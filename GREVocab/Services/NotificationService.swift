import Foundation
import UserNotifications

/// Service for managing push notifications
class NotificationService {

    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    /// Request notification permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                }
                completion(granted)
            }
        }
    }

    /// Check if notifications are authorized
    func checkPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }

    // MARK: - Scheduling

    /// Schedule daily study reminder
    func scheduleDailyReminder(at hour: Int, minute: Int, wordsDue: Int = 0) {
        // Remove existing daily reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Time to Study!"
        content.body = wordsDue > 0
            ? "You have \(wordsDue) words waiting for review. Keep your streak alive!"
            : "A few minutes of practice keeps your vocabulary sharp."
        content.sound = .default
        content.badge = NSNumber(value: wordsDue)

        // Create trigger for specific time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            } else {
                print("Daily reminder scheduled for \(hour):\(minute)")
            }
        }
    }

    /// Schedule streak warning notification
    func scheduleStreakWarning(currentStreak: Int, at date: Date) {
        guard currentStreak >= 3 else { return }  // Only warn for meaningful streaks

        let content = UNMutableNotificationContent()
        content.title = "Don't Lose Your Streak! 🔥"
        content.body = "Your \(currentStreak)-day streak is about to break. Study now to keep it going!"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "streak_warning",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling streak warning: \(error)")
            }
        }
    }

    /// Schedule GRE countdown reminder
    func scheduleGRECountdown(daysRemaining: Int, testDate: Date) {
        guard daysRemaining > 0 else { return }

        // Only schedule at key milestones
        let milestones = [30, 14, 7, 3, 1]
        guard milestones.contains(daysRemaining) else { return }

        let content = UNMutableNotificationContent()

        switch daysRemaining {
        case 1:
            content.title = "GRE Tomorrow! 📚"
            content.body = "Your GRE is tomorrow. You've got this! Review your toughest words one more time."
        case 3:
            content.title = "3 Days to GRE"
            content.body = "Final push! Focus on your weakest words and get plenty of rest."
        case 7:
            content.title = "1 Week to GRE"
            content.body = "One week left. Keep up your daily practice to stay sharp."
        case 14:
            content.title = "2 Weeks to GRE"
            content.body = "You're making great progress. Stay consistent with your studies."
        case 30:
            content.title = "1 Month to GRE"
            content.body = "30 days to go! You have plenty of time to master all the words."
        default:
            return
        }

        content.sound = .default

        // Schedule for 9 AM on that day
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: testDate)
        dateComponents.day! -= daysRemaining
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "gre_countdown_\(daysRemaining)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling GRE countdown: \(error)")
            }
        }
    }

    /// Schedule achievement notification
    func scheduleAchievementNotification(title: String, message: String, delay: TimeInterval = 1.0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        let request = UNNotificationRequest(
            identifier: "achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling achievement notification: \(error)")
            }
        }
    }

    /// Schedule re-engagement notification for lapsed users
    func scheduleReEngagement(after days: Int = 3) {
        let content = UNMutableNotificationContent()
        content.title = "We Miss You! 📚"
        content.body = "Your vocabulary skills are waiting. Come back and continue your GRE prep!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(days * 24 * 60 * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "re_engagement",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling re-engagement notification: \(error)")
            }
        }
    }

    // MARK: - Cancellation

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Cancel specific notification
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Cancel daily reminder
    func cancelDailyReminder() {
        cancelNotification(identifier: "daily_reminder")
    }

    // MARK: - Badge Management

    /// Clear app badge
    func clearBadge() {
        notificationCenter.setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            }
        }
    }

    /// Set app badge count
    func setBadge(count: Int) {
        notificationCenter.setBadgeCount(count) { error in
            if let error = error {
                print("Error setting badge: \(error)")
            }
        }
    }

    // MARK: - Helpers

    /// Update notifications based on user progress
    func updateNotifications(
        enabled: Bool,
        hour: Int,
        minute: Int,
        currentStreak: Int,
        greTestDate: Date?,
        wordsDue: Int
    ) {
        if enabled {
            // Schedule daily reminder
            scheduleDailyReminder(at: hour, minute: minute, wordsDue: wordsDue)

            // Schedule streak warning for evening if user hasn't studied
            if currentStreak >= 3 {
                var warningComponents = DateComponents()
                warningComponents.hour = 20  // 8 PM
                warningComponents.minute = 0
                if let warningDate = Calendar.current.date(from: warningComponents) {
                    scheduleStreakWarning(currentStreak: currentStreak, at: warningDate)
                }
            }

            // Schedule GRE countdown reminders
            if let testDate = greTestDate {
                let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: testDate).day ?? 0
                for milestone in [30, 14, 7, 3, 1] {
                    if daysRemaining >= milestone {
                        scheduleGRECountdown(daysRemaining: milestone, testDate: testDate)
                    }
                }
            }

            // Schedule re-engagement
            scheduleReEngagement(after: 3)

            // Update badge
            setBadge(count: wordsDue)
        } else {
            cancelAllNotifications()
            clearBadge()
        }
    }
}
