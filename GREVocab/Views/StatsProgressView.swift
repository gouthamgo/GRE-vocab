import SwiftUI
import SwiftData
import Charts

struct StatsProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var viewModel: ProgressViewModel
    @State private var appearAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Time Period Selector
                    timeframePicker
                        .padding(.top, AppTheme.Spacing.md)

                    // Hero Stats
                    heroStatsSection

                    // Streak Section
                    streakSection

                    // Activity Chart
                    activityChartSection

                    // Time-filtered Stats
                    timeFilteredStatsSection

                    // Difficult Words
                    difficultWordsSection

                    // Word Status Distribution
                    distributionSection

                    // Detailed Stats
                    detailedStatsSection

                    // Recent Sessions
                    recentSessionsSection

                    // Bottom padding
                    Spacer().frame(height: 120)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.Colors.background, for: .navigationBar)
        }
        .onAppear {
            viewModel.load(modelContext: modelContext)
            withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Timeframe Picker
    private var timeframePicker: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(StatsTimeframe.allCases, id: \.self) { timeframe in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedTimeframe = timeframe
                    }
                    HapticManager.shared.selection()
                } label: {
                    Text(timeframe.rawValue)
                        .font(AppTheme.Typography.labelMedium(.semibold))
                        .foregroundColor(viewModel.selectedTimeframe == timeframe ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedTimeframe == timeframe ? AppTheme.Colors.accent : Color.clear)
                        )
                }
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.Colors.surface)
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 10)
    }

    // MARK: - Time Filtered Stats Section
    private var timeFilteredStatsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("\(viewModel.selectedTimeframe.rawValue.uppercased()) ACTIVITY")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md)
            ], spacing: AppTheme.Spacing.md) {
                DetailStatCard(
                    title: "Words Studied",
                    value: "\(viewModel.filteredWordsStudied)",
                    icon: "book.fill",
                    color: AppTheme.Colors.accent
                )

                DetailStatCard(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", viewModel.filteredAccuracy),
                    icon: "target",
                    color: AppTheme.Colors.secondary
                )

                DetailStatCard(
                    title: "Sessions",
                    value: "\(viewModel.filteredSessionsCount)",
                    icon: "clock.fill",
                    color: AppTheme.Colors.tertiary
                )

                DetailStatCard(
                    title: "Study Time",
                    value: viewModel.formattedFilteredStudyTime,
                    icon: "hourglass",
                    color: AppTheme.Colors.warning
                )
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
    }

    // MARK: - Recent Sessions Section
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("RECENT SESSIONS")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            if viewModel.filteredSessions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text("No sessions yet")
                            .font(AppTheme.Typography.bodySmall())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(.vertical, AppTheme.Spacing.xl)
                    Spacer()
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.surface)
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(viewModel.filteredSessions.prefix(5))) { session in
                        SessionRow(session: session)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.surface)
                )
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: appearAnimation)
    }

    // MARK: - Hero Stats
    private var heroStatsSection: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Main progress ring
            VStack(spacing: AppTheme.Spacing.md) {
                ProgressRing(
                    progress: viewModel.overallProgress,
                    lineWidth: 12,
                    color: AppTheme.Colors.accent,
                    size: 140
                )

                Text("OVERALL MASTERY")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)
            }
            .opacity(appearAnimation ? 1 : 0)
            .scaleEffect(appearAnimation ? 1 : 0.8)

            // Quick stats
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                QuickStat(
                    label: "Total Words",
                    value: "\(viewModel.totalWords)",
                    icon: "textformat.abc",
                    color: AppTheme.Colors.accent
                )

                QuickStat(
                    label: "Mastered",
                    value: "\(viewModel.masteredWords)",
                    icon: "checkmark.seal.fill",
                    color: AppTheme.Colors.success
                )

                QuickStat(
                    label: "Due Today",
                    value: "\(viewModel.dueForReview)",
                    icon: "clock.fill",
                    color: AppTheme.Colors.warning
                )
            }
            .opacity(appearAnimation ? 1 : 0)
            .offset(x: appearAnimation ? 0 : 20)
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [AppTheme.Colors.accent.opacity(0.3), AppTheme.Colors.surfaceHighlight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
    }

    // MARK: - Streak Section
    private var streakSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Current streak
            VStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.warning.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppTheme.Colors.warning)
                }

                Text("\(viewModel.userProgress?.currentStreak ?? 0)")
                    .font(AppTheme.Typography.displaySmall(.black))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("DAY STREAK")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                    )
            )

            // Best streak
            VStack(spacing: AppTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.tertiary.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.Colors.tertiary)
                }

                Text("\(viewModel.userProgress?.longestStreak ?? 0)")
                    .font(AppTheme.Typography.displaySmall(.black))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("BEST STREAK")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .stroke(AppTheme.Colors.tertiary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
    }

    // MARK: - Activity Chart Section
    private var activityChartSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("7-DAY ACTIVITY")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            VStack(spacing: AppTheme.Spacing.md) {
                if viewModel.weeklyActivityData.reduce(0, { $0 + $1.wordsStudied }) == 0 {
                    // No data state
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.5))

                        Text("No activity yet")
                            .font(AppTheme.Typography.bodySmall())
                            .foregroundColor(AppTheme.Colors.textTertiary)

                        Text("Start studying to see your progress")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xl)
                } else {
                    // Chart
                    Chart(viewModel.weeklyActivityData) { data in
                        BarMark(
                            x: .value("Day", data.dayLabel),
                            y: .value("Words", data.wordsStudied)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.Colors.accent, AppTheme.Colors.accent.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                .foregroundStyle(AppTheme.Colors.surfaceHighlight)
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                    .frame(height: 180)
                    .padding(.top, AppTheme.Spacing.sm)

                    // Summary stats below chart
                    HStack(spacing: AppTheme.Spacing.lg) {
                        ChartSummaryItem(
                            value: "\(viewModel.weeklyActivityData.reduce(0) { $0 + $1.wordsStudied })",
                            label: "Total Words",
                            color: AppTheme.Colors.accent
                        )

                        Divider()
                            .frame(height: 30)
                            .background(AppTheme.Colors.surfaceHighlight)

                        ChartSummaryItem(
                            value: String(format: "%.0f", viewModel.weeklyActivityData.map { $0.wordsStudied }.max() ?? 0),
                            label: "Best Day",
                            color: AppTheme.Colors.success
                        )

                        Divider()
                            .frame(height: 30)
                            .background(AppTheme.Colors.surfaceHighlight)

                        ChartSummaryItem(
                            value: String(format: "%.0f", Double(viewModel.weeklyActivityData.reduce(0) { $0 + $1.wordsStudied }) / 7.0),
                            label: "Daily Avg",
                            color: AppTheme.Colors.secondary
                        )
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25), value: appearAnimation)
    }

    // MARK: - Difficult Words Section
    private var difficultWordsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("CHALLENGING WORDS")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                Spacer()

                if !viewModel.difficultWords.isEmpty {
                    Text("\(viewModel.difficultWords.count) words")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }

            if viewModel.difficultWords.isEmpty {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(AppTheme.Colors.success.opacity(0.7))

                    Text("No challenging words yet")
                        .font(AppTheme.Typography.bodySmall())
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text("Keep studying and we'll track words you find difficult")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.xl)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.surface)
                )
            } else {
                VStack(spacing: AppTheme.Spacing.xs) {
                    ForEach(viewModel.difficultWords, id: \.term) { word in
                        DifficultWordRow(word: word)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.surface)
                )
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: appearAnimation)
    }

    // MARK: - Distribution Section (Learning Path)
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("LEARNING PATH")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            VStack(spacing: AppTheme.Spacing.lg) {
                // Learning path visual
                HStack(spacing: 0) {
                    LearningStageIndicator(
                        icon: "sparkles",
                        label: "New",
                        count: viewModel.unseenWords,
                        color: AppTheme.Colors.textTertiary,
                        total: viewModel.totalWords
                    )

                    stageArrow

                    LearningStageIndicator(
                        icon: "eye.fill",
                        label: "Preview",
                        count: viewModel.previewedWords,
                        color: AppTheme.Colors.accent,
                        total: viewModel.totalWords
                    )

                    stageArrow

                    LearningStageIndicator(
                        icon: "checkmark.circle.fill",
                        label: "Quiz",
                        count: viewModel.quizPassedWords,
                        color: AppTheme.Colors.tertiary,
                        total: viewModel.totalWords
                    )

                    stageArrow

                    LearningStageIndicator(
                        icon: "lightbulb.fill",
                        label: "Deep",
                        count: viewModel.deepLearnedWords,
                        color: AppTheme.Colors.warning,
                        total: viewModel.totalWords
                    )
                }

                // Combined progress bar
                VStack(spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text("Progress")
                            .font(AppTheme.Typography.labelSmall(.medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Spacer()
                        Text("\(Int(viewModel.learningPathProgress * 100))%")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.accent)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.Colors.surfaceHighlight)
                                .frame(height: 10)

                            HStack(spacing: 0) {
                                // Deep learned (gold)
                                if viewModel.deepLearnedWords > 0 {
                                    Rectangle()
                                        .fill(AppTheme.Colors.warning)
                                        .frame(width: geo.size.width * progressFraction(viewModel.deepLearnedWords))
                                }
                                // Quiz passed (purple)
                                if viewModel.quizPassedWords > 0 {
                                    Rectangle()
                                        .fill(AppTheme.Colors.tertiary)
                                        .frame(width: geo.size.width * progressFraction(viewModel.quizPassedWords))
                                }
                                // Previewed (blue faded)
                                if viewModel.previewedWords > 0 {
                                    Rectangle()
                                        .fill(AppTheme.Colors.accent.opacity(0.5))
                                        .frame(width: geo.size.width * progressFraction(viewModel.previewedWords))
                                }
                            }
                            .frame(height: 10)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    .frame(height: 10)
                }

                // Action needed section
                if viewModel.strugglingWords > 0 || viewModel.dueForQuizReview > 0 {
                    Divider()
                        .background(AppTheme.Colors.surfaceHighlight)

                    VStack(spacing: AppTheme.Spacing.sm) {
                        if viewModel.strugglingWords > 0 {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.error)
                                Text("\(viewModel.strugglingWords) words need attention")
                                    .font(AppTheme.Typography.labelSmall(.medium))
                                    .foregroundColor(AppTheme.Colors.error)
                                Spacer()
                            }
                        }

                        if viewModel.dueForQuizReview > 0 {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(AppTheme.Colors.warning)
                                Text("\(viewModel.dueForQuizReview) words due for review")
                                    .font(AppTheme.Typography.labelSmall(.medium))
                                    .foregroundColor(AppTheme.Colors.warning)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appearAnimation)
    }

    private var stageArrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 8, weight: .bold))
            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.4))
    }

    private func progressFraction(_ count: Int) -> Double {
        guard viewModel.totalWords > 0 else { return 0 }
        return Double(count) / Double(viewModel.totalWords)
    }

    // MARK: - Detailed Stats
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("STATISTICS")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.md),
                GridItem(.flexible(), spacing: AppTheme.Spacing.md)
            ], spacing: AppTheme.Spacing.md) {
                DetailStatCard(
                    title: "Total Studied",
                    value: "\(viewModel.userProgress?.totalWordsStudied ?? 0)",
                    icon: "book.fill",
                    color: AppTheme.Colors.accent
                )

                DetailStatCard(
                    title: "Accuracy",
                    value: String(format: "%.1f%%", viewModel.userProgress?.accuracy ?? 0),
                    icon: "target",
                    color: AppTheme.Colors.secondary
                )

                DetailStatCard(
                    title: "Correct",
                    value: "\(viewModel.userProgress?.totalCorrect ?? 0)",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.success
                )

                DetailStatCard(
                    title: "Incorrect",
                    value: "\(viewModel.userProgress?.totalIncorrect ?? 0)",
                    icon: "xmark.circle.fill",
                    color: AppTheme.Colors.error
                )
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appearAnimation)
    }
}

