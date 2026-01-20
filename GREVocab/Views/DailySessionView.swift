import SwiftUI
import SwiftData

/// Main orchestrator view for the unified Daily Session
/// Flows through: Preview -> Quiz -> Deep Moment -> Summary
struct DailySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let config: DailySessionConfig
    @State private var viewModel: DailySessionViewModel
    @State private var appearAnimation = false
    @State private var sessionStartTime = Date()

    // User progress for recording session
    @State private var userProgress: UserProgress?
    @State private var currentSession: StudySession?

    init(config: DailySessionConfig) {
        self.config = config
        self._viewModel = State(initialValue: DailySessionViewModel(config: config))
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button and progress
                header
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Session progress bar
                sessionProgressBar
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Phase content
                phaseContent
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupSession()
            // Ensure animation triggers even if reduceMotion changes
            if reduceMotion {
                appearAnimation = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    appearAnimation = true
                }
            }
            // Safety fallback - ensure content becomes visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !appearAnimation {
                    appearAnimation = true
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
                    .background(Circle().fill(AppTheme.Colors.surface))
            }

            Spacer()

            // Current phase indicator
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: viewModel.currentPhase.icon)
                    .font(.system(size: 12, weight: .bold))
                Text(viewModel.currentPhase.displayName.uppercased())
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .tracking(1)
            }
            .foregroundColor(phaseColor)

            Spacer()

            // Session stats (correct/incorrect)
            HStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.success)
                    Text("\(viewModel.stats.quizCorrect)")
                        .font(AppTheme.Typography.labelMedium(.semibold))
                        .foregroundColor(AppTheme.Colors.success)
                }

                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.error)
                    Text("\(viewModel.stats.quizIncorrect)")
                        .font(AppTheme.Typography.labelMedium(.semibold))
                        .foregroundColor(AppTheme.Colors.error)
                }
            }
        }
    }

    // MARK: - Session Progress Bar
    private var sessionProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(AppTheme.Colors.surfaceHighlight)
                    .frame(height: 8)

                // Progress fill
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [phaseColor, phaseColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * viewModel.overallProgress), height: 8)
                    .animation(.spring(response: 0.4), value: viewModel.overallProgress)

                // Phase markers
                HStack(spacing: 0) {
                    ForEach(Array(viewModel.activePhases.enumerated()), id: \.element) { index, phase in
                        if index > 0 {
                            Circle()
                                .fill(phaseMarkerColor(for: phase))
                                .frame(width: 6, height: 6)
                                .offset(x: geo.size.width * phase.progressStart - 3)
                        }
                    }
                }
            }
        }
        .frame(height: 8)
    }

    private func phaseMarkerColor(for phase: SessionPhase) -> Color {
        let currentProgress = viewModel.overallProgress
        let phaseStart = phase.progressStart
        return currentProgress >= phaseStart ? AppTheme.Colors.surface : AppTheme.Colors.textTertiary.opacity(0.3)
    }

    private var phaseColor: Color {
        switch viewModel.currentPhase {
        case .preview: return AppTheme.Colors.accent
        case .quiz: return AppTheme.Colors.tertiary
        case .deepMoment: return AppTheme.Colors.warning
        case .complete: return AppTheme.Colors.success
        }
    }

    // MARK: - Phase Content
    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.currentPhase {
        case .preview:
            if let word = viewModel.currentPreviewWord {
                PreviewStepView(
                    word: word,
                    isFlipped: $viewModel.isCardFlipped,
                    onNext: {
                        viewModel.nextPreviewWord(modelContext: modelContext)
                    },
                    onPrevious: viewModel.previewIndex > 0 ? {
                        viewModel.previousPreviewWord()
                    } : nil,
                    currentIndex: viewModel.previewIndex,
                    totalCount: config.previewWords.count
                )
            } else {
                // No preview words - show loading and trigger transition
                VStack(spacing: AppTheme.Spacing.lg) {
                    ProgressView()
                    Text("Loading...")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // If no preview word available, move to next phase
                    if viewModel.currentPreviewWord == nil {
                        viewModel.startSession()
                    }
                }
            }

        case .quiz:
            if let question = viewModel.currentQuestion {
                QuizStepView(
                    question: question,
                    selectedOption: $viewModel.selectedOption,
                    userTextInput: $viewModel.userTextInput,
                    showingAnswer: $viewModel.showingQuizAnswer,
                    answerResult: $viewModel.quizAnswerResult,
                    currentIndex: viewModel.quizIndex,
                    totalCount: config.quizWords.count,
                    onSubmit: {
                        viewModel.submitQuizAnswer()
                        if viewModel.quizAnswerResult?.isCorrect == true {
                            HapticManager.shared.correctAnswer()
                        } else {
                            HapticManager.shared.incorrectAnswer()
                        }
                    },
                    onSkip: {
                        viewModel.skipQuizQuestion()
                        HapticManager.shared.lightImpact()
                    },
                    onProceed: { correct in
                        viewModel.proceedFromQuiz(recordedAsCorrect: correct, modelContext: modelContext)
                        recordQuizAnswer(correct: correct)
                    }
                )
            } else {
                // Loading quiz question
                VStack(spacing: AppTheme.Spacing.lg) {
                    ProgressView()
                    Text("Loading quiz question...")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Button("Retry Load") {
                        viewModel.loadCurrentQuizQuestion()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .onAppear {
                    viewModel.loadCurrentQuizQuestion()
                }
            }

        case .deepMoment:
            if let question = viewModel.deepMomentQuestion {
                DeepMomentView(
                    question: question,
                    selectedOption: $viewModel.selectedDeepOption,
                    showingAnswer: $viewModel.showingDeepAnswer,
                    answerCorrect: $viewModel.deepAnswerCorrect,
                    onSubmit: {
                        viewModel.submitDeepAnswer(modelContext: modelContext)
                        if viewModel.deepAnswerCorrect {
                            HapticManager.shared.correctAnswer()
                        } else {
                            HapticManager.shared.incorrectAnswer()
                        }
                    },
                    onSkip: {
                        viewModel.skipDeepMoment()
                    },
                    onFinish: {
                        viewModel.finishDeepMoment()
                    }
                )
            } else {
                VStack(spacing: AppTheme.Spacing.lg) {
                    ProgressView()
                    Text("Loading...")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    viewModel.loadDeepMomentQuestion()
                }
            }

        case .complete:
            sessionSummary
        }
    }

    // MARK: - Session Summary
    private var sessionSummary: some View {
        DailySessionSummaryView(
            stats: viewModel.stats,
            onDone: {
                finalizeSession()
                dismiss()
            },
            onOneMore: {
                // This would require building a new session
                // For now, just dismiss
                finalizeSession()
                dismiss()
            }
        )
    }

    // MARK: - Session Management
    private func setupSession() {
        do {
            userProgress = try DataService.shared.getUserProgress(modelContext: modelContext)
        } catch {
            print("Error getting user progress: \(error)")
        }

        sessionStartTime = Date()
        currentSession = StudySession(sessionType: "dailySession", deckName: nil)
        if let session = currentSession {
            modelContext.insert(session)
        }

        // Start the view model
        viewModel.startSession()
    }

    private func recordQuizAnswer(correct: Bool) {
        currentSession?.recordAnswer(correct: correct)
        userProgress?.recordStudy(correct: correct)
        try? modelContext.save()
    }

    private func finalizeSession() {
        guard let session = currentSession else { return }

        session.duration = Date().timeIntervalSince(sessionStartTime)

        if let progress = userProgress {
            progress.recordSession(
                correct: session.correctCount,
                incorrect: session.incorrectCount,
                sessionType: session.sessionType,
                duration: session.duration
            )
            // Mark daily session as completed
            progress.markDailySessionCompleted()
        }

        HapticManager.shared.sessionComplete()
        try? modelContext.save()
    }
}

