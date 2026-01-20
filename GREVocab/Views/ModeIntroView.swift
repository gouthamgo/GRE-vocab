import SwiftUI

/// Intro screen shown before entering a learning mode
/// Explains what the mode is and why it's effective
struct ModeIntroView: View {
    let mode: LearningMode
    let wordCount: Int
    let onStart: () -> Void
    let onDismiss: () -> Void

    @State private var appearAnimation = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum LearningMode {
        case preview
        case quiz
        case deepLearn

        var title: String {
            switch self {
            case .preview: return "Preview Mode"
            case .quiz: return "Quiz Mode"
            case .deepLearn: return "Deep Practice"
            }
        }

        var icon: String {
            switch self {
            case .preview: return "eye.fill"
            case .quiz: return "questionmark.circle.fill"
            case .deepLearn: return "lightbulb.fill"
            }
        }

        var color: Color {
            switch self {
            case .preview: return AppTheme.Colors.accent
            case .quiz: return AppTheme.Colors.tertiary
            case .deepLearn: return AppTheme.Colors.warning
            }
        }

        var tagline: String {
            switch self {
            case .preview: return "See it first, learn it faster"
            case .quiz: return "Prove you know it"
            case .deepLearn: return "Explain it, own it"
            }
        }

        var description: String {
            switch self {
            case .preview:
                return "Quick exposure to new words before you quiz yourself. Seeing words first activates recognition memory."
            case .quiz:
                return "Active recall is the most effective way to memorize. Testing yourself is 43% more effective than just reading."
            case .deepLearn:
                return "The Feynman Technique: If you can explain it simply, you truly understand it. Teach the word to lock it in."
            }
        }

        var steps: [(icon: String, text: String)] {
            switch self {
            case .preview:
                return [
                    ("hand.tap.fill", "Swipe through flashcards"),
                    ("eye.fill", "See word, definition & example"),
                    ("brain.head.profile", "Build familiarity before testing")
                ]
            case .quiz:
                return [
                    ("questionmark.circle.fill", "Answer questions about words"),
                    ("checkmark.circle.fill", "Right answers build mastery"),
                    ("arrow.counterclockwise", "Wrong answers repeat until learned")
                ]
            case .deepLearn:
                return [
                    ("book.fill", "Study the word deeply"),
                    ("text.bubble.fill", "Explain it in your own words"),
                    ("pencil.line", "Create your own example sentence")
                ]
            }
        }

        var scienceFact: String {
            switch self {
            case .preview:
                return "Pre-exposure to material before testing increases retention by 20%"
            case .quiz:
                return "Active recall improves long-term retention by 150% vs passive review"
            case .deepLearn:
                return "Teaching concepts to others increases understanding by 90%"
            }
        }

        var buttonText: String {
            switch self {
            case .preview: return "Start Previewing"
            case .quiz: return "Start Quiz"
            case .deepLearn: return "Start Deep Practice"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with dismiss
                header
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Icon and title
                        modeHeader
                            .padding(.top, AppTheme.Spacing.xl)

                        // Steps
                        stepsSection

                        // Science backing
                        scienceCard

                        Spacer()
                            .frame(height: 120)
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                }

                // Bottom action
                actionButton
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(reduceMotion ? .none : .spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.lightImpact()
                onDismiss()
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

            // Word count badge
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "textformat.abc")
                    .font(.system(size: 12, weight: .semibold))
                Text("\(wordCount) words")
                    .font(AppTheme.Typography.labelMedium(.medium))
            }
            .foregroundColor(AppTheme.Colors.textTertiary)
        }
    }

    // MARK: - Mode Header
    private var modeHeader: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(mode.color.opacity(0.15))
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(mode.color.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)

                Image(systemName: mode.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(mode.color)
            }
            .scaleEffect(appearAnimation ? 1 : 0.5)
            .opacity(appearAnimation ? 1 : 0)

            // Title and tagline
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(mode.title)
                    .font(AppTheme.Typography.displaySmall(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(mode.tagline)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(mode.color)
            }
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 20)

            // Description
            Text(mode.description)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.md)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
        }
    }

    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("HOW IT WORKS")
                .font(AppTheme.Typography.labelSmall(.bold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.5)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(mode.steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: AppTheme.Spacing.md) {
                        // Step number
                        ZStack {
                            Circle()
                                .fill(mode.color.opacity(0.15))
                                .frame(width: 40, height: 40)

                            Image(systemName: step.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(mode.color)
                        }

                        Text(step.text)
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Spacer()
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(AppTheme.Colors.surface)
                    )
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(x: appearAnimation ? 0 : -20)
                    .animation(
                        reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.2),
                        value: appearAnimation
                    )
                }
            }
        }
    }

    // MARK: - Science Card
    private var scienceCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(AppTheme.Colors.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text("Science says")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.secondary)

                Text(mode.scienceFact)
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
                        .stroke(AppTheme.Colors.secondary.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(
            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.5),
            value: appearAnimation
        )
    }

    // MARK: - Action Button
    private var actionButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
            onStart()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(mode.buttonText)
                    .font(AppTheme.Typography.bodyLarge(.bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(AppTheme.Colors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(mode.color)
            )
            .shadow(color: mode.color.opacity(0.4), radius: 20, x: 0, y: 10)
        }
    }
}

#Preview("Preview Mode") {
    ModeIntroView(
        mode: .preview,
        wordCount: 20,
        onStart: {},
        onDismiss: {}
    )
}

#Preview("Quiz Mode") {
    ModeIntroView(
        mode: .quiz,
        wordCount: 15,
        onStart: {},
        onDismiss: {}
    )
}

#Preview("Deep Learn Mode") {
    ModeIntroView(
        mode: .deepLearn,
        wordCount: 5,
        onStart: {},
        onDismiss: {}
    )
}
