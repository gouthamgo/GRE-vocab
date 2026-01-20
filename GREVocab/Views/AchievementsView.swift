import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var achievements: [Achievement]
    @Query private var challenges: [DailyChallenge]
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var appearAnimation = false
    @State private var showChallengeDetail: DailyChallenge? = nil

    // Sort achievements: unlocked first, then by category
    var sortedAchievements: [Achievement] {
        achievements.sorted { a, b in
            if a.isUnlocked != b.isUnlocked {
                return a.isUnlocked && !b.isUnlocked
            }
            return a.category.rawValue < b.category.rawValue
        }
    }

    var todayChallenge: DailyChallenge? {
        challenges.first { Calendar.current.isDateInToday($0.date) }
    }

    var filteredAchievements: [Achievement] {
        guard let category = selectedCategory else {
            return sortedAchievements
        }
        return sortedAchievements.filter { $0.category == category }
    }

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Summary Header
                    summaryHeader
                        .padding(.top, AppTheme.Spacing.md)

                    // Daily Challenge Section
                    dailyChallengeSection

                    // Category Filter
                    categoryFilter

                    // Achievements Grid
                    achievementsGrid

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.bodyMedium(.semibold))
                    .foregroundColor(AppTheme.Colors.accent)
                }
            }
        }
        .onAppear {
            initializeAchievementsIfNeeded()
            initializeTodayChallengeIfNeeded()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
        .sheet(item: $showChallengeDetail) { challenge in
            ChallengeDetailView(challenge: challenge)
        }
    }

    // MARK: - Summary Header
    private var summaryHeader: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Trophy
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.warning.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppTheme.Colors.warning)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("\(unlockedCount) / \(achievements.count)")
                    .font(AppTheme.Typography.displaySmall(.black))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Achievements Unlocked")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.Colors.surfaceHighlight)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.Colors.warning)
                            .frame(width: geo.size.width * (achievements.isEmpty ? 0 : Double(unlockedCount) / Double(achievements.count)), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1.5)
                )
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Daily Challenge Section
    private var dailyChallengeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("TODAY'S CHALLENGE")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                Spacer()

                if let challenge = todayChallenge, challenge.isCompleted {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.success)
                        Text("Completed!")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.success)
                    }
                }
            }

            if let challenge = todayChallenge {
                Button {
                    showChallengeDetail = challenge
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(challenge.isCompleted ? AppTheme.Colors.success.opacity(0.15) : AppTheme.Colors.accent.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: challenge.challengeType.icon)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(challenge.isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accent)
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(challenge.title)
                                .font(AppTheme.Typography.bodyMedium(.bold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text(challenge.descriptionText)
                                .font(AppTheme.Typography.bodySmall())
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppTheme.Colors.surfaceHighlight)
                                        .frame(height: 4)

                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(challenge.isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accent)
                                        .frame(width: geo.size.width * challenge.progress, height: 4)
                                }
                            }
                            .frame(height: 4)
                            .padding(.top, AppTheme.Spacing.xxs)
                        }

                        Spacer()

                        VStack(spacing: 2) {
                            Text("+\(challenge.xpReward)")
                                .font(AppTheme.Typography.labelMedium(.bold))
                                .foregroundColor(AppTheme.Colors.accent)
                            Text("XP")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(AppTheme.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(AppTheme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                    .stroke(challenge.isCompleted ? AppTheme.Colors.success.opacity(0.3) : AppTheme.Colors.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            } else {
                // No challenge yet
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                        Text("Challenge loading...")
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
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
    }

    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xs) {
                AchievementFilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    AchievementFilterChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 10)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
    }

    // MARK: - Achievements Grid
    private var achievementsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AppTheme.Spacing.md),
            GridItem(.flexible(), spacing: AppTheme.Spacing.md)
        ], spacing: AppTheme.Spacing.md) {
            ForEach(Array(filteredAchievements.enumerated()), id: \.element.id) { index, achievement in
                AchievementCard(achievement: achievement)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(0.25 + Double(index) * 0.03),
                        value: appearAnimation
                    )
            }
        }
    }

    // MARK: - Helpers
    private func initializeAchievementsIfNeeded() {
        guard achievements.isEmpty else { return }

        for def in AchievementDefinitions.all {
            let achievement = Achievement(
                id: def.id,
                title: def.title,
                description: def.description,
                icon: def.icon,
                category: def.category,
                requirement: def.requirement,
                xpReward: def.xpReward
            )
            modelContext.insert(achievement)
        }
        try? modelContext.save()
    }

    private func initializeTodayChallengeIfNeeded() {
        guard todayChallenge == nil else { return }

        let newChallenge = ChallengeGenerator.generateDailyChallenge()
        modelContext.insert(newChallenge)
        try? modelContext.save()
    }
}

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? categoryColor.opacity(0.15) : AppTheme.Colors.surfaceHighlight)
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(achievement.isUnlocked ? categoryColor : AppTheme.Colors.textTertiary)
            }

            // Title
            Text(achievement.title)
                .font(AppTheme.Typography.bodySmall(.bold))
                .foregroundColor(achievement.isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Description or Progress
            if achievement.isUnlocked {
                Text("Unlocked!")
                    .font(AppTheme.Typography.labelSmall(.medium))
                    .foregroundColor(categoryColor)
            } else {
                VStack(spacing: 4) {
                    Text("\(achievement.currentProgress)/\(achievement.requirement)")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textTertiary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.Colors.surfaceHighlight)
                                .frame(height: 3)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(categoryColor.opacity(0.5))
                                .frame(width: geo.size.width * achievement.progress, height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(achievement.isUnlocked ? categoryColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
        )
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .streak: return AppTheme.Colors.warning
        case .mastery: return AppTheme.Colors.success
        case .session: return AppTheme.Colors.accent
        case .learning: return AppTheme.Colors.tertiary
        case .challenge: return AppTheme.Colors.secondary
        }
    }
}

// MARK: - Filter Chip
struct AchievementFilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(AppTheme.Typography.labelSmall(.semibold))
            }
            .foregroundColor(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textSecondary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Challenge Detail View
struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let challenge: DailyChallenge

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(challenge.isCompleted ? AppTheme.Colors.success.opacity(0.15) : AppTheme.Colors.accent.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: challenge.challengeType.icon)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(challenge.isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accent)
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(challenge.title)
                        .font(AppTheme.Typography.displaySmall(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(challenge.descriptionText)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Progress
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("\(challenge.currentCount) / \(challenge.targetCount)")
                        .font(AppTheme.Typography.displayMedium(.black))
                        .foregroundColor(challenge.isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accent)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.Colors.surfaceHighlight)
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(challenge.isCompleted ? AppTheme.Colors.success : AppTheme.Colors.accent)
                                .frame(width: geo.size.width * challenge.progress, height: 12)
                        }
                    }
                    .frame(height: 12)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                }

                // Reward
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppTheme.Colors.warning)
                    Text("Reward: +\(challenge.xpReward) XP")
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.warning.opacity(0.1))
                )

                if challenge.isCompleted {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Challenge Completed!")
                    }
                    .font(AppTheme.Typography.bodyLarge(.bold))
                    .foregroundColor(AppTheme.Colors.success)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Got it!")
                        .font(AppTheme.Typography.bodyLarge(.bold))
                        .foregroundColor(AppTheme.Colors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                .fill(AppTheme.Colors.accent)
                        )
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .background(AppTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Daily Challenge")
                        .font(AppTheme.Typography.headlineSmall(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
            }
        }
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: [Achievement.self, DailyChallenge.self], inMemory: true)
}
