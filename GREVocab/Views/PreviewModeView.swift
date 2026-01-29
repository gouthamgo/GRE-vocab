import SwiftUI
import SwiftData

/// Simple browse-only preview mode
/// Tap to flip, swipe/buttons to navigate, marks words as previewed
struct PreviewModeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let deck: Deck

    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var appearAnimation: Bool = false
    @State private var previewedCount: Int = 0

    private var words: [Word] {
        // Prioritize unseen words, then all words
        let unseen = deck.words.filter { $0.learningStage == .unseen }
        if !unseen.isEmpty {
            return unseen
        }
        return Array(deck.words)
    }

    private var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    private var isComplete: Bool {
        currentIndex >= words.count
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                header
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                // Progress
                progressBar
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.md)

                Spacer()

                if isComplete {
                    completeView
                } else if let word = currentWord {
                    cardView(word: word)
                        .opacity(appearAnimation ? 1 : 0)
                        .scaleEffect(appearAnimation ? 1 : 0.9)
                }

                Spacer()

                // Navigation buttons
                if !isComplete {
                    navigationButtons
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
            markCurrentAsPreviewed()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Button {
                HapticManager.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(AppTheme.Colors.surface))
            }

            Spacer()

            // Card counter
            Text("\(currentIndex + 1) of \(words.count)")
                .font(AppTheme.Typography.labelLarge(.semibold))
                .foregroundColor(AppTheme.Colors.textSecondary)

            Spacer()

            // Previewed count badge
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 12))
                Text("\(previewedCount)")
                    .font(AppTheme.Typography.labelMedium(.semibold))
            }
            .foregroundColor(AppTheme.Colors.accent)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(AppTheme.Colors.accent.opacity(0.15)))
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.Colors.surfaceHighlight)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.Colors.accent)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(response: 0.4), value: progress)
            }
        }
        .frame(height: 4)
    }

    private var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }

    // MARK: - Card View
    private func cardView(word: Word) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Tap to flip instruction
            if !isFlipped {
                Text("Tap card to reveal definition")
                    .font(AppTheme.Typography.labelSmall())
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            // The card
            ZStack {
                // Front (term)
                cardFront(word: word)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                // Back (definition)
                cardBack(word: word)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }
            .frame(height: 380)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
                HapticManager.shared.lightImpact()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }

    private func cardFront(word: Word) -> some View {
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
            .padding(.bottom, AppTheme.Spacing.md)
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

    private func cardBack(word: Word) -> some View {
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
            // Previous
            Button {
                goToPrevious()
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                    Text("Previous")
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                }
                .foregroundColor(currentIndex > 0 ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.surface)
                )
            }
            .disabled(currentIndex == 0)

            // Next
            Button {
                goToNext()
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(currentIndex == words.count - 1 ? "Finish" : "Next")
                        .font(AppTheme.Typography.bodyMedium(.semibold))
                    Image(systemName: currentIndex == words.count - 1 ? "checkmark" : "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .fill(AppTheme.Colors.accent)
                )
            }
        }
    }

    // MARK: - Complete View
    private var completeView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "eye.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppTheme.Colors.accent)
            }

            Text("Preview Complete!")
                .font(AppTheme.Typography.displaySmall(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text("You've previewed \(previewedCount) words.\nThey're now ready for quiz!")
                .font(AppTheme.Typography.bodyMedium())
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton("Done", icon: "checkmark") {
                    dismiss()
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.top, AppTheme.Spacing.lg)
        }
        .padding(AppTheme.Spacing.xl)
    }

    // MARK: - Actions
    private func goToNext() {
        HapticManager.shared.lightImpact()

        withAnimation(.easeOut(duration: 0.15)) {
            isFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentIndex += 1
            markCurrentAsPreviewed()
        }
    }

    private func goToPrevious() {
        guard currentIndex > 0 else { return }
        HapticManager.shared.lightImpact()

        withAnimation(.easeOut(duration: 0.15)) {
            isFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentIndex -= 1
        }
    }

    private func markCurrentAsPreviewed() {
        guard let word = currentWord else { return }

        if word.learningStage == .unseen {
            word.markPreviewed()
            previewedCount += 1
            try? modelContext.save()
        }
    }
}

#Preview {
    PreviewModeView(deck: Deck(name: "Test", difficulty: .medium))
        .modelContainer(for: [Word.self, Deck.self], inMemory: true)
}
