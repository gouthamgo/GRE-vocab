import SwiftUI
import SwiftData
import AVFoundation

struct FlashcardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FlashcardViewModel()
    @State private var userProgress: UserProgress?

    // Settings
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var isFlipped = false
    @State private var showHint: SwipeHint? = nil
    @State private var appearAnimation = false

    var deck: Deck?
    var decks: [Deck]?
    var isPreviewMode: Bool

    enum SwipeHint {
        case left, right
    }

    init(deck: Deck, isPreviewMode: Bool = false) {
        self.deck = deck
        self.decks = nil
        self.isPreviewMode = isPreviewMode
    }

    init(decks: [Deck], isPreviewMode: Bool = false) {
        self.deck = nil
        self.decks = decks
        self.isPreviewMode = isPreviewMode
    }

    @State private var userInput: String = ""
    @State private var showFeedback: Bool = false
    @State private var isCorrect: Bool = false
    @State private var sessionStartTime: Date = Date()
    @State private var currentSession: StudySession?

    // Swipe feedback toast
    @State private var showSwipeFeedback: Bool = false
    @State private var swipeFeedbackMessage: String = ""
    @State private var swipeFeedbackIsPositive: Bool = true

    // Post-session navigation
    @State private var showFeynmanMode: Bool = false
    @State private var showActiveRecall: Bool = false

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()

            // Ambient glow based on swipe
            ambientGlow

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Progress bar
                progressBar
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                Spacer()

                // Card Stack
                if let word = viewModel.currentWord {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        flashcard(word: word)
                            .offset(cardOffset)
                            .rotationEffect(.degrees(cardRotation))
                            .gesture(dragGesture)
                            .opacity(appearAnimation ? 1 : 0)
                            .scaleEffect(appearAnimation ? 1 : 0.9)

                        // Know It / Don't Know buttons - always visible
                        HStack(spacing: AppTheme.Spacing.lg) {
                            // Don't Know button (red)
                            Button {
                                if !isFlipped {
                                    // Flip to reveal, then process as don't know
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        isFlipped = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        swipeCard(direction: .left)
                                    }
                                } else {
                                    swipeCard(direction: .left)
                                }
                            } label: {
                                VStack(spacing: AppTheme.Spacing.xs) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 28, weight: .bold))
                                    Text("Don't Know")
                                        .font(AppTheme.Typography.labelMedium(.semibold))
                                }
                                .foregroundColor(AppTheme.Colors.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                        .fill(AppTheme.Colors.error.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                                .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .accessibilityLabel("Don't know this word")

                            // Know It button (green)
                            Button {
                                if !isFlipped {
                                    // Flip to reveal, then process as know
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        isFlipped = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        swipeCard(direction: .right)
                                    }
                                } else {
                                    swipeCard(direction: .right)
                                }
                            } label: {
                                VStack(spacing: AppTheme.Spacing.xs) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 28, weight: .bold))
                                    Text("Know It")
                                        .font(AppTheme.Typography.labelMedium(.semibold))
                                }
                                .foregroundColor(AppTheme.Colors.success)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                        .fill(AppTheme.Colors.success.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                                .stroke(AppTheme.Colors.success.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .accessibilityLabel("Know this word")
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                } else if viewModel.isSessionComplete {
                    SessionCompleteView(
                        correct: viewModel.sessionCorrect,
                        incorrect: viewModel.sessionIncorrect,
                        wordsMastered: viewModel.wordsMastered,
                        wordsLeveledUp: viewModel.wordsLeveledUp.count,
                        wordsStartedLearning: viewModel.wordsStartedLearning.count,
                        strugglingWords: viewModel.strugglingWords,
                        onRestart: {
                            if let deck = deck {
                                viewModel.startSession(deck: deck)
                            } else if let decks = decks {
                                viewModel.startReviewSession(from: decks)
                            }
                            resetCardState()
                        },
                        onDismiss: { dismiss() },
                        onFeynmanMode: deck != nil ? {
                            showFeynmanMode = true
                        } : nil,
                        onActiveRecall: deck != nil ? {
                            showActiveRecall = true
                        } : nil
                    )
                } else {
                    EmptyStateView(
                        icon: "checkmark.seal.fill",
                        title: "All Done!",
                        subtitle: "No cards to review right now"
                    )
                }

                Spacer()
            }

            // Swipe feedback toast
            if showSwipeFeedback {
                VStack {
                    Spacer()

                    SwipeFeedbackToast(
                        message: swipeFeedbackMessage,
                        isPositive: swipeFeedbackIsPositive
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showSwipeFeedback)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showFeynmanMode) {
            if let deck = deck {
                FeynmanModeView(deck: deck)
            }
        }
        .fullScreenCover(isPresented: $showActiveRecall) {
            if let deck = deck {
                ActiveRecallView(deck: deck)
            }
        }
        .onAppear {
            do {
                userProgress = try DataService.shared.getUserProgress(modelContext: modelContext)
            } catch {
                print("Error getting user progress: \(error)")
            }

            // Initialize session tracking
            sessionStartTime = Date()
            let sessionType = deck != nil ? "deck" : "review"
            let deckName = deck?.name
            currentSession = StudySession(sessionType: sessionType, deckName: deckName)
            if let session = currentSession {
                modelContext.insert(session)
            }

            if let deck = deck {
                viewModel.startSession(deck: deck)
            } else if let decks = decks {
                viewModel.startReviewSession(from: decks)
            }

            withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appearAnimation = true
            }

            // Auto-play pronunciation for first word if enabled
            if autoPlayPronunciation, let word = viewModel.currentWord {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    TextToSpeechService.shared.speak(text: word.term)
                }
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
            .accessibilityLabel("Close study session")

            Spacer()

            // Simple card counter: "1 of 12"
            Text("\(currentIndex + 1) of \(viewModel.studyWords.count)")
                .font(AppTheme.Typography.headlineSmall(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            // Empty spacer to balance the close button
            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var currentIndex: Int {
        viewModel.currentIndex
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
                    .frame(width: geo.size.width * viewModel.progress, height: 4)
                    .animation(.spring(response: 0.4), value: viewModel.progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Ambient Glow
    private var ambientGlow: some View {
        ZStack {
            // Right glow (correct)
            Circle()
                .fill(AppTheme.Colors.success)
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .opacity(showHint == .right ? 0.3 : 0)
                .offset(x: 150)

            // Left glow (incorrect)
            Circle()
                .fill(AppTheme.Colors.error)
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .opacity(showHint == .left ? 0.3 : 0)
                .offset(x: -150)
        }
        .animation(.easeOut(duration: 0.2), value: showHint)
    }

    // MARK: - Card Stack
    private func cardStack(word: Word) -> some View {
        ZStack {
            // Background cards
            ForEach(0..<min(2, viewModel.remainingWords - 1), id: \.self) {
                index in
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(AppTheme.Colors.surface)
                    .frame(width: UIScreen.main.bounds.width - 64 - CGFloat(index * 8), height: 400 - CGFloat(index * 8))
                    .offset(y: CGFloat(index + 1) * 8)
                    .opacity(0.5 - Double(index) * 0.2)
            }

            // Main card
            flashcard(word: word)
                .offset(cardOffset)
                .rotationEffect(.degrees(cardRotation))
                .gesture(dragGesture)
                .opacity(appearAnimation ? 1 : 0)
                .scaleEffect(appearAnimation ? 1 : 0.9)
        }
    }

    // MARK: - Flashcard
    private func flashcard(word: Word) -> some View {
        ZStack {
            // Front (Term)
            cardFront(word: word)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 0 : 1)

            // Back (Definition)
            cardBack(word: word)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(width: UIScreen.main.bounds.width - 64, height: 400)
        .onTapGesture {
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isFlipped ? "Definition side. Swipe left if still learning, swipe right if you got it." : "Word side: \(word.term). Tap to reveal definition.")
        .accessibilityHint(isFlipped ? "Swipe to answer" : "Double tap to flip card")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Card Front
    private func cardFront(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            // Word
            VStack(spacing: AppTheme.Spacing.md) {
                Text(word.term)
                    .font(AppTheme.Typography.displayMedium(.black))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    TextToSpeechService.shared.speak(text: word.term)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.accent)
                        .padding(8)
                        .background(Circle().fill(AppTheme.Colors.accent.opacity(0.1)))
                }
                .accessibilityLabel("Hear pronunciation of \(word.term)")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Word: \(word.term). \(word.partOfSpeech)")

            // Part of speech
            Text(word.partOfSpeech)
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(word.difficulty.themeColor)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(
                    Capsule()
                        .fill(word.difficulty.themeColor.opacity(0.15))
                )

            Spacer()

            // Tap hint
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 12))
                Text("Tap to reveal")
                    .font(AppTheme.Typography.labelSmall(.medium))
            }
            .foregroundColor(AppTheme.Colors.textTertiary)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [word.difficulty.themeColor.opacity(0.5), word.difficulty.themeColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: word.difficulty.themeColor.opacity(0.2), radius: 30, x: 0, y: 15)
    }

    // MARK: - Card Back
    private func cardBack(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Active Recall Feedback Banner
            if showFeedback {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))

                    Text(isCorrect ? "Great recall!" : "Keep practicing!")
                        .font(AppTheme.Typography.labelMedium(.bold))
                }
                .foregroundColor(isCorrect ? AppTheme.Colors.success : AppTheme.Colors.warning)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill((isCorrect ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.15))
                )
                .padding(.top, AppTheme.Spacing.lg)
            }

            Spacer()

            // Definition
            VStack(spacing: AppTheme.Spacing.md) {
                Text("DEFINITION")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(2)

                Text(word.definition)
                    .font(AppTheme.Typography.headlineLarge(.medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .accessibilityLabel("Definition: \(word.definition)")
            }

            // Divider
            Rectangle()
                .fill(AppTheme.Colors.surfaceHighlight)
                .frame(width: 60, height: 2)

            // Example
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("EXAMPLE")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(2)

                Text("\(word.exampleSentence)")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }

            Spacer()

            // Swipe hint
            Text("Swipe to answer")
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.bottom, AppTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(showFeedback ? (isCorrect ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.5) : AppTheme.Colors.surfaceHighlight, lineWidth: showFeedback ? 2 : 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged {
                value in
                cardOffset = value.translation
                cardRotation = Double(value.translation.width / 20)

                // Update hint
                if value.translation.width > 50 {
                    showHint = .right
                } else if value.translation.width < -50 {
                    showHint = .left
                } else {
                    showHint = nil
                }
            }
            .onEnded {
                value in
                let threshold: CGFloat = 100

                if value.translation.width > threshold {
                    // Swiped right - knew it
                    swipeCard(direction: .right)
                } else if value.translation.width < -threshold {
                    // Swiped left - didn't know
                    swipeCard(direction: .left)
                } else {
                    // Return to center
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        cardOffset = .zero
                        cardRotation = 0
                        showHint = nil
                    }
                }
            }
    }

    private func handleCheckAnswer() {
        guard let word = viewModel.currentWord else { return }
        isCorrect = viewModel.checkAnswer(userInput: userInput, word: word)
        showFeedback = true

        // Haptic feedback based on result
        if isCorrect {
            HapticManager.shared.correctAnswer()
        } else {
            HapticManager.shared.incorrectAnswer()
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isFlipped = true
        }
    }

    private func handleDontKnow() {
        showFeedback = true
        isCorrect = false
        HapticManager.shared.lightImpact()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isFlipped = true
        }
    }

    private func resetCardState() {
        userInput = ""
        isFlipped = false
        showFeedback = false
        isCorrect = false
        cardOffset = .zero
        cardRotation = 0
        showHint = nil

        // Auto-play pronunciation for next word if enabled
        if autoPlayPronunciation, let word = viewModel.currentWord {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                TextToSpeechService.shared.speak(text: word.term)
            }
        }
    }

    private func swipeCard(direction: SwipeHint) {
        let targetX: CGFloat = direction == .right ? 500 : -500

        // Capture word info before processing
        let currentWord = viewModel.currentWord
        let repetitionsBefore = currentWord?.repetitions ?? 0

        // Haptic feedback for swipe
        if direction == .right {
            HapticManager.shared.cardSwipeRight()
        } else {
            HapticManager.shared.cardSwipeLeft()
        }

        withAnimation(.easeOut(duration: 0.3)) {
            cardOffset = CGSize(width: targetX, height: 0)
            cardRotation = direction == .right ? 20 : -20
        }

        // Process after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let isCorrect = direction == .right

            // Mark word as previewed if in preview mode
            if isPreviewMode {
                currentWord?.markPreviewed()
                swipeFeedbackMessage = "Word previewed - quiz to prove you know it"
                swipeFeedbackIsPositive = true
            } else {
                if let progress = userProgress {
                    viewModel.processResponse(knewIt: isCorrect, userProgress: progress)
                }

                // Generate feedback message
                if isCorrect {
                    let newReps = repetitionsBefore + 1
                    if newReps >= 5 {
                        swipeFeedbackMessage = "Mastered! Great job!"
                        swipeFeedbackIsPositive = true
                    } else {
                        let remaining = 5 - newReps
                        swipeFeedbackMessage = "\(remaining) more to master"
                        swipeFeedbackIsPositive = true
                    }
                } else {
                    swipeFeedbackMessage = "You'll see this again soon"
                    swipeFeedbackIsPositive = false
                }
            }

            // Show feedback toast
            withAnimation {
                showSwipeFeedback = true
            }

            // Hide after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSwipeFeedback = false
                }
            }

            // Record to current session
            currentSession?.recordAnswer(correct: isCorrect)

            // Check if session is complete
            if viewModel.isSessionComplete {
                HapticManager.shared.sessionComplete()
                finalizeSession()
            }

            try? modelContext.save()

            // Reset for next card
            resetCardState()
        }
    }

    private func finalizeSession() {
        guard let session = currentSession else { return }

        // Calculate session duration
        session.duration = Date().timeIntervalSince(sessionStartTime)

        // Update user progress with session info
        if let progress = userProgress {
            progress.recordSession(
                correct: session.correctCount,
                incorrect: session.incorrectCount,
                sessionType: session.sessionType,
                duration: session.duration
            )
        }

        try? modelContext.save()
    }
}

// MARK: - Swipe Feedback Toast
struct SwipeFeedbackToast: View {
    let message: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: isPositive ? "checkmark.circle.fill" : "arrow.clockwise.circle.fill")
                .font(.system(size: 20, weight: .semibold))

            Text(message)
                .font(AppTheme.Typography.bodyMedium(.semibold))
        }
        .foregroundColor(isPositive ? AppTheme.Colors.success : AppTheme.Colors.warning)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            Capsule()
                .fill(AppTheme.Colors.surface)
                .overlay(
                    Capsule()
                        .stroke(isPositive ? AppTheme.Colors.success.opacity(0.3) : AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    FlashcardView(decks: [])
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self, StudySession.self], inMemory: true)
}