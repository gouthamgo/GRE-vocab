import SwiftUI
import SwiftData
import UserNotifications

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var dailyGoal: Double = 20

    // New onboarding state
    @State private var greTestDate: Date = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
    @State private var hasSetTestDate: Bool = false
    @State private var placementScore: Int = 0
    @State private var placementAnswers: [Int] = []
    @State private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var enableNotifications: Bool = true

    private let totalPages = 6

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

                    GREDatePage(
                        testDate: $greTestDate,
                        hasSetDate: $hasSetTestDate
                    )
                    .tag(2)

                    PlacementQuizPage(
                        score: $placementScore,
                        answers: $placementAnswers
                    )
                    .tag(3)

                    PersonalizedGoalPage(
                        dailyGoal: $dailyGoal,
                        testDate: greTestDate,
                        placementScore: placementScore
                    )
                    .tag(4)

                    NotificationPage(
                        enableNotifications: $enableNotifications,
                        notificationTime: $notificationTime,
                        onComplete: completeOnboarding
                    )
                    .tag(5)
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

                    // Navigation buttons (not shown on last page - it has its own button)
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
                                HapticManager.shared.lightImpact()
                            } label: {
                                HStack(spacing: AppTheme.Spacing.xs) {
                                    Text(nextButtonText)
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

    private var nextButtonText: String {
        switch currentPage {
        case 2: return hasSetTestDate ? "Continue" : "Skip Date"
        case 3: return placementAnswers.count >= 5 ? "See Results" : "Next"
        default: return "Next"
        }
    }

    private func completeOnboarding() {
        // Save all onboarding data
        do {
            let userProgress = try DataService.shared.getUserProgress(modelContext: modelContext)

            // Save GRE test date
            if hasSetTestDate {
                userProgress.greTestDate = greTestDate
            }

            // Save placement score
            userProgress.placementScore = placementScore

            // Calculate and save personalized daily goal
            userProgress.dailyGoal = Int(dailyGoal)

            // Save notification preferences
            userProgress.notificationsEnabled = enableNotifications
            userProgress.setNotificationTime(from: notificationTime)

            // Mark enhanced onboarding as completed
            userProgress.hasCompletedEnhancedOnboarding = true

            // Calculate initial estimated score based on placement
            let initialScore = 145 + (placementScore * 2)  // 145-155 based on placement
            userProgress.estimatedVerbalScore = initialScore
            userProgress.previousEstimatedScore = initialScore

            try modelContext.save()

            // Schedule notifications if enabled
            if enableNotifications {
                scheduleNotifications()
            }

        } catch {
            print("Error saving onboarding data: \(error)")
        }

        UserDefaults.standard.set(Int(dailyGoal), forKey: "dailyGoal")
        hasCompletedOnboarding = true
    }

    private func scheduleNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            if granted {
                print("Notifications authorized")
            }
        }
    }
}

