import Foundation
import AVFoundation

class TextToSpeechService: TextToSpeechServiceProtocol {
    static let shared = TextToSpeechService()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}

import SwiftUI

// MARK: - Reusable Components

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(title.uppercased())
                    .font(AppTheme.Typography.labelSmall(.bold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)
            }

            Text(value)
                .font(AppTheme.Typography.displaySmall(.black))
                .foregroundColor(AppTheme.Colors.textPrimary)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: color.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color
    var showPercentage: Bool = true
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    AppTheme.Colors.surfaceHighlight,
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)

            // Glow effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color.opacity(0.4), lineWidth: lineWidth + 8)
                .blur(radius: 8)
                .rotationEffect(.degrees(-90))

            if showPercentage {
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))")
                        .font(AppTheme.Typography.headlineLarge(.black))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("%")
                        .font(AppTheme.Typography.labelSmall(.medium))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Deck Card
struct DeckCard: View {
    let deck: Deck

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                // Difficulty badge
                HStack(spacing: AppTheme.Spacing.xxs) {
                    Image(systemName: deck.difficulty.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(deck.difficulty.rawValue.uppercased())
                        .font(AppTheme.Typography.labelSmall(.bold))
                        .tracking(1)
                }
                .foregroundColor(deck.difficulty.themeColor)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(
                    Capsule()
                        .fill(deck.difficulty.themeColor.opacity(0.15))
                )

                Spacer()

                // Review count
                if deck.dueForReviewCount > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppTheme.Colors.accent)
                            .frame(width: 8, height: 8)
                        Text("\(deck.dueForReviewCount)")
                            .font(AppTheme.Typography.labelMedium(.bold))
                            .foregroundColor(AppTheme.Colors.accent)
                    }
                }
            }

            // Deck name
            Text(deck.name)
                .font(AppTheme.Typography.headlineMedium(.bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            // Stats row
            HStack(spacing: AppTheme.Spacing.lg) {
                Label("\(deck.totalWords)", systemImage: "rectangle.stack.fill")
                    .font(AppTheme.Typography.bodySmall(.medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)

                Label("\(deck.masteredCount)", systemImage: "checkmark.circle.fill")
                    .font(AppTheme.Typography.bodySmall(.medium))
                    .foregroundColor(AppTheme.Colors.success.opacity(0.8))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.surfaceHighlight)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [deck.difficulty.themeColor, deck.difficulty.themeColor.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * deck.progress, height: 6)
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .stroke(AppTheme.Colors.surfaceHighlight, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(deck.name) deck, \(deck.difficulty.rawValue) difficulty")
        .accessibilityValue("\(deck.totalWords) words, \(deck.masteredCount) mastered, \(Int(deck.progress * 100)) percent complete")
        .accessibilityHint(deck.dueForReviewCount > 0 ? "\(deck.dueForReviewCount) cards due for review" : "All cards reviewed")
    }
}

// MARK: - Word Row
struct WordRow: View {
    let word: Word

    var statusColor: Color {
        switch word.status {
        case .new: return AppTheme.Colors.textTertiary
        case .learning: return AppTheme.Colors.warning
        case .mastered: return AppTheme.Colors.success
        }
    }

    var statusText: String {
        switch word.status {
        case .new: return "new"
        case .learning: return "learning"
        case .mastered: return "mastered"
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(word.term)
                    .font(AppTheme.Typography.bodyLarge(.semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(word.definition)
                    .font(AppTheme.Typography.bodySmall())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                HapticManager.shared.lightImpact()
                TextToSpeechService.shared.speak(text: word.term)
            }) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.Colors.accent)
                    .padding(8)
                    .background(Circle().fill(AppTheme.Colors.accent.opacity(0.1)))
            }
            .accessibilityLabel("Pronounce \(word.term)")

            // Part of speech
            Text(word.partOfSpeech)
                .font(AppTheme.Typography.labelSmall(.medium))
                .foregroundColor(word.difficulty.themeColor)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(word.difficulty.themeColor.opacity(0.1))
                )
                .accessibilityHidden(true)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.surface)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(word.term), \(word.partOfSpeech)")
        .accessibilityValue("\(word.definition). Status: \(statusText)")
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = AppTheme.Colors.accent
    var isLarge: Bool = false

    init(_ title: String, icon: String? = nil, color: Color = AppTheme.Colors.accent, isLarge: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isLarge = isLarge
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.buttonTap()
            action()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: isLarge ? 18 : 14, weight: .bold))
                }
                Text(title)
                    .font(isLarge ? AppTheme.Typography.headlineSmall(.bold) : AppTheme.Typography.labelLarge())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLarge ? AppTheme.Spacing.lg : AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.2), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            )
            .shadow(color: color.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var color: Color = AppTheme.Colors.textSecondary

    init(_ title: String, icon: String? = nil, color: Color = AppTheme.Colors.textSecondary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.shared.buttonTap()
            action()
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(AppTheme.Typography.labelLarge())
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(color.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Animated Counter
struct AnimatedCounter: View {
    let value: Int
    let font: Font
    let color: Color

    @State private var animatedValue: Int = 0

    var body: some View {
        Text("\(animatedValue)")
            .font(font)
            .foregroundColor(color)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    animatedValue = newValue
                }
            }
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.5), radius: 16, x: 0, y: 8)
                )
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "Get Started"

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(AppTheme.Colors.textTertiary)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.headlineLarge(.bold))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(AppTheme.Typography.bodyMedium())
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let action = action {
                PrimaryButton(actionTitle, icon: "arrow.right", action: action)
                    .frame(maxWidth: 200)
                    .padding(.top, AppTheme.Spacing.md)
            }
        }
        .padding(AppTheme.Spacing.xxl)
    }
}
