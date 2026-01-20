import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dailyGoal: Double = 20

    private let totalPages = 4

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ProblemPage()
                        .tag(0)

                    SolutionPage()
                        .tag(1)

                    LearningPathPage()
                        .tag(2)

                    GoalSettingPage(dailyGoal: $dailyGoal, onComplete: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Bottom navigation
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Page indicators
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? AppTheme.Colors.accent : AppTheme.Colors.surfaceHighlight)
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Navigation buttons
                    if currentPage < totalPages - 1 {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Button {
                                completeOnboarding()
                            } label: {
                                Text("Skip")
                                    .font(AppTheme.Typography.bodyMedium(.medium))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    currentPage += 1
                                }
                            } label: {
                                HStack(spacing: AppTheme.Spacing.xs) {
                                    Text("Next")
                                        .font(AppTheme.Typography.bodyLarge(.semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(.horizontal, AppTheme.Spacing.xl)
                                .padding(.vertical, AppTheme.Spacing.md)
                                .background(AppTheme.Colors.accent)
                                .cornerRadius(AppTheme.Radius.lg)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.xl)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(Int(dailyGoal), forKey: "dailyGoal")
        hasCompletedOnboarding = true
    }
}

// MARK: - Page 1: The Problem
struct ProblemPage: View {
    @State private var animate = false
    @State private var showExample = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.xxl)

                // Confused icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.error.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animate ? 1.05 : 1.0)

                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 70, weight: .light))
                        .foregroundColor(AppTheme.Colors.error.opacity(0.8))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Sound Familiar?")
                        .font(AppTheme.Typography.headlineLarge(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("\"I studied 500 flashcards...\nbut froze on the test\"")
                        .font(AppTheme.Typography.bodyLarge())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .italic()
                }

                // The explanation
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.Colors.warning)

                        Text("The Problem")
                            .font(AppTheme.Typography.headlineSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }

                    Text("Swiping flashcards trains recognition—you see a word and think \"I know that!\"")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Text("But the GRE doesn't show you words. It shows you blanks.")
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    // Visual example
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("GRE Question:")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)

                        Text("The technology became so _______ that people stopped noticing it.")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(AppTheme.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                    .fill(AppTheme.Colors.surfaceElevated)
                            )

                        HStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(["ubiquitous", "pervasive", "endemic", "rampant"], id: \.self) { word in
                                Text(word)
                                    .font(AppTheme.Typography.labelSmall())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                            .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .fill(AppTheme.Colors.surface)
                    )

                    Text("Recognizing \"ubiquitous\" on a flashcard doesn't mean you can pick it from similar words in context.")
                        .font(AppTheme.Typography.bodySmall())
                        .foregroundColor(AppTheme.Colors.error)
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(AppTheme.Colors.surface)
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer().frame(height: 120)
            }
        }
    }
}

// MARK: - Page 2: The Solution
struct SolutionPage: View {
    @State private var animate = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.xxl)

                // Success icon
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.success.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animate ? 1.05 : 1.0)

                    Image(systemName: "target")
                        .font(.system(size: 70, weight: .light))
                        .foregroundColor(AppTheme.Colors.success)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("We Train for Blanks")
                        .font(AppTheme.Typography.headlineLarge(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Not flashcards")
                        .font(AppTheme.Typography.bodyLarge())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                // Comparison
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Old way
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.error)
                            Text("Most apps")
                                .font(AppTheme.Typography.labelMedium(.bold))
                                .foregroundColor(AppTheme.Colors.error)
                        }

                        HStack(spacing: AppTheme.Spacing.md) {
                            Text("Ubiquitous")
                                .font(AppTheme.Typography.bodyLarge(.semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Image(systemName: "arrow.right")
                                .foregroundColor(AppTheme.Colors.textTertiary)

                            HStack(spacing: AppTheme.Spacing.sm) {
                                Text("Know")
                                    .font(AppTheme.Typography.labelSmall())
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(AppTheme.Colors.success.opacity(0.2))
                                    .cornerRadius(AppTheme.Radius.sm)

                                Text("Don't")
                                    .font(AppTheme.Typography.labelSmall())
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .background(AppTheme.Colors.error.opacity(0.2))
                                    .cornerRadius(AppTheme.Radius.sm)
                            }
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.error.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .stroke(AppTheme.Colors.error.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    Image(systemName: "arrow.down")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.Colors.accent)

                    // New way
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.success)
                            Text("GREVocab")
                                .font(AppTheme.Typography.labelMedium(.bold))
                                .foregroundColor(AppTheme.Colors.success)
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("The _______ nature of smartphones means everyone has one.")
                                .font(AppTheme.Typography.bodyMedium())
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            HStack(spacing: AppTheme.Spacing.sm) {
                                ForEach(["ubiquitous", "bespoke", "esoteric", "transient"], id: \.self) { word in
                                    Text(word)
                                        .font(AppTheme.Typography.labelSmall())
                                        .foregroundColor(word == "ubiquitous" ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                                        .padding(.horizontal, AppTheme.Spacing.sm)
                                        .padding(.vertical, AppTheme.Spacing.xs)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                                .fill(word == "ubiquitous" ? AppTheme.Colors.success.opacity(0.2) : AppTheme.Colors.surface)
                                        )
                                }
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.success.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                        .stroke(AppTheme.Colors.success.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(AppTheme.Colors.surface)
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                // Key point
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppTheme.Colors.warning)
                    Text("This is how the GRE actually tests you")
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.warning.opacity(0.1))
                )

                Spacer().frame(height: 120)
            }
        }
    }
}

