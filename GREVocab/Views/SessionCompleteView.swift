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

    @State private var appearAnimation = false
    @State private var confettiTrigger = false
    @State private var showProgressDetails = false

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
        recommendation: LearningRecommendation? = nil
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

            Spacer()

            // Buttons
            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton("Study Again", icon: "arrow.counterclockwise", isLarge: true) {
                    onRestart()
                }

                SecondaryButton("Done", icon: "checkmark") {
                    onDismiss()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xxl)
            .opacity(appearAnimation ? 1 : 0)
            .offset(y: appearAnimation ? 0 : 30)
            .animation(.spring(response: 0.6).delay(0.8), value: appearAnimation)
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

#Preview {
    SessionCompleteView(
        correct: 15,
        incorrect: 5,
        onRestart: {},
        onDismiss: {}
    )
}