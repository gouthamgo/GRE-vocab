import Foundation
import SwiftData

@Model
class Achievement {
    var id: String
    var title: String
    var descriptionText: String
    var icon: String
    var category: AchievementCategory
    var requirement: Int
    var currentProgress: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    var xpReward: Int

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int,
        xpReward: Int = 50
    ) {
        self.id = id
        self.title = title
        self.descriptionText = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.currentProgress = 0
        self.isUnlocked = false
        self.unlockedDate = nil
        self.xpReward = xpReward
    }

    var progress: Double {
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(currentProgress) / Double(requirement))
    }

    func updateProgress(_ newValue: Int) -> Bool {
        currentProgress = newValue
        if currentProgress >= requirement && !isUnlocked {
            isUnlocked = true
            unlockedDate = Date()
            return true // Achievement just unlocked
        }
        return false
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "Streak"
    case mastery = "Mastery"
    case session = "Session"
    case learning = "Learning"
    case challenge = "Challenge"

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .mastery: return "star.fill"
        case .session: return "book.fill"
        case .learning: return "lightbulb.fill"
        case .challenge: return "trophy.fill"
        }
    }
}

// MARK: - Achievement Definitions
struct AchievementDefinitions {
    static let all: [(id: String, title: String, description: String, icon: String, category: AchievementCategory, requirement: Int, xpReward: Int)] = [
        // Streak achievements
        ("streak_3", "Getting Started", "Maintain a 3-day streak", "flame", .streak, 3, 30),
        ("streak_7", "Week Warrior", "Maintain a 7-day streak", "flame.fill", .streak, 7, 70),
        ("streak_14", "Fortnight Fighter", "Maintain a 14-day streak", "flame.circle", .streak, 14, 140),
        ("streak_30", "Monthly Master", "Maintain a 30-day streak", "flame.circle.fill", .streak, 30, 300),
        ("streak_100", "Century Champion", "Maintain a 100-day streak", "sparkles", .streak, 100, 1000),

        // Mastery achievements
        ("master_10", "First Steps", "Master 10 words", "star", .mastery, 10, 50),
        ("master_50", "Vocab Builder", "Master 50 words", "star.fill", .mastery, 50, 100),
        ("master_100", "Century Club", "Master 100 words", "star.circle", .mastery, 100, 200),
        ("master_250", "Word Wizard", "Master 250 words", "star.circle.fill", .mastery, 250, 500),
        ("master_500", "Vocabulary Virtuoso", "Master 500 words", "crown.fill", .mastery, 500, 1000),

        // Session achievements
        ("session_1", "First Session", "Complete your first study session", "play.fill", .session, 1, 20),
        ("session_10", "Regular Learner", "Complete 10 study sessions", "play.circle", .session, 10, 100),
        ("session_50", "Dedicated Student", "Complete 50 study sessions", "play.circle.fill", .session, 50, 250),
        ("session_100", "Study Champion", "Complete 100 study sessions", "graduationcap.fill", .session, 100, 500),
        ("perfect_1", "Perfect Score", "Complete a session with 100% accuracy", "checkmark.seal.fill", .session, 1, 50),
        ("perfect_10", "Perfectionist", "Complete 10 perfect sessions", "checkmark.seal", .session, 10, 200),

        // Learning achievements
        ("feynman_1", "Teaching Mode", "Complete your first Feynman session", "lightbulb", .learning, 1, 30),
        ("feynman_10", "Explainer", "Complete 10 Feynman sessions", "lightbulb.fill", .learning, 10, 150),
        ("feynman_50", "Master Teacher", "Complete 50 Feynman sessions", "lightbulb.circle", .learning, 50, 500),
        ("quiz_1", "Quiz Taker", "Complete your first quiz", "questionmark.circle", .learning, 1, 30),
        ("quiz_25", "Quiz Master", "Complete 25 quizzes", "questionmark.circle.fill", .learning, 25, 250),

        // Challenge achievements
        ("daily_1", "Challenger", "Complete your first daily challenge", "flag", .challenge, 1, 25),
        ("daily_7", "Weekly Challenger", "Complete 7 daily challenges", "flag.fill", .challenge, 7, 100),
        ("daily_30", "Monthly Challenger", "Complete 30 daily challenges", "flag.circle.fill", .challenge, 30, 500),

        // Special achievements
        ("night_owl", "Night Owl", "Study after 10 PM", "moon.fill", .session, 1, 25),
        ("early_bird", "Early Bird", "Study before 7 AM", "sun.horizon.fill", .session, 1, 25),
        ("speed_demon", "Speed Demon", "Complete a 20-word session in under 5 minutes", "bolt.fill", .session, 1, 75),
        ("comeback", "Comeback Kid", "Return after 7+ days away and study", "arrow.uturn.up.circle.fill", .streak, 1, 50),
    ]
}