// MARK: - Daily Session Summary View
struct DailySessionSummaryView: View {
    let stats: DailySessionStats
    let onDone: () -> Void
    let onOneMore: () -> Void

    @State private var appearAnimation = false
    @State private var confettiTrigger = false

    var grade: (text: String, color: Color, icon: String) {
        switch stats.accuracy {
        case 90...100: return ("Excellent!", AppTheme.Colors.success, "star.fill")
        case 70..<90: return ("Great Job!", AppTheme.Colors.tertiary, "hand.thumbsup.fill")
        case 50..<70: return ("Keep Going!", AppTheme.Colors.warning, "flame.fill")
        default: return ("Keep Practicing", AppTheme.Colors.error, "arrow.clockwise")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Celebration icon
            ZStack {
                // Glow rings
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(grade.color.opacity(0.1 - Double(index) * 0.03), lineWidth: 2)
                        .frame(width: CGFloat(140 + index * 35), height: CGFloat(140 + index * 35))
                        .scaleEffect(appearAnimation ? 1 : 0.5)
                        .opacity(appearAnimation ? 1 : 0)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.6)
                            .delay(Double(index) * 0.1),
                            value: appearAnimation
                        )
                }

                // Main circle
                Circle()
                    .fill(grade.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(grade.color.opacity(0.5), lineWidth: 3)
                    )
                    .scaleEffect(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appearAnimation)

