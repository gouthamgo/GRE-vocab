import Foundation
import SwiftData

@Model
class UserProgress {
    var currentStreak: Int
    var longestStreak: Int
    var lastStudyDate: Date?
    var totalWordsStudied: Int
    var totalCorrect: Int
    var totalIncorrect: Int
    var dailyGoal: Int

    // Track today's words separately
    var todayStudiedCount: Int
    var todayStudyDate: Date?

    // Achievement tracking
    var totalSessionsCompleted: Int
    var perfectSessionsCount: Int
    var feynmanSessionsCount: Int
    var quizSessionsCount: Int

    // XP and Level system
    var totalXP: Int
    var currentLevel: Int

    // Study time tracking
    var totalStudyTimeSeconds: Int
    var todayStudyTimeSeconds: Int
    var todayStudyTimeDate: Date?

    // Daily session tracking
    var dailySessionCompletedDate: Date?

    // MARK: - NEW: GRE Test & Score Tracking
    var greTestDate: Date?
    var estimatedVerbalScore: Int
    var previousEstimatedScore: Int

    // MARK: - NEW: Notification Settings
    var notificationsEnabled: Bool
    var preferredNotificationHour: Int  // 0-23
    var preferredNotificationMinute: Int  // 0-59

    // MARK: - NEW: Onboarding & Monetization
    var placementScore: Int  // 0-5 from placement quiz
    var appInstallDate: Date?
    var isPremium: Bool
    var premiumExpiryDate: Date?
    var totalWordsAtLastPaywallShow: Int
    var lastPaywallShowDate: Date?
    var hasCompletedEnhancedOnboarding: Bool

    init() {
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalWordsStudied = 0
        self.totalCorrect = 0
        self.totalIncorrect = 0
        self.dailyGoal = 20
        self.todayStudiedCount = 0
        self.todayStudyDate = nil
        self.totalSessionsCompleted = 0
        self.perfectSessionsCount = 0
        self.feynmanSessionsCount = 0
        self.quizSessionsCount = 0
        self.totalXP = 0
        self.currentLevel = 1
        self.totalStudyTimeSeconds = 0
        self.todayStudyTimeSeconds = 0
        self.todayStudyTimeDate = nil
        self.dailySessionCompletedDate = nil

        // NEW: Initialize new fields
        self.greTestDate = nil
        self.estimatedVerbalScore = 145  // Starting baseline
        self.previousEstimatedScore = 145
        self.notificationsEnabled = false
        self.preferredNotificationHour = 9  // Default 9 AM
        self.preferredNotificationMinute = 0
        self.placementScore = 0
        self.appInstallDate = Date()
        self.isPremium = false
        self.premiumExpiryDate = nil
        self.totalWordsAtLastPaywallShow = 0
        self.lastPaywallShowDate = nil
        self.hasCompletedEnhancedOnboarding = false
    }

    /// Check if today's daily session has been completed
    var hasDoneSessionToday: Bool {
        guard let completedDate = dailySessionCompletedDate else { return false }
        return Calendar.current.isDateInToday(completedDate)
    }

    /// Mark today's daily session as completed
    func markDailySessionCompleted() {
        dailySessionCompletedDate = Date()
    }

    var accuracy: Double {
        guard totalWordsStudied > 0 else { return 100 }
        return Double(totalCorrect) / Double(totalWordsStudied) * 100
    }

    var todayWordsStudied: Int {
        // Check if todayStudyDate is today
        guard let studyDate = todayStudyDate, Calendar.current.isDateInToday(studyDate) else {
            return 0
        }
        return todayStudiedCount
    }

