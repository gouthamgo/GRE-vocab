import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var userProgress: UserProgress?

    // Settings state
    @AppStorage("hapticFeedbackEnabled") private var hapticEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = false
    @State private var dailyGoal: Int = 20

    @State private var showResetAlert = false
    @State private var showRebuildAlert = false
    @State private var showHowItWorks = false
    @State private var showFeynmanMode = false
    @State private var showActiveRecall = false
    @State private var appearAnimation = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Help & How It Works
                    helpSection

                    // Study Settings
                    studySettingsSection

                    // Advanced Study Modes
                    studyModesSection

                    // Feedback Settings
                    feedbackSettingsSection

                    // Audio Settings
                    audioSettingsSection

                    // Data Management
                    dataManagementSection

                    // About
                    aboutSection

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("Settings")
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
            loadSettings()
            withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
        .alert("Reset Progress", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetProgress()
            }
        } message: {
            Text("This will reset all your learning progress. This action cannot be undone.")
        }
        .alert("Rebuild Database", isPresented: $showRebuildAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Rebuild", role: .destructive) {
                rebuildDatabase()
            }
        } message: {
            Text("This will delete all existing data and re-import words from source files. All progress will be lost.")
        }
        .sheet(isPresented: $showHowItWorks) {
            HowItWorksView()
        }
    }

    // MARK: - Help Section
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("HELP")

            VStack(spacing: 0) {
                Button {
                    showHowItWorks = true
                } label: {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("How It Works")
                                .font(AppTheme.Typography.bodyMedium(.medium))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Learn about spaced repetition & study modes")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Study Settings
    private var studySettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("STUDY")

            VStack(spacing: 0) {
                // Daily Goal
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Label("Daily Goal", systemImage: "target")
                            .font(AppTheme.Typography.bodyMedium(.medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()

                        Text("\(dailyGoal) words")
                            .font(AppTheme.Typography.bodyMedium(.semibold))
                            .foregroundColor(AppTheme.Colors.accent)
                    }

                    Slider(value: Binding(
                        get: { Double(dailyGoal) },
                        set: { dailyGoal = Int($0); saveDailyGoal() }
                    ), in: 5...50, step: 5)
                    .tint(AppTheme.Colors.accent)
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    // MARK: - Study Modes Section
    private var studyModesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("ADVANCED MODES")

            VStack(spacing: 0) {
                // Feynman Mode
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.warning)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Feynman Mode")
                            .font(AppTheme.Typography.bodyMedium(.medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Deep learning by explaining in your own words")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }

                    Spacer()

                    Text("In Decks")
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.surfaceHighlight)
                        )
                }
                .padding(AppTheme.Spacing.lg)

                Divider()
                    .background(AppTheme.Colors.surfaceHighlight)
                    .padding(.leading, 56)

                // Active Recall
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.tertiary)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Active Recall Quiz")
                            .font(AppTheme.Typography.bodyMedium(.medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Multiple choice and fill-in-the-blank questions")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }

                    Spacer()

                    Text("In Decks")
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(AppTheme.Colors.surfaceHighlight)
                        )
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )

            // Helper text
            Text("These modes are available when viewing individual decks. Tap a deck and look for \"More study options\".")
                .font(AppTheme.Typography.labelSmall())
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.horizontal, AppTheme.Spacing.xs)
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
    }

    // MARK: - Feedback Settings
    private var feedbackSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("FEEDBACK")

            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    title: "Haptic Feedback",
                    subtitle: "Vibration on interactions",
                    isOn: $hapticEnabled
                )
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
    }

    // MARK: - Audio Settings
    private var audioSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("AUDIO")

            VStack(spacing: 0) {
                SettingsToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sound Effects",
                    subtitle: "Audio feedback on actions",
                    isOn: $soundEnabled
                )

                Divider()
                    .background(AppTheme.Colors.surfaceHighlight)
                    .padding(.leading, 56)

                SettingsToggleRow(
                    icon: "waveform",
                    title: "Auto-Play Pronunciation",
                    subtitle: "Speak word when card appears",
                    isOn: $autoPlayPronunciation
                )
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
    }

    // MARK: - Data Management
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("DATA")

            VStack(spacing: 0) {
                Button {
                    HapticManager.shared.warning()
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.error)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset Progress")
                                .font(AppTheme.Typography.bodyMedium(.medium))
                                .foregroundColor(AppTheme.Colors.error)

                            Text("Clear all learning data")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(AppTheme.Spacing.lg)
                }

                Divider()
                    .background(AppTheme.Colors.surfaceHighlight)
                    .padding(.leading, 56)

                Button {
                    HapticManager.shared.warning()
                    showRebuildAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.warning)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rebuild Database")
                                .font(AppTheme.Typography.bodyMedium(.medium))
                                .foregroundColor(AppTheme.Colors.warning)

                            Text("Re-import words from source files")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: appearAnimation)
    }

    // MARK: - About
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("ABOUT")

            VStack(spacing: 0) {
                SettingsInfoRow(icon: "info.circle.fill", title: "Version", value: "1.0.0")

                Divider()
                    .background(AppTheme.Colors.surfaceHighlight)
                    .padding(.leading, 56)

                SettingsInfoRow(icon: "book.fill", title: "Total Words", value: "\(getTotalWords())")
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.surface)
            )
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: appearAnimation)
    }

    // MARK: - Helpers
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Typography.labelSmall(.bold))
            .foregroundColor(AppTheme.Colors.textTertiary)
            .tracking(1.5)
    }

    private func loadSettings() {
        do {
            userProgress = try DataService.shared.getUserProgress(modelContext: modelContext)
            dailyGoal = userProgress?.dailyGoal ?? 20
        } catch {
            print("Error loading settings: \(error)")
        }
    }

    private func saveDailyGoal() {
        userProgress?.dailyGoal = dailyGoal
        modelContext.trySave(operation: "save daily goal")
    }

    private func resetProgress() {
        // Reset all words to new status
        let descriptor = FetchDescriptor<Word>()
        do {
            let words = try modelContext.fetch(descriptor)
            for word in words {
                word.status = .new
                word.repetitions = 0
                word.easeFactor = 2.5
                word.interval = 0
                word.lastReviewDate = nil
                word.nextReviewDate = nil
            }
        } catch {
            print("Error fetching words for reset: \(error)")
        }

        // Reset user progress
        userProgress?.currentStreak = 0
        userProgress?.longestStreak = 0
        userProgress?.totalWordsStudied = 0
        userProgress?.totalCorrect = 0
        userProgress?.totalIncorrect = 0
        userProgress?.lastStudyDate = nil

        do {
            try modelContext.safeSave(operation: "reset progress")
            HapticManager.shared.success()
        } catch {
            print("Error saving reset progress: \(error)")
            HapticManager.shared.warning()
        }
    }

    private func rebuildDatabase() {
        do {
            // Delete all existing decks (and their words through cascade)
            let deckDescriptor = FetchDescriptor<Deck>()
            let decks = try modelContext.fetch(deckDescriptor)
            for deck in decks {
                modelContext.delete(deck)
            }

            // Delete all orphaned words
            let wordDescriptor = FetchDescriptor<Word>()
            let words = try modelContext.fetch(wordDescriptor)
            for word in words {
                modelContext.delete(word)
            }

            // Delete all study sessions
            let sessionDescriptor = FetchDescriptor<StudySession>()
            let sessions = try modelContext.fetch(sessionDescriptor)
            for session in sessions {
                modelContext.delete(session)
            }

            // Delete user progress
            let progressDescriptor = FetchDescriptor<UserProgress>()
            let progressList = try modelContext.fetch(progressDescriptor)
            for progress in progressList {
                modelContext.delete(progress)
            }

            // Delete achievements
            let achievementDescriptor = FetchDescriptor<Achievement>()
            let achievements = try modelContext.fetch(achievementDescriptor)
            for achievement in achievements {
                modelContext.delete(achievement)
            }

            try modelContext.safeSave(operation: "rebuild database - delete all")

            // Re-initialize data from JSON
            DataService.shared.initializeDataIfNeeded(modelContext: modelContext)

            HapticManager.shared.success()
        } catch {
            print("Error rebuilding database: \(error)")
            HapticManager.shared.warning()
        }
    }

    private func getTotalWords() -> Int {
        let descriptor = FetchDescriptor<Word>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium(.medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(AppTheme.Colors.accent)
                .labelsHidden()
        }
        .padding(AppTheme.Spacing.lg)
        .onChange(of: isOn) { _, _ in
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 24)

            Text(title)
                .font(AppTheme.Typography.bodyMedium(.medium))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .padding(AppTheme.Spacing.lg)
    }
}

