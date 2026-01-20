import UIKit

class HapticManager {
    static let shared = HapticManager()

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
    }

    private init() {
        // Set default value if not set
        if UserDefaults.standard.object(forKey: "hapticFeedbackEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "hapticFeedbackEnabled")
        }
    }

    // MARK: - Impact Feedback

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func lightImpact() {
        impact(.light)
    }

    func mediumImpact() {
        impact(.medium)
    }

    func heavyImpact() {
        impact(.heavy)
    }

    func softImpact() {
        impact(.soft)
    }

    func rigidImpact() {
        impact(.rigid)
    }

    // MARK: - Notification Feedback

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    func success() {
        notification(.success)
    }

    func warning() {
        notification(.warning)
    }

    func error() {
        notification(.error)
    }

    // MARK: - Selection Feedback

    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    // MARK: - Custom Patterns

    func cardFlip() {
        lightImpact()
    }

    func cardSwipeRight() {
        success()
    }

    func cardSwipeLeft() {
        mediumImpact()
    }

    func buttonTap() {
        lightImpact()
    }

    func tabChange() {
        selection()
    }

    func sessionComplete() {
        DispatchQueue.main.async {
            self.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.lightImpact()
            }
        }
    }

    func correctAnswer() {
        success()
    }

    func incorrectAnswer() {
        error()
    }
}