// MARK: - Quick Stat
struct QuickStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppTheme.Typography.headlineSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(label)
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
    }
}

// MARK: - Status Bar
struct StatusBar: View {
    let label: String
    let value: Int
    let total: Int
    let color: Color

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(value) / Double(total)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            HStack {
                Text(label)
                    .font(AppTheme.Typography.bodySmall(.medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Spacer()

                Text("\(value)")
                    .font(AppTheme.Typography.labelLarge())
                    .foregroundColor(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Detail Stat Card
struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(AppTheme.Typography.headlineLarge(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(title)
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Session Row
struct SessionRow: View {
    let session: StudySession

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Session type icon
            ZStack {
                Circle()
                    .fill(sessionColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: sessionIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(sessionColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sessionTypeName)
                    .font(AppTheme.Typography.bodySmall(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(formattedDate)
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.wordsStudied) words")
                    .font(AppTheme.Typography.labelMedium(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(String(format: "%.0f%% accuracy", session.accuracy))
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(session.accuracy >= 80 ? AppTheme.Colors.success : AppTheme.Colors.warning)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private var sessionTypeName: String {
        switch session.sessionType {
        case "review": return "Review Session"
        case "deck": return session.deckName ?? "Deck Study"
        case "feynman": return "Feynman Mode"
        case "quiz": return "Quiz"
        case "challenge": return "Challenge"
        default: return "Study Session"
        }
    }

    private var sessionIcon: String {
        switch session.sessionType {
        case "review": return "arrow.clockwise"
        case "deck": return "rectangle.stack"
        case "feynman": return "lightbulb"
        case "quiz": return "questionmark.circle"
        case "challenge": return "flame"
        default: return "book"
        }
    }

    private var sessionColor: Color {
        switch session.sessionType {
        case "review": return AppTheme.Colors.accent
        case "deck": return AppTheme.Colors.secondary
        case "feynman": return AppTheme.Colors.warning
        case "quiz": return AppTheme.Colors.tertiary
        case "challenge": return AppTheme.Colors.error
        default: return AppTheme.Colors.textSecondary
        }
    }

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: session.date, relativeTo: Date())
    }
}

// MARK: - Chart Summary Item
struct ChartSummaryItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppTheme.Typography.headlineSmall(.bold))
                .foregroundColor(color)

            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Difficult Word Row
struct DifficultWordRow: View {
    let word: Word

    var accuracy: Double {
        guard word.timesReviewed > 0 else { return 0 }
        return Double(word.timesCorrect) / Double(word.timesReviewed) * 100
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Accuracy indicator
            ZStack {
                Circle()
                    .fill(accuracyColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(String(format: "%.0f%%", accuracy))
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(accuracyColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(word.term)
                    .font(AppTheme.Typography.bodyMedium(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("\(word.timesCorrect)/\(word.timesReviewed) correct")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text("•")
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    Text(word.difficulty.rawValue)
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(word.difficulty.themeColor)
                }
            }

            Spacer()

            // Ease factor indicator
            VStack(alignment: .trailing, spacing: 2) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.Colors.textTertiary)

                Text(String(format: "%.1f", word.easeFactor))
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private var accuracyColor: Color {
        switch accuracy {
        case 0..<30: return AppTheme.Colors.error
        case 30..<60: return AppTheme.Colors.warning
        default: return AppTheme.Colors.tertiary
        }
    }
}

// MARK: - Learning Stage Indicator
struct LearningStageIndicator: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    let total: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            ZStack {
                Circle()
                    .fill(count > 0 ? color.opacity(0.15) : AppTheme.Colors.surfaceHighlight)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(count > 0 ? color : AppTheme.Colors.textTertiary.opacity(0.5))
            }

            Text(label)
                .font(AppTheme.Typography.labelSmall())
                .foregroundColor(count > 0 ? color : AppTheme.Colors.textTertiary.opacity(0.5))

            Text("\(count)")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(count > 0 ? color : AppTheme.Colors.textTertiary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StatsProgressView(viewModel: ProgressViewModel())
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self, StudySession.self], inMemory: true)
}