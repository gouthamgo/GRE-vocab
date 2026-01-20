import SwiftUI
import SwiftData

struct FeynmanModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    @State private var studyWords: [Word] = []
    @State private var currentIndex: Int = 0
    @State private var currentStep: FeynmanStep = .learn
    @State private var userExplanation: String = ""
    @State private var userExample: String = ""
    @State private var confidenceRating: Int = 0
    @State private var sessionStartTime: Date = Date()
    @State private var currentSession: StudySession?
    @State private var userProgress: UserProgress?
    @State private var appearAnimation = false
    @State private var wordsCompleted: Int = 0

    enum FeynmanStep: Int, CaseIterable {
        case learn = 0
        case explain = 1
        case apply = 2
        case rate = 3

        var title: String {
            switch self {
            case .learn: return "Learn"
            case .explain: return "Explain"
            case .apply: return "Apply"
            case .rate: return "Rate"
            }
        }

        var icon: String {
            switch self {
            case .learn: return "book.fill"
            case .explain: return "text.bubble.fill"
            case .apply: return "pencil.line"
            case .rate: return "star.fill"
            }
        }

        var instruction: String {
            switch self {
            case .learn: return "Study the word and its meaning"
            case .explain: return "Explain it in your own simple words"
            case .apply: return "Create your own example sentence"
            case .rate: return "Rate your understanding"
            }
        }
    }

    var currentWord: Word? {
        guard currentIndex < studyWords.count else { return nil }
        return studyWords[currentIndex]
    }

    var progress: Double {
        guard !studyWords.isEmpty else { return 0 }
        let wordProgress = Double(currentIndex) / Double(studyWords.count)
        let stepProgress = Double(currentStep.rawValue) / Double(FeynmanStep.allCases.count)
        return wordProgress + (stepProgress / Double(studyWords.count))
    }

    var isSessionComplete: Bool {
        return currentIndex >= studyWords.count
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Progress
                progressSection
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Step Indicator
                stepIndicator
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.lg)

                if isSessionComplete {
                    Spacer()
                    completionView
                    Spacer()
                } else if let word = currentWord {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Content based on step
                            stepContent(word: word)
                                .padding(.top, AppTheme.Spacing.lg)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, 100)
                    }

                    // Bottom action button
                    actionButton
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupSession()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appearAnimation = true
            }
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
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.surface)
                    )
            }

            Spacer()

            // Mode indicator
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.Colors.warning)
                Text("Feynman Mode")
                    .font(AppTheme.Typography.labelMedium(.bold))
                    .foregroundColor(AppTheme.Colors.warning)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.warning.opacity(0.15))
            )

            Spacer()

            Text("\(currentIndex + 1)/\(studyWords.count)")
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .frame(width: 40, alignment: .trailing)
        }
    }

    // MARK: - Progress Section
    private var progressSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.surfaceHighlight)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.Colors.warning)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step Indicator
    private var stepIndicator: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(FeynmanStep.allCases, id: \.self) { step in
                VStack(spacing: AppTheme.Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(step.rawValue <= currentStep.rawValue ? AppTheme.Colors.warning : AppTheme.Colors.surfaceHighlight)
                            .frame(width: 36, height: 36)

                        Image(systemName: step.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(step.rawValue <= currentStep.rawValue ? AppTheme.Colors.background : AppTheme.Colors.textTertiary)
                    }

                    Text(step.title)
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(step.rawValue == currentStep.rawValue ? AppTheme.Colors.warning : AppTheme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)

                if step != FeynmanStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? AppTheme.Colors.warning : AppTheme.Colors.surfaceHighlight)
                        .frame(height: 2)
                        .frame(maxWidth: 30)
                        .offset(y: -12)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Step Content
    @ViewBuilder
    private func stepContent(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Instruction
            Text(currentStep.instruction)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            switch currentStep {
            case .learn:
                learnStepContent(word: word)
            case .explain:
                explainStepContent(word: word)
            case .apply:
                applyStepContent(word: word)
            case .rate:
                rateStepContent(word: word)
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Learn Step
    private func learnStepContent(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Word Card
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    Text(word.term)
                        .font(AppTheme.Typography.displayMedium(.black))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Button {
                        TextToSpeechService.shared.speak(text: word.term)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }

                Text(word.partOfSpeech)
                    .font(AppTheme.Typography.labelMedium())
                    .foregroundColor(word.difficulty.themeColor)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(word.difficulty.themeColor.opacity(0.15))
                    )
            }
            .padding(AppTheme.Spacing.xl)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                            .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 2)
                    )
            )

            // Definition
            infoSection(title: "DEFINITION", content: word.definition, icon: "text.book.closed.fill")

            // Example
            infoSection(title: "EXAMPLE", content: word.exampleSentence, icon: "quote.bubble.fill", isItalic: true)

            // Mnemonic (if available)
            if let mnemonic = word.mnemonicHint, !mnemonic.isEmpty {
                infoSection(title: "MEMORY TIP", content: mnemonic, icon: "brain.head.profile", color: AppTheme.Colors.tertiary)
            }

            // Synonyms/Antonyms
            if !word.synonyms.isEmpty || !word.antonyms.isEmpty {
                HStack(spacing: AppTheme.Spacing.md) {
                    if !word.synonyms.isEmpty {
                        wordListSection(title: "Synonyms", words: word.synonyms, color: AppTheme.Colors.success)
                    }
                    if !word.antonyms.isEmpty {
                        wordListSection(title: "Antonyms", words: word.antonyms, color: AppTheme.Colors.error)
                    }
                }
            }

            // Root word (if available)
            if let root = word.rootWord, let meaning = word.rootMeaning {
                rootWordSection(root: root, meaning: meaning)
            }
        }
    }

    // MARK: - Explain Step
    private func explainStepContent(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Word reminder
            Text(word.term)
                .font(AppTheme.Typography.displaySmall(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            // Text editor for explanation
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("YOUR EXPLANATION")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                TextEditor(text: $userExplanation)
                    .font(AppTheme.Typography.bodyLarge())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(AppTheme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                    .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 1)
                            )
                    )

                Text("Explain the word as if teaching a child. Use simple language!")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            // Example prompt
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("HINT")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.warning)
                    .tracking(1)

                Text("Think: What does this word make you picture? How would you describe it without using the word itself?")
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.warning.opacity(0.1))
            )
        }
    }

    // MARK: - Apply Step
    private func applyStepContent(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Word reminder
            Text(word.term)
                .font(AppTheme.Typography.displaySmall(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            // Text editor for example
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("YOUR EXAMPLE SENTENCE")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                TextEditor(text: $userExample)
                    .font(AppTheme.Typography.bodyLarge())
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 150)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(AppTheme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                    .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 1)
                            )
                    )

                Text("Create a sentence using '\(word.term)' that shows you understand its meaning.")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            // Original example for reference
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("REFERENCE EXAMPLE")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.accent)
                    .tracking(1)

                Text(word.exampleSentence)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .italic()
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.accent.opacity(0.1))
            )
        }
    }

    // MARK: - Rate Step
    private func rateStepContent(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Summary of what they did
            VStack(spacing: AppTheme.Spacing.lg) {
                Text(word.term)
                    .font(AppTheme.Typography.displaySmall(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if !userExplanation.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Your explanation:")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(userExplanation)
                            .font(AppTheme.Typography.bodySmall())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }

                if !userExample.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Your example:")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text(userExample)
                            .font(AppTheme.Typography.bodySmall())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }
            }

            // Confidence rating
            VStack(spacing: AppTheme.Spacing.md) {
                Text("How well do you understand this word?")
                    .font(AppTheme.Typography.bodyMedium(.medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                confidenceRating = rating
                            }
                            HapticManager.shared.selection()
                        } label: {
                            VStack(spacing: AppTheme.Spacing.xs) {
                                ZStack {
                                    Circle()
                                        .fill(confidenceRating >= rating ? ratingColor(rating) : AppTheme.Colors.surfaceHighlight)
                                        .frame(width: 50, height: 50)

                                    Text("\(rating)")
                                        .font(AppTheme.Typography.headlineMedium(.bold))
                                        .foregroundColor(confidenceRating >= rating ? .white : AppTheme.Colors.textTertiary)
                                }

                                Text(ratingLabel(rating))
                                    .font(AppTheme.Typography.labelSmall())
                                    .foregroundColor(confidenceRating == rating ? ratingColor(rating) : AppTheme.Colors.textTertiary)
                            }
                        }
                    }
                }

                if confidenceRating > 0 {
                    Text(ratingDescription(confidenceRating))
                        .font(AppTheme.Typography.bodySmall())
                        .foregroundColor(ratingColor(confidenceRating))
                        .multilineTextAlignment(.center)
                        .padding(.top, AppTheme.Spacing.sm)
                }
            }
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(AppTheme.Colors.surface)
            )
        }
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
            handleAction()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(actionButtonTitle)
                    .font(AppTheme.Typography.bodyLarge(.bold))
                Image(systemName: actionButtonIcon)
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(actionButtonEnabled ? AppTheme.Colors.background : AppTheme.Colors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(actionButtonEnabled ? AppTheme.Colors.warning : AppTheme.Colors.surfaceHighlight)
            )
        }
        .disabled(!actionButtonEnabled)
    }

    private var actionButtonTitle: String {
        switch currentStep {
        case .learn: return "I've studied it"
        case .explain: return userExplanation.isEmpty ? "Skip" : "Continue"
        case .apply: return userExample.isEmpty ? "Skip" : "Continue"
        case .rate: return "Complete"
        }
    }

    private var actionButtonIcon: String {
        currentStep == .rate ? "checkmark" : "arrow.right"
    }

    private var actionButtonEnabled: Bool {
        switch currentStep {
        case .rate: return confidenceRating > 0
        default: return true
        }
    }

    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // Success icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.warning.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(AppTheme.Colors.warning)
            }

            Text("Feynman Session Complete!")
                .font(AppTheme.Typography.displaySmall(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("You've deeply learned \(wordsCompleted) words using the Feynman Technique")
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: AppTheme.Spacing.lg) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(AppTheme.Typography.bodyLarge(.bold))
                        .foregroundColor(AppTheme.Colors.warning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                .stroke(AppTheme.Colors.warning, lineWidth: 2)
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .padding(AppTheme.Spacing.xl)
    }

    // MARK: - Helper Views
    private func infoSection(title: String, content: String, icon: String, isItalic: Bool = false, color: Color = AppTheme.Colors.accent) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)
            }

            Group {
                if isItalic {
                    Text(content)
                        .italic()
                } else {
                    Text(content)
                }
            }
            .font(AppTheme.Typography.bodyMedium())
            .foregroundColor(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
        )
    }

    private func wordListSection(title: String, words: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)

            FlowLayout(spacing: AppTheme.Spacing.xs) {
                ForEach(words.prefix(4), id: \.self) { word in
                    Text(word)
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(color)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(color.opacity(0.15))
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
        )
    }

    private func rootWordSection(root: String, meaning: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "tree.fill")
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Root: \(root)")
                    .font(AppTheme.Typography.bodyMedium(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(meaning)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(AppTheme.Colors.secondary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Rating Helpers
    private func ratingColor(_ rating: Int) -> Color {
        switch rating {
        case 1: return AppTheme.Colors.error
        case 2: return AppTheme.Colors.warning
        case 3: return AppTheme.Colors.tertiary
        case 4: return AppTheme.Colors.accent
        case 5: return AppTheme.Colors.success
        default: return AppTheme.Colors.textTertiary
        }
    }

    private func ratingLabel(_ rating: Int) -> String {
        switch rating {
        case 1: return "Lost"
        case 2: return "Fuzzy"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Solid"
        default: return ""
        }
    }

    private func ratingDescription(_ rating: Int) -> String {
        switch rating {
        case 1: return "I don't understand this word at all"
        case 2: return "I have a vague idea but need more practice"
        case 3: return "I understand it but might forget"
        case 4: return "I understand it well"
        case 5: return "I could teach this word to someone else!"
        default: return ""
        }
    }

    // MARK: - Actions
    private func setupSession() {
        // Load user progress
        do {
            userProgress = try DataService.shared.getUserProgress(modelContext: modelContext)
        } catch {
            print("Error loading user progress: \(error)")
        }

        // Get words to study - prioritize learning path deep learn queue
        let deepLearnQueue = LearningPathService.shared.getDeepLearnQueue(from: deck.words, limit: 5)
        if !deepLearnQueue.isEmpty {
            studyWords = deepLearnQueue
        } else {
            // Fallback to words with low Feynman confidence
            studyWords = Array(deck.words.filter { $0.feynmanConfidence < 4 }.prefix(5))
            if studyWords.isEmpty {
                studyWords = Array(deck.words.prefix(5))
            }
        }

        // Create session
        sessionStartTime = Date()
        currentSession = StudySession(sessionType: "feynman", deckName: deck.name)
        if let session = currentSession {
            modelContext.insert(session)
        }

        // Pre-fill existing data if available
        if let word = currentWord {
            userExplanation = word.userExplanation ?? ""
            userExample = word.userExample ?? ""
            confidenceRating = word.feynmanConfidence
        }
    }

    private func handleAction() {
        switch currentStep {
        case .learn:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = .explain
            }
        case .explain:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = .apply
            }
        case .apply:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = .rate
            }
        case .rate:
            saveCurrentWord()
            moveToNextWord()
        }
    }

    private func saveCurrentWord() {
        guard let word = currentWord else { return }

        // Save user input to the word
        if !userExplanation.isEmpty {
            word.userExplanation = userExplanation
        }
        if !userExample.isEmpty {
            word.userExample = userExample
        }

        // Record deep learn completion to learning path
        // This updates learningStage, feynmanConfidence, deepLearnDate, and status
        word.markDeepLearned(confidence: confidenceRating)

        // Record in session
        currentSession?.recordAnswer(correct: confidenceRating >= 3)

        try? modelContext.save()
        wordsCompleted += 1
    }

    private func moveToNextWord() {
        currentIndex += 1
        currentStep = .learn
        userExplanation = ""
        userExample = ""
        confidenceRating = 0

        // Pre-fill if word has existing data
        if let word = currentWord {
            userExplanation = word.userExplanation ?? ""
            userExample = word.userExample ?? ""
            if word.feynmanConfidence > 0 {
                confidenceRating = word.feynmanConfidence
            }
        }

        // Finalize session if complete
        if isSessionComplete {
            finalizeSession()
        }
    }

    private func finalizeSession() {
        guard let session = currentSession else { return }

        session.duration = Date().timeIntervalSince(sessionStartTime)

        if let progress = userProgress {
            progress.recordSession(
                correct: session.correctCount,
                incorrect: session.incorrectCount,
                sessionType: "feynman",
                duration: session.duration
            )
            progress.feynmanSessionsCount += 1
        }

        try? modelContext.save()
        HapticManager.shared.sessionComplete()
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    FeynmanModeView(deck: Deck(name: "Test", difficulty: .common))
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self, StudySession.self], inMemory: true)
}
