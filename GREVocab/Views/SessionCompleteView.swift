import SwiftUI

struct SessionCompleteView: View {
    let correct: Int
    let incorrect: Int
    let wordsMastered: [Word]
    let wordsLeveledUp: Int
    let wordsStartedLearning: Int
    let strugglingWords: [Word]
    let onRestart: () -> Void
    let onDismiss: () -> Void
    let onFeynmanMode: (() -> Void)?
    let onActiveRecall: (() -> Void)?
    let onPreviewMode: (() -> Void)?

    // Learning path recommendation
    let recommendation: LearningRecommendation?

    // NEW: Tomorrow preview data
    let wordsDueTomorrow: Int
    let newWordsTomorrow: Int
    let tomorrowTeaserWords: [String]  // Sample word names for teaser
    let currentStreak: Int
    let scoreChange: Int  // Positive or negative score change
    let estimatedScore: Int
    let notificationTime: String?  // e.g., "9:00 AM"
    let onShareProgress: (() -> Void)?

    @State private var appearAnimation = false
    @State private var confettiTrigger = false
    @State private var showProgressDetails = false
    @State private var showShareSheet = false

    // Convenience initializer for backwards compatibility
    init(
        correct: Int,
        incorrect: Int,
        onRestart: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.correct = correct
        self.incorrect = incorrect
        self.wordsMastered = []
        self.wordsLeveledUp = 0
        self.wordsStartedLearning = 0
        self.strugglingWords = []
        self.onRestart = onRestart
        self.onDismiss = onDismiss
        self.onFeynmanMode = nil
        self.onActiveRecall = nil
        self.onPreviewMode = nil
        self.recommendation = nil
        // Tomorrow preview defaults
        self.wordsDueTomorrow = 0
        self.newWordsTomorrow = 0
        self.tomorrowTeaserWords = []
        self.currentStreak = 0
        self.scoreChange = 0
        self.estimatedScore = 145
        self.notificationTime = nil
        self.onShareProgress = nil
    }

    // Full initializer with all session data
    init(
        correct: Int,
        incorrect: Int,
        wordsMastered: [Word],
        wordsLeveledUp: Int,
        wordsStartedLearning: Int,
        strugglingWords: [Word],
        onRestart: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onFeynmanMode: (() -> Void)? = nil,
        onActiveRecall: (() -> Void)? = nil,
        onPreviewMode: (() -> Void)? = nil,
        recommendation: LearningRecommendation? = nil,
        wordsDueTomorrow: Int = 0,
        newWordsTomorrow: Int = 0,
        tomorrowTeaserWords: [String] = [],
        currentStreak: Int = 0,
        scoreChange: Int = 0,
        estimatedScore: Int = 145,
        notificationTime: String? = nil,
        onShareProgress: (() -> Void)? = nil
    ) {
        self.correct = correct
        self.incorrect = incorrect
        self.wordsMastered = wordsMastered
        self.wordsLeveledUp = wordsLeveledUp
        self.wordsStartedLearning = wordsStartedLearning
        self.strugglingWords = strugglingWords
        self.onRestart = onRestart
        self.onDismiss = onDismiss
        self.onFeynmanMode = onFeynmanMode
        self.onActiveRecall = onActiveRecall
        self.onPreviewMode = onPreviewMode
        self.recommendation = recommendation
        self.wordsDueTomorrow = wordsDueTomorrow
        self.newWordsTomorrow = newWordsTomorrow
        self.tomorrowTeaserWords = tomorrowTeaserWords
        self.currentStreak = currentStreak
        self.scoreChange = scoreChange
        self.estimatedScore = estimatedScore
        self.notificationTime = notificationTime
        self.onShareProgress = onShareProgress
    }