// MARK: - How It Works View
struct HowItWorksView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Spaced Repetition Section
                    HelpSection(
                        title: "Spaced Repetition",
                        icon: "brain.head.profile",
                        color: AppTheme.Colors.accent
                    ) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("GREVocab uses spaced repetition to help you remember words long-term. Here's how it works:")
                                .font(AppTheme.Typography.bodyMedium())
                                .foregroundColor(AppTheme.Colors.textSecondary)

                            HelpBullet(
                                number: "1",
                                text: "When you get a word right, you'll see it again later"
                            )
                            HelpBullet(
                                number: "2",
                                text: "Each time you get it right, the gap gets longer"
                            )
                            HelpBullet(
                                number: "3",
                                text: "Words you struggle with appear more often"
                            )
                            HelpBullet(
                                number: "4",
                                text: "After 5 correct recalls, a word is mastered"
                            )
                        }
                    }

                    // Word Status Section
                    HelpSection(
                        title: "Word Status",
                        icon: "chart.bar.fill",
                        color: AppTheme.Colors.success
                    ) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            StatusExplanationRow(
                                status: "New",
                                icon: "sparkles",
                                color: AppTheme.Colors.textTertiary,
                                description: "Words you haven't studied yet"
                            )

                            StatusExplanationRow(
                                status: "Learning",
                                icon: "flame.fill",
                                color: AppTheme.Colors.warning,
                                description: "You've started learning but need more practice (1-4 correct)"
                            )

                            StatusExplanationRow(
                                status: "Mastered",
                                icon: "checkmark.seal.fill",
                                color: AppTheme.Colors.success,
                                description: "You know this word well (5+ correct recalls)"
                            )
                        }
                    }

                    // Study Modes Section
                    HelpSection(
                        title: "Study Modes",
                        icon: "rectangle.stack.fill",
                        color: AppTheme.Colors.tertiary
                    ) {
                        VStack(spacing: AppTheme.Spacing.md) {
                            StudyModeExplanation(
                                title: "Flashcards",
                                icon: "rectangle.portrait.on.rectangle.portrait.fill",
                                description: "Quick review with swipe gestures. Swipe right if you know it, left if you don't."
                            )

                            StudyModeExplanation(
                                title: "Feynman Mode",
                                icon: "lightbulb.fill",
                                description: "Deep learning by explaining words in your own words. Best for truly understanding concepts."
                            )

                            StudyModeExplanation(
                                title: "Active Recall",
                                icon: "questionmark.circle.fill",
                                description: "Quiz yourself with multiple choice and fill-in-the-blank questions."
                            )
                        }
                    }

                    // Tips Section
                    HelpSection(
                        title: "Tips for Success",
                        icon: "star.fill",
                        color: AppTheme.Colors.warning
                    ) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            TipRow(text: "Study a little every day rather than cramming")
                            TipRow(text: "Be honest - only swipe right if you really know it")
                            TipRow(text: "Use Feynman mode for words you keep forgetting")
                            TipRow(text: "Try to use new words in sentences")
                            TipRow(text: "Review due words before learning new ones")
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.md)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle("How It Works")
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
    }
}

// MARK: - Help Section Container
struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(AppTheme.Typography.headlineSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }

            content()
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
        )
    }
}

// MARK: - Help Bullet Point
struct HelpBullet: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(number)
                .font(AppTheme.Typography.labelMedium(.bold))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.15))
                )

            Text(text)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

// MARK: - Status Explanation Row
struct StatusExplanationRow: View {
    let status: String
    let icon: String
    let color: Color
    let description: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(status)
                    .font(AppTheme.Typography.bodyMedium(.semibold))
                    .foregroundColor(color)

                Text(description)
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Study Mode Explanation
struct StudyModeExplanation: View {
    let title: String
    let icon: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.Colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.bodyMedium(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(description)
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.success)

            Text(text)
                .font(AppTheme.Typography.bodySmall())
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}