// MARK: - Page 3: The Learning Path
struct LearningPathPage: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.xxl)

                Text("Your Learning Path")
                    .font(AppTheme.Typography.headlineLarge(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Three steps to truly learn each word")
                    .font(AppTheme.Typography.bodyLarge())
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // Learning path visualization
                VStack(spacing: 0) {
                    LearningPathStep(
                        number: 1,
                        title: "Preview",
                        subtitle: "Optional",
                        description: "Quick look at new words",
                        detail: "See definitions before quizzing",
                        icon: "eye.fill",
                        color: AppTheme.Colors.accent,
                        isOptional: true
                    )

                    PathConnector()

                    LearningPathStep(
                        number: 2,
                        title: "Quiz",
                        subtitle: "Required",
                        description: "Prove you know it",
                        detail: "Answer questions to test recall",
                        icon: "questionmark.circle.fill",
                        color: AppTheme.Colors.tertiary,
                        isOptional: false
                    )

                    PathConnector()

                    LearningPathStep(
                        number: 3,
                        title: "Deep Learn",
                        subtitle: "Required",
                        description: "Lock it in forever",
                        detail: "Explain it in your own words",
                        icon: "lightbulb.fill",
                        color: AppTheme.Colors.warning,
                        isOptional: false
                    )
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(AppTheme.Colors.surface)
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                // Key message
                VStack(spacing: AppTheme.Spacing.sm) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(AppTheme.Colors.success)
                        Text("Mastery Requirement")
                            .font(AppTheme.Typography.labelMedium(.bold))
                            .foregroundColor(AppTheme.Colors.success)
                    }

                    Text("Words are only \"Mastered\" after completing Quiz + Deep Learn with spaced repetition over time")
                        .font(AppTheme.Typography.bodySmall())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.success.opacity(0.1))
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer().frame(height: 120)
            }
        }
    }
}

struct LearningPathStep: View {
    let number: Int
    let title: String
    let subtitle: String
    let description: String
    let detail: String
    let icon: String
    let color: Color
    let isOptional: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Number circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(title)
                        .font(AppTheme.Typography.bodyLarge(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text(subtitle)
                        .font(AppTheme.Typography.labelSmall())
                        .foregroundColor(isOptional ? AppTheme.Colors.textTertiary : color)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isOptional ? AppTheme.Colors.surfaceHighlight : color.opacity(0.15))
                        )
                }

                Text(description)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(color)

                Text(detail)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.sm)
    }
}

struct PathConnector: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(AppTheme.Colors.surfaceHighlight)
                .frame(width: 2, height: 24)
                .padding(.leading, 27)

            Spacer()
        }
    }
}

// MARK: - Page 4: Goal Setting
struct GoalSettingPage: View {
    @Binding var dailyGoal: Double
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            // Goal icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "flame.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppTheme.Colors.accent)
            }

            Text("Set Your Daily Goal")
                .font(AppTheme.Typography.headlineLarge(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("How many words do you want to learn each day?")
                .font(AppTheme.Typography.bodyLarge())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Goal display
            VStack(spacing: AppTheme.Spacing.md) {
                Text("\(Int(dailyGoal))")
                    .font(AppTheme.Typography.displayMedium(.bold))
                    .foregroundColor(AppTheme.Colors.accent)

                Text("words per day")
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textSecondary)

                // Slider
                Slider(value: $dailyGoal, in: 5...50, step: 5)
                    .tint(AppTheme.Colors.accent)
                    .padding(.horizontal, AppTheme.Spacing.xl)

                // Preset buttons
                HStack(spacing: AppTheme.Spacing.sm) {
                    GoalPresetButton(goal: 10, label: "Light", currentGoal: $dailyGoal)
                    GoalPresetButton(goal: 20, label: "Regular", currentGoal: $dailyGoal)
                    GoalPresetButton(goal: 35, label: "Intense", currentGoal: $dailyGoal)
                }
            }
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(AppTheme.Colors.surface)
            )
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()

            // Get Started button
            Button(action: onComplete) {
                HStack {
                    Text("Start Learning")
                        .font(AppTheme.Typography.bodyLarge(.bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(AppTheme.Colors.accent)
                .cornerRadius(AppTheme.Radius.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()
        }
    }
}

struct GoalPresetButton: View {
    let goal: Double
    let label: String
    @Binding var currentGoal: Double

    var isSelected: Bool {
        currentGoal == goal
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                currentGoal = goal
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(Int(goal))")
                    .font(AppTheme.Typography.bodyLarge(.bold))
                Text(label)
                    .font(AppTheme.Typography.labelSmall())
            }
            .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surfaceHighlight)
            )
        }
    }
}

#Preview {
    OnboardingView()
}