    var total: Int { correct + incorrect }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }

    var grade: (text: String, color: Color, icon: String) {
        switch accuracy {
        case 90...100: return ("Excellent!", AppTheme.Colors.success, "star.fill")
        case 70..<90: return ("Great Job!", AppTheme.Colors.tertiary, "hand.thumbsup.fill")
        case 50..<70: return ("Keep Going!", AppTheme.Colors.warning, "flame.fill")
        default: return ("Keep Practicing", AppTheme.Colors.error, "arrow.clockwise")
        }
    }

    private var isDeepLearnRecommendation: Bool {
        guard let rec = recommendation else { return false }
        if case .deepLearn = rec { return true }
        return false
    }

    private var isQuizRecommendation: Bool {
        guard let rec = recommendation else { return false }
        if case .quiz = rec { return true }
        return false
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
                        .frame(width: CGFloat(160 + index * 40), height: CGFloat(160 + index * 40))
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
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(grade.color.opacity(0.5), lineWidth: 3)
                    )
                    .scaleEffect(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.5), value: appearAnimation)

                // Icon
                Image(systemName: grade.icon)
                    .font(.system(size: 56, weight: .bold))
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

            Text("Session Complete")
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.top, AppTheme.Spacing.xxs)
                .opacity(appearAnimation ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: appearAnimation)

            // Progress Summary (Level-ups, Mastered, etc.)
            progressSummarySection
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.lg)
                .opacity(appearAnimation ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.4), value: appearAnimation)

            // Stats cards
            HStack(spacing: AppTheme.Spacing.md) {
                SessionStatCard(
                    value: "\(correct)",
                    label: "Correct",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.Colors.success
                )
                .opacity(appearAnimation ? 1 : 0)
                .offset(x: appearAnimation ? 0 : -20)
                .animation(.spring(response: 0.6).delay(0.5), value: appearAnimation)

                SessionStatCard(
                    value: "\(incorrect)",
                    label: "Incorrect",
                    icon: "xmark.circle.fill",
                    color: AppTheme.Colors.error
                )
                .opacity(appearAnimation ? 1 : 0)
                .offset(x: appearAnimation ? 0 : 20)
                .animation(.spring(response: 0.6).delay(0.6), value: appearAnimation)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.md)

            // Smart Suggestions
            if !strugglingWords.isEmpty || accuracy >= 70 {
                smartSuggestionsSection
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.lg)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.7), value: appearAnimation)
            }

            // Streak celebration & Score change
            if currentStreak > 0 || scoreChange != 0 {
                streakAndScoreSection
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.lg)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.75), value: appearAnimation)
            }

            // Tomorrow Preview
            if wordsDueTomorrow > 0 || newWordsTomorrow > 0 {
                tomorrowPreviewSection
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.lg)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.8), value: appearAnimation)
            }

            Spacer()

            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton("Study Again", icon: "arrow.counterclockwise", isLarge: true) {
                    onRestart()
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    // Share Progress Button
                    if onShareProgress != nil {
                        Button {
                            onShareProgress?()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Share")
                                    .font(AppTheme.Typography.bodyMedium(.semibold))
                            }
                            .foregroundColor(AppTheme.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                    .stroke(AppTheme.Colors.accent, lineWidth: 1.5)
                            )
                        }
                    }

                    SecondaryButton("Done", icon: "checkmark") {
                        onDismiss()
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xxl)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 30)
            .animation(.spring(response: 0.6).delay(0.85), value: appearAnimation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
        .overlay(
            ConfettiView(trigger: confettiTrigger, color: grade.color)
        )
        .onAppear {
            withAnimation {
                appearAnimation = true
            }

            // Trigger confetti for good scores
            if accuracy >= 70 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    confettiTrigger = true
                }
            }
        }
    }
}

// MARK: - Progress Summary Section
extension SessionCompleteView {
    @ViewBuilder
    var progressSummarySection: some View {
        let hasProgress = !wordsMastered.isEmpty || wordsLeveledUp > 0 || wordsStartedLearning > 0

        if hasProgress {
            VStack(spacing: AppTheme.Spacing.sm) {
                // Mastered words
                if !wordsMastered.isEmpty {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.Colors.success)

                        Text("\(wordsMastered.count) word\(wordsMastered.count == 1 ? "" : "s") mastered!")
                            .font(AppTheme.Typography.bodyMedium(.semibold))
                            .foregroundColor(AppTheme.Colors.success)

                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.success.opacity(0.15))
                    )
                }