// MARK: - Daily Challenge
@Model
class DailyChallenge {
    var id: UUID
    var date: Date
    var title: String
    var descriptionText: String
    var challengeType: ChallengeType
    var targetCount: Int
    var currentCount: Int
    var xpReward: Int
    var isCompleted: Bool
    var completedDate: Date?

    init(
        title: String,
        description: String,
        type: ChallengeType,
        targetCount: Int,
        xpReward: Int
    ) {
        self.id = UUID()
        self.date = Date()
        self.title = title
        self.descriptionText = description
        self.challengeType = type
        self.targetCount = targetCount
        self.currentCount = 0
        self.xpReward = xpReward
        self.isCompleted = false
        self.completedDate = nil
    }

    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(1.0, Double(currentCount) / Double(targetCount))
    }

    func updateProgress(_ newValue: Int) -> Bool {
        currentCount = newValue
        if currentCount >= targetCount && !isCompleted {
            isCompleted = true
            completedDate = Date()
            return true
        }
        return false
    }
}

enum ChallengeType: String, Codable, CaseIterable {
    case studyWords = "Study Words"
    case perfectAccuracy = "Perfect Accuracy"
    case feynmanMode = "Feynman Mode"
    case learnNew = "Learn New Words"
    case reviewDue = "Review Due Words"
    case speedChallenge = "Speed Challenge"
    case rootWords = "Root Words"

    var icon: String {
        switch self {
        case .studyWords: return "book.fill"
        case .perfectAccuracy: return "target"
        case .feynmanMode: return "lightbulb.fill"
        case .learnNew: return "plus.circle.fill"
        case .reviewDue: return "arrow.clockwise"
        case .speedChallenge: return "bolt.fill"
        case .rootWords: return "tree.fill"
        }
    }
}

// MARK: - Challenge Generator
struct ChallengeGenerator {
    static func generateDailyChallenge() -> DailyChallenge {
        let challenges: [(title: String, description: String, type: ChallengeType, target: Int, xp: Int)] = [
            ("Word Hunter", "Study 30 words today", .studyWords, 30, 50),
            ("Perfect Round", "Complete a session with 100% accuracy", .perfectAccuracy, 1, 75),
            ("Teaching Mode", "Complete 3 Feynman sessions", .feynmanMode, 3, 60),
            ("Explorer", "Learn 10 new words", .learnNew, 10, 40),
            ("Catch Up", "Review all due words", .reviewDue, 1, 50),
            ("Speed Learner", "Study 20 words in under 10 minutes", .speedChallenge, 20, 80),
            ("Root Master", "Study 5 words with Latin or Greek roots", .rootWords, 5, 45),
            ("Double Down", "Study 50 words today", .studyWords, 50, 100),
            ("Triple Threat", "Complete 3 perfect sessions", .perfectAccuracy, 3, 150),
        ]

        let randomChallenge = challenges.randomElement()!
        return DailyChallenge(
            title: randomChallenge.title,
            description: randomChallenge.description,
            type: randomChallenge.type,
            targetCount: randomChallenge.target,
            xpReward: randomChallenge.xp
        )
    }
}