// MARK: - Page 1: The Problem
struct ProblemPage: View {
    @State private var animate = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.xxl)

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

                VStack(spacing: AppTheme.Spacing.lg) {
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

// MARK: - Page 3: GRE Test Date
struct GREDatePage: View {
    @Binding var testDate: Date
    @Binding var hasSetDate: Bool
    @State private var animate = false

    private var daysUntilTest: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: testDate).day ?? 0
        return max(0, days)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.xxl)

                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animate ? 1.05 : 1.0)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(AppTheme.Colors.accent)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("When is your GRE?")
                        .font(AppTheme.Typography.headlineLarge(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("We'll create a personalized study plan")
                        .font(AppTheme.Typography.bodyLarge())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                VStack(spacing: AppTheme.Spacing.lg) {
                    DatePicker(
                        "Test Date",
                        selection: $testDate,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(AppTheme.Colors.accent)
                    .onChange(of: testDate) { _, _ in
                        hasSetDate = true
                        HapticManager.shared.selection()
                    }

                    Divider()
                        .background(AppTheme.Colors.surfaceHighlight)

                    if hasSetDate {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(daysUntilTest)")
                                    .font(AppTheme.Typography.displaySmall(.bold))
                                    .foregroundColor(AppTheme.Colors.accent)
                                Text("days to prepare")
                                    .font(AppTheme.Typography.bodySmall())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(testDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(AppTheme.Typography.bodyLarge(.semibold))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Text("Your test date")
                                    .font(AppTheme.Typography.bodySmall())
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .fill(AppTheme.Colors.accent.opacity(0.1))
                        )
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .fill(AppTheme.Colors.surface)
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text("You can change this later in Settings")
                        .font(AppTheme.Typography.bodySmall())
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer().frame(height: 120)
            }
        }
    }
}

// MARK: - Page 4: Placement Quiz
struct PlacementQuizPage: View {
    @Binding var score: Int
    @Binding var answers: [Int]
    @State private var currentQuestion = 0
    @State private var selectedAnswer: Int? = nil
    @State private var showResult = false

    private let questions: [(word: String, definition: String, options: [String], correct: Int)] = [
        ("ubiquitous", "present, appearing, or found everywhere", ["rare", "everywhere", "expensive", "ancient"], 1),
        ("ephemeral", "lasting for a very short time", ["eternal", "brief", "solid", "colorful"], 1),
        ("pragmatic", "dealing with things sensibly and realistically", ["idealistic", "practical", "dramatic", "automatic"], 1),
        ("ameliorate", "make (something bad) better", ["worsen", "improve", "measure", "celebrate"], 1),
        ("taciturn", "reserved or uncommunicative in speech", ["talkative", "quiet", "angry", "happy"], 1)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.lg)

                if currentQuestion < questions.count {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Quick Check")
                            .font(AppTheme.Typography.headlineLarge(.bold))
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Let's see where you're starting from")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    HStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(0..<questions.count, id: \.self) { index in
                            Circle()
                                .fill(questionColor(for: index))
                                .frame(width: 12, height: 12)
                        }
                    }

                    VStack(spacing: AppTheme.Spacing.lg) {
                        Text("\(currentQuestion + 1) of \(questions.count)")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)

                        Text(questions[currentQuestion].word.uppercased())
                            .font(AppTheme.Typography.displaySmall(.bold))
                            .foregroundColor(AppTheme.Colors.accent)

                        Text("means...")
                            .font(AppTheme.Typography.bodyMedium())
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                                Button {
                                    selectAnswer(index)
                                } label: {
                                    HStack {
                                        Text(questions[currentQuestion].options[index])
                                            .font(AppTheme.Typography.bodyLarge(.medium))
                                            .foregroundColor(optionTextColor(for: index))

                                        Spacer()

                                        if selectedAnswer == index {
                                            Image(systemName: showResult ?
                                                  (index == questions[currentQuestion].correct ? "checkmark.circle.fill" : "xmark.circle.fill") :
                                                    "circle.fill")
                                            .foregroundColor(optionIconColor(for: index))
                                        }
                                    }
                                    .padding(AppTheme.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                            .fill(optionBackgroundColor(for: index))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                                    .stroke(optionBorderColor(for: index), lineWidth: selectedAnswer == index ? 2 : 1)
                                            )
                                    )
                                }
                                .disabled(showResult)
                            }
                        }

                        if showResult {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text("Definition:")
                                    .font(AppTheme.Typography.labelSmall(.bold))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                Text(questions[currentQuestion].definition)
                                    .font(AppTheme.Typography.bodyMedium())
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(AppTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                    .fill(AppTheme.Colors.surfaceHighlight)
                            )

                            Button {
                                nextQuestion()
                            } label: {
                                Text("Continue")
                                    .font(AppTheme.Typography.bodyLarge(.semibold))
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppTheme.Spacing.md)
                                    .background(AppTheme.Colors.accent)
                                    .cornerRadius(AppTheme.Radius.md)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                            .fill(AppTheme.Colors.surface)
                    )
                    .padding(.horizontal, AppTheme.Spacing.lg)
                } else {
                    quizResultsView
                }

                Spacer().frame(height: 120)
            }
        }
    }

    private var quizResultsView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.1))
                    .frame(width: 140, height: 140)

                VStack {
                    Text("\(score)")
                        .font(AppTheme.Typography.displayMedium(.bold))
                        .foregroundColor(scoreColor)
                    Text("of 5")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }

            Text(scoreMessage)
                .font(AppTheme.Typography.headlineMedium(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            Text(scoreDescription)
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .padding(AppTheme.Spacing.xl)
    }

    private var scoreColor: Color {
        switch score {
        case 4...5: return AppTheme.Colors.success
        case 2...3: return AppTheme.Colors.warning
        default: return AppTheme.Colors.accent
        }
    }

    private var scoreMessage: String {
        switch score {
        case 5: return "Excellent!"
        case 4: return "Great start!"
        case 3: return "Good foundation!"
        case 2: return "Room to grow!"
        default: return "Let's build together!"
        }
    }

    private var scoreDescription: String {
        switch score {
        case 4...5: return "You have a strong vocabulary base. We'll focus on advanced words."
        case 2...3: return "You know the basics. We'll strengthen your foundation."
        default: return "Perfect starting point! We'll build your vocabulary from essential words."
        }
    }

    private func questionColor(for index: Int) -> Color {
        if index < answers.count {
            return answers[index] == questions[index].correct ? AppTheme.Colors.success : AppTheme.Colors.error
        } else if index == currentQuestion {
            return AppTheme.Colors.accent
        }
        return AppTheme.Colors.surfaceHighlight
    }

    private func optionTextColor(for index: Int) -> Color {
        if showResult {
            if index == questions[currentQuestion].correct { return AppTheme.Colors.success }
            else if index == selectedAnswer { return AppTheme.Colors.error }
        }
        return selectedAnswer == index ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary
    }

    private func optionIconColor(for index: Int) -> Color {
        if showResult {
            return index == questions[currentQuestion].correct ? AppTheme.Colors.success : AppTheme.Colors.error
        }
        return AppTheme.Colors.accent
    }

    private func optionBackgroundColor(for index: Int) -> Color {
        if showResult {
            if index == questions[currentQuestion].correct { return AppTheme.Colors.success.opacity(0.1) }
            else if index == selectedAnswer { return AppTheme.Colors.error.opacity(0.1) }
        }
        return selectedAnswer == index ? AppTheme.Colors.accent.opacity(0.1) : AppTheme.Colors.surfaceElevated
    }

    private func optionBorderColor(for index: Int) -> Color {
        if showResult {
            if index == questions[currentQuestion].correct { return AppTheme.Colors.success }
            else if index == selectedAnswer { return AppTheme.Colors.error }
        }
        return selectedAnswer == index ? AppTheme.Colors.accent : AppTheme.Colors.surfaceHighlight
    }

    private func selectAnswer(_ index: Int) {
        selectedAnswer = index
        HapticManager.shared.lightImpact()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showResult = true
            }
            answers.append(index)
            if index == questions[currentQuestion].correct {
                score += 1
            }
        }
    }

    private func nextQuestion() {
        withAnimation {
            currentQuestion += 1
            selectedAnswer = nil
            showResult = false
        }
        HapticManager.shared.lightImpact()
    }
}