                // Icon
                Image(systemName: grade.icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(grade.color)
                    .scaleEffect(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.7, dampingFraction: 0.5).delay(0.2), value: appearAnimation)
            }
            .padding(.bottom, AppTheme.Spacing.xl)

            // Grade text
            Text(grade.text)
                .font(AppTheme.Typography.displaySmall(.black))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.3), value: appearAnimation)

            Text("Daily Session Complete")
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.top, AppTheme.Spacing.xxs)
                .opacity(appearAnimation ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: appearAnimation)

            // Stats
            statsSection
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.xl)
                .opacity(appearAnimation ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.5), value: appearAnimation)

            Spacer()

            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton("Done", icon: "checkmark", isLarge: true) {
                    onDone()
                }

                Button {
                    onOneMore()
                } label: {
                    Text("See you tomorrow!")
                        .font(AppTheme.Typography.labelMedium())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xxl)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 30)
            .animation(.spring(response: 0.6).delay(0.6), value: appearAnimation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            ConfettiView(trigger: confettiTrigger, color: grade.color)
        )
        .onAppear {
            withAnimation {
                appearAnimation = true
            }

            if stats.accuracy >= 70 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    confettiTrigger = true
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Main stats row
            HStack(spacing: AppTheme.Spacing.md) {
                SessionStatCard(
                    value: "\(stats.quizCorrect)",
                    label: "Correct",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.success
                )

                SessionStatCard(
                    value: "\(stats.quizIncorrect)",
                    label: "Incorrect",
                    icon: "xmark.circle.fill",
                    color: AppTheme.Colors.error
                )
            }

            // Summary row
            HStack(spacing: AppTheme.Spacing.lg) {
                if stats.wordsPreviewd > 0 {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.accent)
                        Text("\(stats.wordsPreviewd) previewed")
                            .font(AppTheme.Typography.labelSmall(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }

                if stats.deepMomentCompleted {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.warning)
                        Text("Deep moment \(stats.deepMomentCorrect ? "passed" : "reviewed")")
                            .font(AppTheme.Typography.labelSmall(.medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
            }
            .padding(.top, AppTheme.Spacing.sm)
        }
    }
}

#Preview {
    DailySessionView(config: DailySessionConfig(
        previewWords: [],
        quizWords: [],
        deepLearnWord: nil
    ))
    .modelContainer(for: [Word.self, Deck.self, UserProgress.self, StudySession.self], inMemory: true)
}
