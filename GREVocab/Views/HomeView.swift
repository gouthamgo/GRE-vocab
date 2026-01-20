import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selectedTab: ContentView.Tab
    @Bindable var deckViewModel: DeckViewModel
    @Bindable var progressViewModel: ProgressViewModel
    @Binding var showSettings: Bool
    @Binding var showSearch: Bool

    // Mode presentations
    @State private var showQuizMode = false
    @State private var showPreviewMode = false
    @State private var showDeepLearnMode = false
    @State private var showAchievements = false
    @State private var appearAnimation = false

    // Daily Session (item-based presentation)
    @State private var dailySessionConfig: DailySessionConfig?

    // Intro screens (kept for "Other ways to learn")
    @State private var showPreviewIntro = false
    @State private var showQuizIntro = false
    @State private var showDeepLearnIntro = false

    // Learning path stats (computed from all words)
    private var allWords: [Word] {
        deckViewModel.decks.flatMap { $0.words }
    }

    private var stats: LearningPathStats {
        LearningPathService.shared.getStats(for: allWords)
    }

    private var recommendation: LearningRecommendation {
        LearningPathService.shared.getRecommendation(for: allWords)
    }

    private var sessionSummary: (preview: Int, quiz: Int, deepLearn: Bool) {
        LearningPathService.shared.getDailySessionSummary(for: allWords)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Learning Path Visualization
                    learningPathSection
                        .padding(.bottom, AppTheme.Spacing.lg)

                    // Primary Action (Recommended)
                    recommendedActionSection
                        .padding(.bottom, AppTheme.Spacing.xl)

                    // Today's Stats
                    todayStatsSection
                        .padding(.bottom, AppTheme.Spacing.xl)

                    // Other Learning Modes
                    otherModesSection
                        .padding(.bottom, AppTheme.Spacing.lg)

                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: 120)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 32)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Button {
                            HapticManager.shared.lightImpact()
                            showSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .accessibilityLabel("Search all words")

                        Button {
                            HapticManager.shared.lightImpact()
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .accessibilityLabel("Settings")

                        streakBadge
                    }
                }
            }
            .fullScreenCover(isPresented: $showQuizMode) {
                ActiveRecallView(decks: deckViewModel.decks)
                    .onDisappear {
                        refreshData()
                    }
            }
            .fullScreenCover(isPresented: $showPreviewMode) {
                FlashcardView(decks: deckViewModel.decks, isPreviewMode: true)
                    .onDisappear {
                        refreshData()
                    }
            }
            .fullScreenCover(isPresented: $showDeepLearnMode) {
                if let firstDeck = deckViewModel.decks.first {
                    FeynmanModeView(deck: firstDeck)
                        .onDisappear {
                            refreshData()
                        }
                } else {
                    // Empty state - dismiss automatically
                    Text("No words available")
                        .onAppear { showDeepLearnMode = false }
                }
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            // Daily Session
            .fullScreenCover(item: $dailySessionConfig) { config in
                DailySessionView(config: config)
                    .onDisappear {
                        refreshData()
                    }
            }
            // Mode intro screens
            .fullScreenCover(isPresented: $showPreviewIntro) {
                ModeIntroView(
                    mode: .preview,
                    wordCount: stats.unseen,
                    onStart: {
                        showPreviewIntro = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showPreviewMode = true
                        }
                    },
                    onDismiss: { showPreviewIntro = false }
                )
            }
            .fullScreenCover(isPresented: $showQuizIntro) {
                ModeIntroView(
                    mode: .quiz,
                    wordCount: stats.readyForQuiz,
                    onStart: {
                        showQuizIntro = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showQuizMode = true
                        }
                    },
                    onDismiss: { showQuizIntro = false }
                )
            }
            .fullScreenCover(isPresented: $showDeepLearnIntro) {
                ModeIntroView(
                    mode: .deepLearn,
                    wordCount: stats.needsDeepLearn,
                    onStart: {
                        showDeepLearnIntro = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showDeepLearnMode = true
                        }
                    },
                    onDismiss: { showDeepLearnIntro = false }
                )
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .none : .spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Learning Path Section
    private var learningPathSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Text("YOUR LEARNING PATH")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                Spacer()

                Text("\(Int(stats.learningPercentage))% progressed")
                    .font(AppTheme.Typography.labelSmall(.medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            // Path visualization
            HStack(spacing: 0) {
                // Preview Stage
                pathStage(
                    icon: "eye.fill",
                    label: "Preview",
                    count: stats.unseen,
                    countLabel: "new",
                    color: AppTheme.Colors.accent,
                    isActive: recommendation == .preview(count: 0, reason: "")
                )

                pathArrow

                // Quiz Stage
                pathStage(
                    icon: "questionmark.circle.fill",
                    label: "Quiz",
                    count: stats.readyForQuiz,
                    countLabel: "ready",
                    color: AppTheme.Colors.tertiary,
                    isActive: {
                        if case .quiz = recommendation { return true }
                        return false
                    }()
                )

                pathArrow

                // Deep Learn Stage
                pathStage(
                    icon: "lightbulb.fill",
                    label: "Deep",
                    count: stats.needsDeepLearn,
                    countLabel: "need",
                    color: AppTheme.Colors.warning,
                    isActive: {
                        if case .deepLearn = recommendation { return true }
                        return false
                    }()
                )

                pathArrow

                // Mastered
                pathStage(
                    icon: "checkmark.seal.fill",
                    label: "Done",
                    count: stats.mastered,
                    countLabel: "mastered",
                    color: AppTheme.Colors.success,
                    isActive: recommendation == .allCaughtUp
                )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 8)

                    // Stacked progress
                    HStack(spacing: 0) {
                        // Mastered (green)
                        if stats.mastered > 0 {
                            Rectangle()
                                .fill(AppTheme.Colors.success)
                                .frame(width: geo.size.width * progressFraction(stats.mastered))
                        }
                        // Deep learned (yellow)
                        if stats.deepLearned > 0 {
                            Rectangle()
                                .fill(AppTheme.Colors.warning)
                                .frame(width: geo.size.width * progressFraction(stats.deepLearned))
                        }
                        // Quiz passed (purple)
                        if stats.quizPassed > 0 {
                            Rectangle()
                                .fill(AppTheme.Colors.tertiary)
                                .frame(width: geo.size.width * progressFraction(stats.quizPassed))
                        }
                        // Previewed (blue)
                        if stats.previewed > 0 {
                            Rectangle()
                                .fill(AppTheme.Colors.accent.opacity(0.5))
                                .frame(width: geo.size.width * progressFraction(stats.previewed))
                        }
                    }
                    .frame(height: 8)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(height: 8)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
        )
        .padding(.top, AppTheme.Spacing.md)
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func pathStage(icon: String, label: String, count: Int, countLabel: String, color: Color, isActive: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(isActive ? color.opacity(0.2) : AppTheme.Colors.surfaceHighlight)
                    .frame(width: 44, height: 44)

                if isActive {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isActive ? color : AppTheme.Colors.textTertiary)
            }

            Text(label)
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(isActive ? color : AppTheme.Colors.textTertiary)

            Text("\(count)")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(isActive ? color : AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var pathArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))
    }

    // MARK: - Recommended Action Section (Daily Session)
    private var recommendedActionSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            if progressViewModel.userProgress?.hasDoneSessionToday == true {
                // Done for today state
                sessionCompletedCard
            } else {
                // Start session button
                startSessionButton
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.15), value: appearAnimation)
    }

    // MARK: - Session Completed Card
    private var sessionCompletedCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Success card
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 56, height: 56)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Done for Today!")
                            .font(AppTheme.Typography.headlineMedium(.bold))

                        Text("Great work! Come back tomorrow")
                            .font(AppTheme.Typography.bodySmall())
                            .opacity(0.9)
                    }

                    Spacer()
                }

                // Today's stats summary
                HStack(spacing: AppTheme.Spacing.lg) {
                    if let progress = progressViewModel.userProgress {
                        sessionPreviewItem(
                            icon: "book.fill",
                            count: progress.todayWordsStudied,
                            label: "studied"
                        )
                        sessionPreviewItem(
                            icon: "flame.fill",
                            count: progress.currentStreak,
                            label: "day streak"
                        )
                    }
                }
            }
            .foregroundColor(.white)
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.success, AppTheme.Colors.success.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: AppTheme.Colors.success.opacity(0.3), radius: 15, x: 0, y: 8)

            // Optional: Do more section
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("WANT TO DO MORE?")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)
                    .padding(.top, AppTheme.Spacing.sm)

                Button {
                    HapticManager.shared.mediumImpact()
                    startDailySession()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Another Session")
                            .font(AppTheme.Typography.bodySmall(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }
            }
        }
    }

    // MARK: - Start Session Button
    private var startSessionButton: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                HapticManager.shared.mediumImpact()
                startDailySession()
            } label: {
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 56, height: 56)
                            Image(systemName: "play.fill")
                                .font(.system(size: 24, weight: .bold))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Today's Session")
                                .font(AppTheme.Typography.headlineMedium(.bold))

                            Text(dailySessionDescription)
                                .font(AppTheme.Typography.bodySmall())
                                .opacity(0.9)
                        }

                        Spacer()
                    }

                    HStack(spacing: AppTheme.Spacing.lg) {
                        if sessionSummary.preview > 0 {
                            sessionPreviewItem(
                                icon: "eye.fill",
                                count: sessionSummary.preview,
                                label: "new"
                            )
                        }
                        if sessionSummary.quiz > 0 {
                            sessionPreviewItem(
                                icon: "questionmark.circle.fill",
                                count: sessionSummary.quiz,
                                label: "quiz"
                            )
                        }
                        if sessionSummary.deepLearn {
                            sessionPreviewItem(
                                icon: "lightbulb.fill",
                                count: 1,
                                label: "deep"
                            )
                        }
                    }
                }
                .foregroundColor(.white)
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.accent, AppTheme.Colors.tertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: AppTheme.Colors.accent.opacity(0.4), radius: 20, x: 0, y: 10)
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "clock.fill")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Text("~5 minutes")
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .font(AppTheme.Typography.labelSmall(.medium))

            if stats.struggling > 0 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.Colors.warning)
                    Text("\(stats.struggling) words need extra attention")
                        .foregroundColor(AppTheme.Colors.warning)
                }
                .font(AppTheme.Typography.labelSmall(.medium))
            }
        }
    }

    private func sessionPreviewItem(icon: String, count: Int, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text("\(count) \(label)")
                .font(AppTheme.Typography.labelSmall(.medium))
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .background(Capsule().fill(Color.white.opacity(0.2)))
    }

    private var dailySessionDescription: String {
        if recommendation == .allCaughtUp {
            return "Review to maintain mastery"
        }
        let parts: [String] = [
            sessionSummary.preview > 0 ? "Learn new words" : nil,
            sessionSummary.quiz > 0 ? "quiz" : nil,
            sessionSummary.deepLearn ? "deep practice" : nil
        ].compactMap { $0 }
        return parts.joined(separator: ", ").capitalized
    }

    private func startDailySession() {
        // Setting the config directly triggers the fullScreenCover(item:)
        dailySessionConfig = LearningPathService.shared.buildDailySession(from: allWords)
    }

    // Legacy recommendation handling (for "Other ways to learn")
    private var recommendationColor: Color {
        switch recommendation {
        case .preview: return AppTheme.Colors.accent
        case .quiz: return AppTheme.Colors.tertiary
        case .deepLearn: return AppTheme.Colors.warning
        case .allCaughtUp: return AppTheme.Colors.success
        }
    }

    private func handleRecommendedAction() {
        switch recommendation {
        case .preview:
            showPreviewIntro = true
        case .quiz:
            showQuizIntro = true
        case .deepLearn:
            showDeepLearnIntro = true
        case .allCaughtUp:
            showQuizIntro = true // Default to quiz for review
        }
    }

    // MARK: - Today's Stats
    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("TODAY")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            HStack(spacing: AppTheme.Spacing.md) {
                StatCard(
                    title: "Quizzed",
                    value: "\(progressViewModel.userProgress?.todayWordsStudied ?? 0)",
                    icon: "questionmark.circle.fill",
                    color: AppTheme.Colors.tertiary,
                    subtitle: "of \(progressViewModel.userProgress?.dailyGoal ?? 20) goal"
                )

                StatCard(
                    title: "Accuracy",
                    value: "\(Int(progressViewModel.userProgress?.accuracy ?? 0))%",
                    icon: "target",
                    color: AppTheme.Colors.secondary
                )
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
    }

    // MARK: - Other Modes Section
    private var otherModesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text(progressViewModel.userProgress?.hasDoneSessionToday == true ? "OPTIONAL EXTRAS" : "OTHER WAYS TO LEARN")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                if progressViewModel.userProgress?.hasDoneSessionToday == true {
                    Text("(not required)")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.6))
                }
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                // Preview Mode (if not recommended)
                if case .preview = recommendation {
                    // Already recommended, don't show here
                } else {
                    ModeButton(
                        icon: "eye.fill",
                        title: "Preview New Words",
                        subtitle: "Quick look at \(stats.unseen) new words",
                        color: AppTheme.Colors.accent,
                        isSecondary: true
                    ) {
                        showPreviewIntro = true
                    }
                }

                // Quiz Mode (if not recommended)
                if case .quiz = recommendation {
                    // Already recommended, don't show here
                } else if stats.readyForQuiz > 0 {
                    ModeButton(
                        icon: "questionmark.circle.fill",
                        title: "Quiz Yourself",
                        subtitle: "\(stats.readyForQuiz) words ready to test",
                        color: AppTheme.Colors.tertiary,
                        isSecondary: true
                    ) {
                        showQuizIntro = true
                    }
                }

                // Deep Learn Mode (if not recommended)
                if case .deepLearn = recommendation {
                    // Already recommended, don't show here
                } else if stats.needsDeepLearn > 0 {
                    ModeButton(
                        icon: "lightbulb.fill",
                        title: "Deep Practice",
                        subtitle: "\(stats.needsDeepLearn) words need attention",
                        color: AppTheme.Colors.warning,
                        isSecondary: true
                    ) {
                        showDeepLearnIntro = true
                    }
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4), value: appearAnimation)
    }

    // MARK: - Streak Badge
    private var streakBadge: some View {
        Button {
            HapticManager.shared.lightImpact()
            showAchievements = true
        } label: {
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.Colors.warning)

                Text("\(progressViewModel.userProgress?.currentStreak ?? 0)")
                    .font(AppTheme.Typography.labelLarge())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.warning.opacity(0.15))
            )
        }
        .accessibilityLabel("View achievements")
    }

    // MARK: - Helpers
    private func progressFraction(_ count: Int) -> Double {
        guard stats.total > 0 else { return 0 }
        return Double(count) / Double(stats.total)
    }

    private func refreshData() {
        deckViewModel.loadDecks(modelContext: modelContext)
        progressViewModel.load(modelContext: modelContext)
    }
}

// MARK: - Mode Button
struct ModeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isSecondary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(subtitle)
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
    }
}

#Preview {
    HomeView(
        selectedTab: .constant(.home),
        deckViewModel: DeckViewModel(),
        progressViewModel: ProgressViewModel(),
        showSettings: .constant(false),
        showSearch: .constant(false)
    )
    .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}
