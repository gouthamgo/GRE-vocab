import SwiftUI
import SwiftData

/// Simplified deep learning moment for Daily Session
/// Multiple choice: pick the best explanation for a struggling word
struct DeepMomentView: View {
    let question: DeepMomentQuestion
    @Binding var selectedOption: DeepMomentQuestion.DeepMomentOption?
    @Binding var showingAnswer: Bool
    @Binding var answerCorrect: Bool
    let onSubmit: () -> Void
    let onSkip: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Phase header
            phaseHeader

            // Instruction
            Text("This word needs extra attention")
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Word card
                    wordCard

                    // Question prompt
                    Text(question.prompt)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)

                    // Options
                    if !showingAnswer {
                        optionsList
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
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14, weight: .bold))
            Text("DEEP MOMENT")
                .font(AppTheme.Typography.labelSmall(.bold))
                .tracking(1.5)
        }
        .foregroundColor(AppTheme.Colors.warning)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.Colors.warning.opacity(0.15))
        )
    }

    // MARK: - Word Card
    private var wordCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Term
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(question.word.term)
                    .font(AppTheme.Typography.displaySmall(.black))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Button {
                    TextToSpeechService.shared.speak(text: question.word.term)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.Colors.warning)
                        .padding(6)
                        .background(Circle().fill(AppTheme.Colors.warning.opacity(0.1)))
                }
            }

            // Part of speech
            Text(question.word.partOfSpeech)
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(question.word.difficulty.themeColor)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(
                    Capsule()
                        .fill(question.word.difficulty.themeColor.opacity(0.15))
                )

            // Struggling indicator
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                Text("Needs review")
                    .font(AppTheme.Typography.labelSmall(.medium))
            }
            .foregroundColor(AppTheme.Colors.warning)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(AppTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Options List
    private var optionsList: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(question.options) { option in
                optionButton(option: option)
            }
        }
    }

    private func optionButton(option: DeepMomentQuestion.DeepMomentOption) -> some View {
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
                          AppTheme.Colors.warning : AppTheme.Colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(selectedOption?.id == option.id ?
                            AppTheme.Colors.warning : AppTheme.Colors.surfaceHighlight, lineWidth: 1)
            )
        }
    }

    // MARK: - Answer Feedback
    private var answerFeedback: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Result banner
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: answerCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(answerCorrect ? "Excellent!" : "Not quite")
                        .font(AppTheme.Typography.labelLarge(.bold))
                    Text(answerCorrect ?
                         "You understand this word well." :
                         "Review the correct explanation.")
                        .font(AppTheme.Typography.labelSmall())
                }
                Spacer()
            }
            .foregroundColor(answerCorrect ? AppTheme.Colors.success : AppTheme.Colors.error)
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill((answerCorrect ? AppTheme.Colors.success : AppTheme.Colors.error).opacity(0.15))
            )

            // Correct explanation
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("BEST EXPLANATION")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)

                Text(question.correctExplanation)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surfaceElevated)
            )

            // Example sentence
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("EXAMPLE")
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1)

                Text(question.word.exampleSentence)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .italic()
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

                PrimaryButton("Check", icon: "checkmark.circle", color: AppTheme.Colors.warning) {
                    onSubmit()
                }
                .disabled(selectedOption == nil)
            } else {
                PrimaryButton("Continue", icon: "arrow.right", color: AppTheme.Colors.warning) {
                    onFinish()
                }
            }
        }
        .padding(.bottom, AppTheme.Spacing.md)
    }
}