// MARK: - Page 5: Personalized Goal
struct PersonalizedGoalPage: View {
    @Binding var dailyGoal: Double
    let testDate: Date
    let placementScore: Int

    private var daysUntilTest: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: testDate).day ?? 60
        return max(1, days)
    }

    private var recommendedGoal: Int {
        let totalWords = 500
        let wordsPerDay = totalWords / daysUntilTest
        return max(10, min(50, wordsPerDay + 5))
    }

    private var completionDate: Date {
        let wordsToLearn = 500
        let daysNeeded = wordsToLearn / max(1, Int(dailyGoal))
        return Calendar.current.date(byAdding: .day, value: daysNeeded, to: Date()) ?? Date()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer().frame(height: AppTheme.Spacing.lg)

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Your Personal Plan")
                        .font(AppTheme.Typography.headlineLarge(.bold))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Text("Based on your test date and assessment")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                VStack(spacing: AppTheme.Spacing.md) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(AppTheme.Colors.warning)
                        Text("RECOMMENDED FOR YOU")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.warning)
                            .tracking(1)
                    }

                    Text("\(recommendedGoal) words/day")
                        .font(AppTheme.Typography.displaySmall(.bold))
                        .foregroundColor(AppTheme.Colors.accent)

                    Text("to master 500 words by your test date")
                        .font(AppTheme.Typography.bodySmall())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(AppTheme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.warning.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                                .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.lg)

                VStack(spacing: AppTheme.Spacing.lg) {
                    Text("\(Int(dailyGoal))")
                        .font(AppTheme.Typography.displayMedium(.bold))
                        .foregroundColor(AppTheme.Colors.accent)

                    Text("words per day")
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)

                    Slider(value: $dailyGoal, in: 5...50, step: 5)
                        .tint(AppTheme.Colors.accent)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .onChange(of: dailyGoal) { _, _ in
                            HapticManager.shared.selection()
                        }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        GoalPresetButton(goal: 10, label: "Light", currentGoal: $dailyGoal)
                        GoalPresetButton(goal: Double(recommendedGoal), label: "Recommended", currentGoal: $dailyGoal)
                        GoalPresetButton(goal: 35, label: "Intense", currentGoal: $dailyGoal)
                    }

                    Divider()
                        .background(AppTheme.Colors.surfaceHighlight)

                    VStack(spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Text("At this pace, you'll master all words by:")
                                .font(AppTheme.Typography.bodySmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            Spacer()
                        }

                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(AppTheme.Colors.accent)
                            Text(completionDate.formatted(date: .long, time: .omitted))
                                .font(AppTheme.Typography.bodyLarge(.semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()

                            if completionDate <= testDate {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.success)
                                Text("Before test!")
                                    .font(AppTheme.Typography.labelSmall(.bold))
                                    .foregroundColor(AppTheme.Colors.success)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AppTheme.Colors.warning)
                                Text("After test")
                                    .font(AppTheme.Typography.labelSmall(.bold))
                                    .foregroundColor(AppTheme.Colors.warning)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.xl)
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

// MARK: - Page 6: Notification Permission
struct NotificationPage: View {
    @Binding var enableNotifications: Bool
    @Binding var notificationTime: Date
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: enableNotifications ? "bell.badge.fill" : "bell.slash.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(enableNotifications ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
            }

            VStack(spacing: AppTheme.Spacing.md) {
                Text("Stay on Track")
                    .font(AppTheme.Typography.headlineLarge(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Daily reminders help you build a study habit")
                    .font(AppTheme.Typography.bodyLarge())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                Toggle(isOn: $enableNotifications) {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.Colors.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily Reminders")
                                .font(AppTheme.Typography.bodyMedium(.semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("Get notified when it's time to study")
                                .font(AppTheme.Typography.labelSmall())
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                }
                .tint(AppTheme.Colors.accent)
                .onChange(of: enableNotifications) { _, _ in
                    HapticManager.shared.selection()
                }

                if enableNotifications {
                    Divider()
                        .background(AppTheme.Colors.surfaceHighlight)

                    DatePicker(
                        "Reminder Time",
                        selection: $notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                    .tint(AppTheme.Colors.accent)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        TimePresetButton(hour: 7, label: "7 AM", currentTime: $notificationTime)
                        TimePresetButton(hour: 9, label: "9 AM", currentTime: $notificationTime)
                        TimePresetButton(hour: 12, label: "12 PM", currentTime: $notificationTime)
                        TimePresetButton(hour: 20, label: "8 PM", currentTime: $notificationTime)
                    }
                }
            }
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                    .fill(AppTheme.Colors.surface)
            )
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()

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

            Spacer().frame(height: AppTheme.Spacing.xl)
        }
    }
}

struct TimePresetButton: View {
    let hour: Int
    let label: String
    @Binding var currentTime: Date

    private var isSelected: Bool {
        let components = Calendar.current.dateComponents([.hour], from: currentTime)
        return components.hour == hour
    }

    var body: some View {
        Button {
            var components = DateComponents()
            components.hour = hour
            components.minute = 0
            if let date = Calendar.current.date(from: components) {
                currentTime = date
            }
            HapticManager.shared.selection()
        } label: {
            Text(label)
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(isSelected ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surfaceHighlight)
                )
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
            HapticManager.shared.selection()
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
        .modelContainer(for: [Word.self, Deck.self, UserProgress.self], inMemory: true)
}
