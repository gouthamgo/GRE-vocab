import SwiftUI
import SwiftData

struct ActiveRecallView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Settings
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false

    // State
    @State private var studyWords: [Word] = []
    @State private var currentIndex: Int = 0
    @State private var currentQuestion: ActiveRecallQuestion?
    @State private var userInput: String = ""
    @State private var selectedOption: ActiveRecallQuestion.QuestionOption?
    @State private var answerResult: AnswerResult?
    @State private var showingAnswer: Bool = false
    @State private var showHint: Bool = false

    // Session tracking
    @State private var sessionCorrect: Int = 0
    @State private var sessionIncorrect: Int = 0
    @State private var isSessionComplete: Bool = false
    @State private var sessionStartTime: Date = Date()
    @State private var currentSession: StudySession?
    @State private var userProgress: UserProgress?

    // Animation
    @State private var cardScale: CGFloat = 0.9
    @State private var cardOpacity: Double = 0

    // Question type selection
    @State private var selectedQuestionTypes: Set<QuestionType> = Set(QuestionType.allCases)
    @State private var showingTypeSelector: Bool = false

    var deck: Deck?
    var decks: [Deck]?

    init(deck: Deck) {
        self.deck = deck
        self.decks = nil
    }

    init(decks: [Deck]) {
        self.deck = nil
        self.decks = decks
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                progressBar
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                Spacer()

                if isSessionComplete {
                    sessionCompleteView
                } else if let question = currentQuestion {
                    questionContent(question: question)
                        .scaleEffect(cardScale)
                        .opacity(cardOpacity)
                } else {
                    emptyStateView
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingTypeSelector) {
            questionTypeSelector
        }
        .onAppear {
            setupSession()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppTheme.Colors.surface))
            }

            Spacer()

            // Session stats
            HStack(spacing: AppTheme.Spacing.lg) {
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.success)
                    Text("\(sessionCorrect)")
                        .font(AppTheme.Typography.labelLarge())
                        .foregroundColor(AppTheme.Colors.success)
                }

                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.error)
                    Text("\(sessionIncorrect)")
                        .font(AppTheme.Typography.labelLarge())
                        .foregroundColor(AppTheme.Colors.error)
                }
            }

            Spacer()

            // Question type filter
            Button {
                showingTypeSelector = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppTheme.Colors.surface))
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.surfaceHighlight)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.accent)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 4)
    }

    private var progress: Double {
        guard !studyWords.isEmpty else { return 0 }
        return Double(currentIndex) / Double(studyWords.count)
    }

    // MARK: - Question Content
    @ViewBuilder
    private func questionContent(question: ActiveRecallQuestion) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Question type badge
            questionTypeBadge(question.type)

            // Main question card
            questionCard(question: question)

            // Answer input or options
            if !showingAnswer {
                answerInput(question: question)
            } else {
                answerFeedback(question: question)
            }

            // Action buttons
            actionButtons(question: question)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private func questionTypeBadge(_ type: QuestionType) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: type.icon)
                .font(.system(size: 14, weight: .semibold))
            Text(type.rawValue)
                .font(AppTheme.Typography.labelMedium(.semibold))
        }
        .foregroundColor(type.color)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(type.color.opacity(0.15))
        )
    }

    private func questionCard(question: ActiveRecallQuestion) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Word display for certain question types
            if question.type != .wordFromDefinition {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(question.word.term)
                        .font(AppTheme.Typography.displayMedium(.black))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Button {
                        TextToSpeechService.shared.speak(text: question.word.term)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.accent)
                            .padding(8)
                            .background(Circle().fill(AppTheme.Colors.accent.opacity(0.1)))
                    }
                }

                Text(question.word.partOfSpeech)
                    .font(AppTheme.Typography.labelMedium(.medium))
                    .foregroundColor(question.word.difficulty.themeColor)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(question.word.difficulty.themeColor.opacity(0.15))
                    )
            }

            // Question prompt
            Text(question.prompt)
                .font(question.type == .wordFromDefinition ?
                      AppTheme.Typography.headlineMedium(.medium) :
                      AppTheme.Typography.bodyLarge())
                .foregroundColor(question.type == .wordFromDefinition ?
                                 AppTheme.Colors.textPrimary :
                                 AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.md)

            // Hint button
            if let hint = question.hint, !showHint {
                Button {
                    withAnimation {
                        showHint = true
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "lightbulb")
                        Text("Show Hint")
                    }
                    .font(AppTheme.Typography.labelSmall(.medium))
                    .foregroundColor(AppTheme.Colors.warning)
                }
            }

            if showHint, let hint = question.hint {
                Text(hint)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.warning)
                    .padding(AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                            .fill(AppTheme.Colors.warning.opacity(0.1))
                    )
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(question.type.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Answer Input
    @ViewBuilder
    private func answerInput(question: ActiveRecallQuestion) -> some View {
        if question.type == .definitionRecall {
            // Text input for definition recall
            VStack(spacing: AppTheme.Spacing.md) {
                TextField("Type the definition...", text: $userInput, axis: .vertical)
                    .textFieldStyle(AppTheme.CustomTextFieldStyle())
                    .font(AppTheme.Typography.bodyLarge())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(3...6)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        } else if let options = question.options {
            // Multiple choice options
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(options) { option in
                    optionButton(option: option, question: question)
                }
            }
        }
    }

    private func optionButton(option: ActiveRecallQuestion.QuestionOption, question: ActiveRecallQuestion) -> some View {
        Button {
            HapticManager.shared.lightImpact()
            selectedOption = option
        } label: {
            HStack {
                Text(option.text)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(selectedOption?.id == option.id ?
                                     .white : AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if selectedOption?.id == option.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(selectedOption?.id == option.id ?
                          question.type.color : AppTheme.Colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(selectedOption?.id == option.id ?
                            question.type.color : AppTheme.Colors.surfaceHighlight, lineWidth: 1)
            )
        }
    }

    // MARK: - Answer Feedback
    private func answerFeedback(question: ActiveRecallQuestion) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Result banner
            if let result = answerResult {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.isCorrect ? "Correct!" : "Incorrect")
                            .font(AppTheme.Typography.labelLarge(.bold))
                        Text(result.feedback)
                            .font(AppTheme.Typography.labelSmall())
                    }
                    Spacer()
                    if result.score > 0 {
                        Text("+\(result.score)")
                            .font(AppTheme.Typography.headlineSmall(.bold))
                    }
                }
                .foregroundColor(result.isCorrect ? AppTheme.Colors.success : AppTheme.Colors.error)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill((result.isCorrect ? AppTheme.Colors.success : AppTheme.Colors.error).opacity(0.15))
                )
            }

            // Show correct answer
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("CORRECT ANSWER")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)

                Text(question.correctAnswer)
                    .font(AppTheme.Typography.bodyLarge())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surfaceElevated)
            )

            // Show example sentence
            if question.type != .sentenceCompletion {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("EXAMPLE")
                        .font(AppTheme.Typography.labelSmall(.bold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1)

                    Text(question.word.exampleSentence)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.surfaceElevated)
                )
            }
        }
    }

    // MARK: - Action Buttons
    private func actionButtons(question: ActiveRecallQuestion) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if !showingAnswer {
                SecondaryButton("I Don't Know", icon: "xmark.circle") {
                    handleDontKnow()
                }

                if question.type == .definitionRecall {
                    PrimaryButton("Check Answer", icon: "checkmark.circle") {
                        handleCheckTextAnswer()
                    }
                    .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    PrimaryButton("Submit", icon: "checkmark.circle") {
                        handleCheckOptionAnswer()
                    }
                    .disabled(selectedOption == nil)
                }
            } else {
                SecondaryButton("Still Learning", icon: "arrow.left.circle") {
                    handleResponse(correct: false)
                }
                PrimaryButton("Got It!", icon: "arrow.right.circle") {
                    handleResponse(correct: answerResult?.isCorrect ?? false)
                }
            }
        }
    }

    // MARK: - Session Complete View
    private var sessionCompleteView: some View {
        SessionCompleteView(
            correct: sessionCorrect,
            incorrect: sessionIncorrect,
            onRestart: {
                resetSession()
            },
            onDismiss: {
                dismiss()
            }
        )
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "checkmark.seal.fill",
            title: "All Done!",
            subtitle: "No cards to review right now"
        )
    }

    // MARK: - Question Type Selector
    private var questionTypeSelector: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(QuestionType.allCases) { type in
                        Button {
                            if selectedQuestionTypes.contains(type) {
                                if selectedQuestionTypes.count > 1 {
                                    selectedQuestionTypes.remove(type)
                                }
                            } else {
                                selectedQuestionTypes.insert(type)
                            }
                        } label: {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.rawValue)
                                        .font(AppTheme.Typography.bodyMedium())
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    Text(type.description)
                                        .font(AppTheme.Typography.labelSmall())
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                }

                                Spacer()

                                if selectedQuestionTypes.contains(type) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.Colors.accent)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select Question Types")
                } footer: {
                    Text("Choose at least one question type. Questions will be randomly selected from enabled types.")
                }
            }
            .navigationTitle("Question Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingTypeSelector = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Actions
    private func setupSession() {
        do {
            userProgress = try DataService.shared.getUserProgress(modelContext: modelContext)
        } catch {
            print("Error getting user progress: \(error)")
        }

        sessionStartTime = Date()
        let sessionType = "activeRecall"
        let deckName = deck?.name
        currentSession = StudySession(sessionType: sessionType, deckName: deckName)
        if let session = currentSession {
            modelContext.insert(session)
        }

        // Load words - prioritize learning path quiz queue
        if let deck = deck {
            let quizQueue = LearningPathService.shared.getQuizQueue(from: deck.words, limit: 20)
            if quizQueue.isEmpty {
                studyWords = SpacedRepetitionService.shared.getWordsForReview(from: deck.words, limit: 20)
            } else {
                studyWords = quizQueue
            }
        } else if let decks = decks {
            let allWords = decks.flatMap { $0.words }
            let quizQueue = LearningPathService.shared.getQuizQueue(from: allWords, limit: 20)
            if quizQueue.isEmpty {
                studyWords = SpacedRepetitionService.shared.getWordsForReview(from: allWords, limit: 20)
            } else {
                studyWords = quizQueue
            }
        }

        loadNextQuestion()

        // Animate card in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            cardScale = 1.0
            cardOpacity = 1.0
        }
    }

    private func loadNextQuestion() {
        guard currentIndex < studyWords.count else {
            isSessionComplete = true
            finalizeSession()
            return
        }

        let word = studyWords[currentIndex]

        // Filter question types that are available for this word AND selected by user
        let availableTypes = selectedQuestionTypes.filter { $0.isAvailable(for: word) }
        let questionType = availableTypes.randomElement() ?? .definitionRecall

        currentQuestion = QuestionGenerator.generateQuestion(
            for: word,
            type: questionType,
            allWords: studyWords
        )

        // Reset state
        userInput = ""
        selectedOption = nil
        answerResult = nil
        showingAnswer = false
        showHint = false

        // Auto-play pronunciation
        if autoPlayPronunciation && questionType != .wordFromDefinition {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                TextToSpeechService.shared.speak(text: word.term)
            }
        }
    }

    private func handleCheckTextAnswer() {
        guard let question = currentQuestion else { return }

        answerResult = QuestionGenerator.validateTextAnswer(
            userInput: userInput,
            correctAnswer: question.correctAnswer,
            questionType: question.type
        )

        if answerResult?.isCorrect == true {
            HapticManager.shared.correctAnswer()
        } else {
            HapticManager.shared.incorrectAnswer()
        }

        withAnimation {
            showingAnswer = true
        }
    }

    private func handleCheckOptionAnswer() {
        guard let question = currentQuestion,
              let selected = selectedOption else { return }

        let isCorrect = selected.isCorrect
        answerResult = AnswerResult(
            isCorrect: isCorrect,
            score: isCorrect ? 100 : 0,
            feedback: isCorrect ? "Excellent!" : "Not quite right."
        )

        if isCorrect {
            HapticManager.shared.correctAnswer()
        } else {
            HapticManager.shared.incorrectAnswer()
        }

        withAnimation {
            showingAnswer = true
        }
    }

    private func handleDontKnow() {
        answerResult = AnswerResult(
            isCorrect: false,
            score: 0,
            feedback: "That's okay! Review the answer to learn."
        )
        HapticManager.shared.lightImpact()

        withAnimation {
            showingAnswer = true
        }
    }

    private func handleResponse(correct: Bool) {
        if correct {
            sessionCorrect += 1
            HapticManager.shared.cardSwipeRight()
        } else {
            sessionIncorrect += 1
            HapticManager.shared.cardSwipeLeft()
        }

        // Update spaced repetition and learning path
        if let word = currentQuestion?.word {
            SpacedRepetitionService.shared.processSwipeResponse(word: word, knewIt: correct)

            // Record quiz attempt to learning path
            word.recordQuizAttempt(passed: correct)
        }

        // Record session
        currentSession?.recordAnswer(correct: correct)
        userProgress?.recordStudy(correct: correct)

        try? modelContext.save()

        // Move to next
        currentIndex += 1

        // Animate transition
        withAnimation(.easeOut(duration: 0.2)) {
            cardScale = 0.9
            cardOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            loadNextQuestion()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                cardScale = 1.0
                cardOpacity = 1.0
            }
        }
    }

    private func resetSession() {
        currentIndex = 0
        sessionCorrect = 0
        sessionIncorrect = 0
        isSessionComplete = false
        sessionStartTime = Date()

        // Reload words - prioritize learning path quiz queue
        if let deck = deck {
            let quizQueue = LearningPathService.shared.getQuizQueue(from: deck.words, limit: 20)
            if quizQueue.isEmpty {
                studyWords = SpacedRepetitionService.shared.getWordsForReview(from: deck.words, limit: 20)
            } else {
                studyWords = quizQueue
            }
        } else if let decks = decks {
            let allWords = decks.flatMap { $0.words }
            let quizQueue = LearningPathService.shared.getQuizQueue(from: allWords, limit: 20)
            if quizQueue.isEmpty {
                studyWords = SpacedRepetitionService.shared.getWordsForReview(from: allWords, limit: 20)
            } else {
                studyWords = quizQueue
            }
        }

        loadNextQuestion()
    }

    private func finalizeSession() {
        guard let session = currentSession else { return }

        session.duration = Date().timeIntervalSince(sessionStartTime)
        session.questionTypes = Array(selectedQuestionTypes.map { $0.rawValue })

        if let progress = userProgress {
            progress.recordSession(
                correct: session.correctCount,
                incorrect: session.incorrectCount,
                sessionType: session.sessionType,
                duration: session.duration
            )
        }

        HapticManager.shared.sessionComplete()
        try? modelContext.save()
    }
}

#Preview {
    ActiveRecallView(decks: [])
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self, StudySession.self], inMemory: true)
}
