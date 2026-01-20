import SwiftUI
import SwiftData

/// Lightweight word preview card for Daily Session
/// Tap to flip, swipe when ready to move on
struct PreviewStepView: View {
    let word: Word
    @Binding var isFlipped: Bool
    let onNext: () -> Void
    let onPrevious: (() -> Void)?
    let currentIndex: Int
    let totalCount: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Phase header
            phaseHeader

            // Card counter
            Text("\(currentIndex + 1) of \(totalCount)")
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(AppTheme.Colors.textTertiary)

            Spacer()

            // Flip instruction
            if !isFlipped {
                Text("Tap card to see definition")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            // The card
            ZStack {
                // Front (term)
                cardFront
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                // Back (definition)
                cardBack
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(height: 340)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
                HapticManager.shared.lightImpact()
            }

            Spacer()

            // Navigation
            navigationButtons
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    // MARK: - Phase Header
    private var phaseHeader: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "eye.fill")
                .font(.system(size: 14, weight: .bold))
            Text("NEW WORDS")
                .font(AppTheme.Typography.labelSmall(.bold))
                .tracking(1.5)
        }
        .foregroundColor(AppTheme.Colors.accent)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.Colors.accent.opacity(0.15))
        )
    }

    // MARK: - Card Front
    private var cardFront: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            // Term
            Text(word.term)
                .font(AppTheme.Typography.displayMedium(.black))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            // Part of speech
            Text(word.partOfSpeech)
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(word.difficulty.themeColor)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(word.difficulty.themeColor.opacity(0.15)))

            // Pronunciation button
            Button {
                TextToSpeechService.shared.speak(text: word.term)
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Listen")
                }
                .font(AppTheme.Typography.labelMedium(.medium))
                .foregroundColor(AppTheme.Colors.accent)
            }

            Spacer()

            // Flip hint
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "hand.tap.fill")
                Text("Tap to flip")
            }
            .font(AppTheme.Typography.labelSmall())
            .foregroundColor(AppTheme.Colors.textTertiary)
            .padding(.bottom, AppTheme.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(AppTheme.Colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Card Back
    private var cardBack: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Definition
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("DEFINITION")
                        .font(AppTheme.Typography.labelSmall(.bold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1)

                    Text(word.definition)
                        .font(AppTheme.Typography.bodyLarge())
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }

                // Example
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("EXAMPLE")
                        .font(AppTheme.Typography.labelSmall(.bold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1)

                    Text(word.exampleSentence)
                        .font(AppTheme.Typography.bodyMedium())
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .italic()
                }

                // Synonyms if available
                if !word.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("SYNONYMS")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1)

                        Text(word.synonyms.joined(separator: ", "))
                            .font(AppTheme.Typography.bodySmall())
                            .foregroundColor(AppTheme.Colors.secondary)
                    }
                }

                // Mnemonic if available
                if let mnemonic = word.mnemonicHint {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("MEMORY TIP")
                            .font(AppTheme.Typography.labelSmall(.bold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1)

                        Text(mnemonic)
                            .font(AppTheme.Typography.bodySmall())
                            .foregroundColor(AppTheme.Colors.warning)
                    }
                }
            }
            .padding(AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .stroke(AppTheme.Colors.secondary.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Previous (if available)
            if let onPrevious = onPrevious, currentIndex > 0 {
                Button {
                    HapticManager.shared.lightImpact()
                    onPrevious()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .fill(AppTheme.Colors.surface)
                    )
                }
            }

            // Next / Continue
            Button {
                HapticManager.shared.lightImpact()
                onNext()
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(currentIndex == totalCount - 1 ? "Start Quiz" : "Next")
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                    Image(systemName: currentIndex == totalCount - 1 ? "arrow.right" : "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Colors.accent)
                )
            }
        }
        .padding(.bottom, AppTheme.Spacing.md)
    }
}