                // Leveled up words
                if wordsLeveledUp > 0 {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.Colors.tertiary)

                        Text("\(wordsLeveledUp) word\(wordsLeveledUp == 1 ? "" : "s") leveled up")
                            .font(AppTheme.Typography.bodyMedium(.medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }

                // Started learning
                if wordsStartedLearning > 0 {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.Colors.warning)

                        Text("\(wordsStartedLearning) new word\(wordsStartedLearning == 1 ? "" : "s") started")
                            .font(AppTheme.Typography.bodyMedium(.medium))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }
            }
        }
    }

    @ViewBuilder
    var smartSuggestionsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Text("NEXT STEPS")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Learning path recommendation (primary)
            if let rec = recommendation {
                nextStepButton(for: rec)
            }

            // Feynman Mode suggestion for struggling words (if not already recommended)
            if !strugglingWords.isEmpty,
               let onFeynman = onFeynmanMode,
               !isDeepLearnRecommendation {
                Button {
                    onFeynman()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.Colors.warning)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Try Feynman Mode")
                                .font(AppTheme.Typography.bodyMedium(.semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("\(strugglingWords.count) word\(strugglingWords.count == 1 ? " needs" : "s need") deeper practice")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.warning)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.warning.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                    .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Active Recall suggestion for good performance (if not already recommended)
            if accuracy >= 70,
               let onRecall = onActiveRecall,
               !isQuizRecommendation {
                Button {
                    onRecall()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.Colors.tertiary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Try Active Recall")
                                .font(AppTheme.Typography.bodyMedium(.semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text("Test your knowledge with quizzes")
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
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }
            }
        }
    }

    // MARK: - Streak & Score Section
    @ViewBuilder
    var streakAndScoreSection: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Streak celebration
            if currentStreak > 0 {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.Colors.warning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(currentStreak) Day Streak!")
                            .font(AppTheme.Typography.bodyMedium(.bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if currentStreak >= 7 {
                            Text("On fire!")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.warning)
                        }
                    }
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.warning.opacity(0.1))
                )
            }

            // Score change indicator
            if scoreChange != 0 {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: scoreChange > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(scoreChange > 0 ? AppTheme.Colors.success : AppTheme.Colors.error)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(scoreChange > 0 ? "+\(scoreChange)" : "\(scoreChange)")
                                .font(AppTheme.Typography.bodyMedium(.bold))
                                .foregroundColor(scoreChange > 0 ? AppTheme.Colors.success : AppTheme.Colors.error)

                            Text("pts")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Text("Est. \(estimatedScore)")
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(scoreChange > 0 ? AppTheme.Colors.success.opacity(0.1) : AppTheme.Colors.error.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Tomorrow Preview Section
    @ViewBuilder
    var tomorrowPreviewSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Section header
            HStack {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accent)

                Text("TOMORROW'S PREVIEW")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)

                Spacer()
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                // Words due for review
                if wordsDueTomorrow > 0 {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.tertiary)
                            .frame(width: 24)

                        Text("\(wordsDueTomorrow) word\(wordsDueTomorrow == 1 ? "" : "s") due for review")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()
                    }
                }

                // New words coming
                if newWordsTomorrow > 0 {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.success)
                            .frame(width: 24)

                        Text("\(newWordsTomorrow) new word\(newWordsTomorrow == 1 ? "" : "s") to learn")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()
                    }
                }

                // Teaser words
                if !tomorrowTeaserWords.isEmpty {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.warning)
                            .frame(width: 24)

                        Text(teaserText)
                            .font(AppTheme.Typography.bodyMedium(.medium))
                            .foregroundColor(AppTheme.Colors.accent)
                            .italic()

                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surface)
            )

            // Notification reminder
            if let time = notificationTime {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.accent)

                    Text("We'll remind you at \(time)")
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
            }
        }
    }

    private var teaserText: String {
        if tomorrowTeaserWords.count == 1 {
            return "\"\(tomorrowTeaserWords[0])\" comes back!"
        } else if tomorrowTeaserWords.count == 2 {
            return "\"\(tomorrowTeaserWords[0])\" & \"\(tomorrowTeaserWords[1])\" return!"
        } else {
            return "\"\(tomorrowTeaserWords[0])\" and more return!"
        }
    }

    @ViewBuilder
    private func nextStepButton(for rec: LearningRecommendation) -> some View {
        let (icon, title, subtitle, color, action): (String, String, String, Color, (() -> Void)?) = {
            switch rec {
            case .preview(let count, _):
                return ("eye.fill", "Preview New Words", "\(count) new words to learn", AppTheme.Colors.accent, onPreviewMode)
            case .quiz(let count, _):
                return ("questionmark.circle.fill", "Quiz Yourself", "\(count) words ready to test", AppTheme.Colors.tertiary, onActiveRecall)
            case .deepLearn(let count, _):
                return ("lightbulb.fill", "Deep Practice", "\(count) words need attention", AppTheme.Colors.warning, onFeynmanMode)
            case .allCaughtUp:
                return ("checkmark.seal.fill", "All Caught Up!", "Review to maintain mastery", AppTheme.Colors.success, onActiveRecall)
            }
        }()

        if let action = action {
            Button {
                action()
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Text("RECOMMENDED")
                                .font(AppTheme.Typography.labelSmall(.bold))
                                .foregroundColor(color)
                                .tracking(0.5)
                        }

                        Text(title)
                            .font(AppTheme.Typography.bodyMedium(.semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text(subtitle)
                            .font(AppTheme.Typography.labelSmall())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(color.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                .stroke(color.opacity(0.3), lineWidth: 1.5)
                        )
                )
            }
        }
    }
}

