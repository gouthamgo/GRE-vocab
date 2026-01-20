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

    func recordStudy(correct: Bool) {
        // Update streak
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
}