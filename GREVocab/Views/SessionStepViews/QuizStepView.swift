import SwiftUI
import SwiftData

/// Single quiz question component for Daily Session
struct QuizStepView: View {
    let question: ActiveRecallQuestion
    @Binding var selectedOption: ActiveRecallQuestion.QuestionOption?
    @Binding var userTextInput: String
    @Binding var showingAnswer: Bool
    @Binding var answerResult: AnswerResult?
    let currentIndex: Int
    let totalCount: Int
    let onSubmit: () -> Void
    let onSkip: () -> Void
    let onProceed: (Bool) -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Phase header
            phaseHeader

            // Question counter
            Text("Question \(currentIndex + 1) of \(totalCount)")
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)

            // Question card
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    questionContent

                    if !showingAnswer {
                        answerInput
                    } else {
                        answerFeedback
                    }
                }
            }

            Spacer()

            // Action buttons
            actionButtons
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    // MARK: - Phase Header
    private var phaseHeader: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 14, weight: .bold))
            Text("QUIZ")
                .font(AppTheme.Typography.labelSmall(.bold))
                .tracking(1.5)
        }
        .foregroundColor(AppTheme.Colors.tertiary)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.Colors.tertiary.opacity(0.15))
        )
    }

    // MARK: - Question Content
    private var questionContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Question type badge
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: question.type.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(question.type.rawValue)
                    .font(AppTheme.Typography.labelSmall(.semibold))
            }
            .foregroundColor(question.type.color)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(
                Capsule()
                    .fill(question.type.color.opacity(0.15))
            )

            // Word display (for most question types)
            if question.type != .wordFromDefinition {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(question.word.term)
                        .font(AppTheme.Typography.displaySmall(.black))
                        .foregroundColor(AppTheme.Colors.textPrimary)

                    Button {
                        TextToSpeechService.shared.speak(text: question.word.term)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.Colors.accent)
                            .padding(6)
                            .background(Circle().fill(AppTheme.Colors.accent.opacity(0.1)))
                    }
                }

                Text(question.word.partOfSpeech)
                    .font(AppTheme.Typography.labelSmall(.medium))
                    .foregroundColor(question.word.difficulty.themeColor)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xxs)
                    .background(
                        Capsule()
                            .fill(question.word.difficulty.themeColor.opacity(0.15))
                    )
            }

            // Question prompt
            Text(question.prompt)
                .font(question.type == .wordFromDefinition ?
                      AppTheme.Typography.headlineSmall(.medium) :
                      AppTheme.Typography.bodyMedium())
                .foregroundColor(question.type == .wordFromDefinition ?
                                 AppTheme.Colors.textPrimary :
                                 AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.sm)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(question.type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Answer Input
    @ViewBuilder
    private var answerInput: some View {
        if question.type == .definitionRecall {
            // Text input
            TextField("Type your answer...", text: $userTextInput, axis: .vertical)
                .textFieldStyle(AppTheme.CustomTextFieldStyle())
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(2...4)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } else if let options = question.options {
            // Multiple choice
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(options) { option in
                    optionButton(option: option)
                }
            }
        }
    }

    private func optionButton(option: ActiveRecallQuestion.QuestionOption) -> some View {
        Button {
            HapticManager.shared.lightImpact()
            selectedOption = option
        } label: {
            HStack {
                Text(option.text)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(selectedOption?.id == option.id ?
                                     .white : AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if selectedOption?.id == option.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(selectedOption?.id == option.id ?
                          question.type.color : AppTheme.Colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(selectedOption?.id == option.id ?
                            question.type.color : AppTheme.Colors.surfaceHighlight, lineWidth: 1)
            )
        }
    }

    // MARK: - Answer Feedback
    private var answerFeedback: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Result banner
            if let result = answerResult {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.isCorrect ? "Correct!" : "Incorrect")
                            .font(AppTheme.Typography.labelLarge(.bold))
                        Text(result.feedback)
                            .font(AppTheme.Typography.labelSmall())
                    }
                    Spacer()
                }
                .foregroundColor(result.isCorrect ? AppTheme.Colors.success : AppTheme.Colors.error)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill((result.isCorrect ? AppTheme.Colors.success : AppTheme.Colors.error).opacity(0.15))
                )
            }

            // Correct answer
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("CORRECT ANSWER")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)

                Text(question.correctAnswer)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surfaceElevated)
            )
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            if !showingAnswer {
                SecondaryButton("Skip", icon: "forward.fill") {
                    onSkip()
                }

                if question.type == .definitionRecall {
                    PrimaryButton("Check", icon: "checkmark.circle") {
                        onSubmit()
                    }
                    .disabled(userTextInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    PrimaryButton("Submit", icon: "checkmark.circle") {
                        onSubmit()
                    }
                    .disabled(selectedOption == nil)
                }
            } else {
                SecondaryButton("Still Learning", icon: "arrow.counterclockwise") {
                    onProceed(false)
                }
                PrimaryButton("Got It!", icon: "arrow.right") {
                    onProceed(answerResult?.isCorrect ?? false)
                }
            }
        }
        .padding(.bottom, AppTheme.Spacing.md)
    }
}