// MARK: - Session Stat Card
struct SessionStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)

            Text(value)
                .font(AppTheme.Typography.displaySmall(.black))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(label)
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    let trigger: Bool
    let color: Color

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    createConfetti(in: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createConfetti(in size: CGSize) {
        let colors: [Color] = [color, AppTheme.Colors.secondary, AppTheme.Colors.tertiary, AppTheme.Colors.warning]

        for _ in 0..<50 {
            let particle = ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: size.height / 3),
                velocity: CGPoint(
                    x: CGFloat.random(in: -200...200),
                    y: CGFloat.random(in: -400...(-100))
                ),
                size: CGFloat.random(in: 4...10),
                color: colors.randomElement()!,
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Animate particles
        animateParticles(in: size)
    }

    private func animateParticles(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            for i in particles.indices.reversed() {
                particles[i].velocity.y += 15 // gravity
                particles[i].position.x += particles[i].velocity.x * 0.016
                particles[i].position.y += particles[i].velocity.y * 0.016
                particles[i].opacity -= 0.015

                if particles[i].opacity <= 0 || particles[i].position.y > size.height {
                    particles.remove(at: i)
                }
            }

            if particles.isEmpty {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
}

#Preview("Basic") {
    SessionCompleteView(
        correct: 15,
        incorrect: 5,
        onRestart: {},
        onDismiss: {}
    )
}

#Preview("Full Features") {
    SessionCompleteView(
        correct: 18,
        incorrect: 2,
        wordsMastered: [],
        wordsLeveledUp: 5,
        wordsStartedLearning: 3,
        strugglingWords: [],
        onRestart: {},
        onDismiss: {},
        wordsDueTomorrow: 12,
        newWordsTomorrow: 5,
        tomorrowTeaserWords: ["ubiquitous", "ephemeral"],
        currentStreak: 7,
        scoreChange: 2,
        estimatedScore: 158,
        notificationTime: "9:00 AM",
        onShareProgress: {}
    )
}