    var dailyGoalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todayWordsStudied) / Double(dailyGoal))
    }

    var xpForNextLevel: Int {
        // XP required increases with level
        return currentLevel * 100
    }

    var levelProgress: Double {
        let xpInCurrentLevel = totalXP - xpForLevel(currentLevel - 1)
        let xpNeeded = xpForNextLevel
        return Double(xpInCurrentLevel) / Double(xpNeeded)
    }

    private func xpForLevel(_ level: Int) -> Int {
        guard level > 0 else { return 0 }
        return (level * (level + 1) / 2) * 100
    }

    /// Update streak only (call this when recording study elsewhere)
    func updateStreak() {
        if let lastDate = lastStudyDate {
            if !Calendar.current.isDateInToday(lastDate) {
                if Calendar.current.isDateInYesterday(lastDate) {
                    currentStreak += 1
                } else {
                    currentStreak = 1
                }
            }
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastStudyDate = Date()
    }

    func recordStudy(correct: Bool) {
        // Update streak
        updateStreak()
        totalWordsStudied += 1

        // Update today's count
        if let studyDate = todayStudyDate, Calendar.current.isDateInToday(studyDate) {
            todayStudiedCount += 1
        } else {
            // New day, reset counter
            todayStudyDate = Date()
            todayStudiedCount = 1
        }

        if correct {
            totalCorrect += 1
        } else {
            totalIncorrect += 1
        }
    }

    func addXP(_ amount: Int) {
        totalXP += amount
        // Check for level up
        while totalXP >= xpForLevel(currentLevel) {
            currentLevel += 1
        }
    }

    func recordSession(correct: Int, incorrect: Int, sessionType: String, duration: TimeInterval) {
        totalSessionsCompleted += 1

        // Track perfect sessions (100% accuracy with at least 5 words)
        let total = correct + incorrect
        if total >= 5 && incorrect == 0 {
            perfectSessionsCount += 1
        }

        // Track session types
        if sessionType == "feynman" {
            feynmanSessionsCount += 1
        } else if sessionType == "quiz" {
            quizSessionsCount += 1
        }

        // Track study time
        totalStudyTimeSeconds += Int(duration)
        if let timeDate = todayStudyTimeDate, Calendar.current.isDateInToday(timeDate) {
            todayStudyTimeSeconds += Int(duration)
        } else {
            todayStudyTimeDate = Date()
            todayStudyTimeSeconds = Int(duration)
        }

        // Award XP based on performance
        let baseXP = total * 10
        let accuracyBonus = incorrect == 0 ? 20 : 0
        let streakBonus = currentStreak * 5
        addXP(baseXP + accuracyBonus + streakBonus)
    }

    var formattedTotalStudyTime: String {
        let hours = totalStudyTimeSeconds / 3600
        let minutes = (totalStudyTimeSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedTodayStudyTime: String {
        guard let timeDate = todayStudyTimeDate, Calendar.current.isDateInToday(timeDate) else {
            return "0m"
        }
        let minutes = todayStudyTimeSeconds / 60
        return "\(minutes)m"
    }

    // MARK: - GRE Test Date Computed Properties

    /// Days remaining until GRE test
    var daysUntilGRE: Int? {
        guard let testDate = greTestDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: testDate).day
        return max(0, days ?? 0)
    }

    /// Formatted string for days until GRE
    var daysUntilGREFormatted: String {
        guard let days = daysUntilGRE else { return "No date set" }
        if days == 0 { return "Today!" }
        if days == 1 { return "Tomorrow!" }
        return "\(days) days"
    }

    /// Score change since last update
    var scoreChange: Int {
        return estimatedVerbalScore - previousEstimatedScore
    }

    /// Formatted score change string
    var scoreChangeFormatted: String {
        if scoreChange > 0 {
            return "+\(scoreChange)"
        } else if scoreChange < 0 {
            return "\(scoreChange)"
        }
        return "—"
    }

    /// Update estimated score and track previous
    func updateEstimatedScore(_ newScore: Int) {
        previousEstimatedScore = estimatedVerbalScore
        estimatedVerbalScore = min(170, max(130, newScore))
    }

    /// Preferred notification time as Date components
    var preferredNotificationTime: DateComponents {
        var components = DateComponents()
        components.hour = preferredNotificationHour
        components.minute = preferredNotificationMinute
        return components
    }

    /// Set notification time from Date
    func setNotificationTime(from date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        preferredNotificationHour = components.hour ?? 9
        preferredNotificationMinute = components.minute ?? 0
    }

    /// Formatted notification time
    var formattedNotificationTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        var components = DateComponents()
        components.hour = preferredNotificationHour
        components.minute = preferredNotificationMinute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "9:00 AM"
    }

    // MARK: - Paywall Logic

    /// Days since app install
    var daysSinceInstall: Int {
        guard let installDate = appInstallDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }

    /// Check if paywall should be shown
    var shouldShowPaywall: Bool {
        // Don't show if premium
        if isPremium { return false }

        // Show if Day 3+ and haven't shown today
        let isDay3Plus = daysSinceInstall >= 3

        // Show if 50+ words learned since last paywall
        let wordsLearnedSincePaywall = totalWordsStudied - totalWordsAtLastPaywallShow
        let has50NewWords = wordsLearnedSincePaywall >= 50

        // Don't show more than once per day
        if let lastShow = lastPaywallShowDate, Calendar.current.isDateInToday(lastShow) {
            return false
        }

        return isDay3Plus || has50NewWords
    }

    /// Record that paywall was shown
    func recordPaywallShown() {
        lastPaywallShowDate = Date()
        totalWordsAtLastPaywallShow = totalWordsStudied
    }

    /// Check if premium subscription is active
    var hasPremiumAccess: Bool {
        guard isPremium else { return false }

        if let expiry = premiumExpiryDate {
            return expiry > Date()
        }
        return true  // Lifetime or no expiry set
    }

    /// Activate premium subscription
    func activatePremium(expiryDate: Date? = nil) {
        isPremium = true
        premiumExpiryDate = expiryDate
    }

    /// Deactivate premium subscription
    func deactivatePremium() {
        isPremium = false
        premiumExpiryDate = nil
    }
}