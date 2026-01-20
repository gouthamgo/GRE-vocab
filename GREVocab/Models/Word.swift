import Foundation
import SwiftData

@Model
class Word {
    var term: String
    var definition: String
    var partOfSpeech: String
    var exampleSentence: String
    var difficulty: Difficulty
    var status: WordStatus
    var lastReviewDate: Date?
    var nextReviewDate: Date?
    var repetitions: Int
    var easeFactor: Double
    var interval: Int

    // Enhanced learning fields
    var synonyms: [String]
    var antonyms: [String]
    var mnemonicHint: String?
    var rootWord: String?
    var rootMeaning: String?
    var relatedWords: [String]
    var usageNotes: String?
    var frequency: FrequencyTier
    var source: WordSource

    // Feynman technique fields
    var userExplanation: String?
    var userExample: String?
    var feynmanConfidence: Int // 1-5 rating

    // Learning analytics
    var timesReviewed: Int
    var timesCorrect: Int
    var lastCorrectDate: Date?
    var averageResponseTime: Double // in seconds

    // Learning Path tracking (Preview → Quiz → DeepLearn)
    var learningStage: LearningStage
    var previewedDate: Date?          // When first previewed
    var quizPassCount: Int            // Times passed quiz (for spaced rep)
    var lastQuizDate: Date?           // Last quiz attempt
    var nextQuizDue: Date?            // When next quiz is due
    var deepLearnDate: Date?          // When completed deep learn
    var timesQuizFailed: Int          // Track struggles for recommendations

    init(term: String, definition: String, partOfSpeech: String, exampleSentence: String, difficulty: Difficulty) {
        self.term = term
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.exampleSentence = exampleSentence
        self.difficulty = difficulty
        self.status = .new
        self.repetitions = 0
        self.easeFactor = 2.5
        self.interval = 1
        self.synonyms = []
        self.antonyms = []
        self.mnemonicHint = nil
        self.rootWord = nil
        self.rootMeaning = nil
        self.relatedWords = []
        self.usageNotes = nil
        self.frequency = .common
        self.source = .custom
        self.userExplanation = nil
        self.userExample = nil
        self.feynmanConfidence = 0
        self.timesReviewed = 0
        self.timesCorrect = 0
        self.lastCorrectDate = nil
        self.averageResponseTime = 0
        self.learningStage = .unseen
        self.previewedDate = nil
        self.quizPassCount = 0
        self.lastQuizDate = nil
        self.nextQuizDue = nil
        self.deepLearnDate = nil
        self.timesQuizFailed = 0
    }

    // Full initializer with all fields
    init(
        term: String,
        definition: String,
        partOfSpeech: String,
        exampleSentence: String,
        difficulty: Difficulty,
        synonyms: [String] = [],
        antonyms: [String] = [],
        mnemonicHint: String? = nil,
        rootWord: String? = nil,
        rootMeaning: String? = nil,
        relatedWords: [String] = [],
        usageNotes: String? = nil,
        frequency: FrequencyTier = .common,
        source: WordSource = .custom
    ) {
        self.term = term
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.exampleSentence = exampleSentence
        self.difficulty = difficulty
        self.status = .new
        self.repetitions = 0
        self.easeFactor = 2.5
        self.interval = 1
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.mnemonicHint = mnemonicHint
        self.rootWord = rootWord
        self.rootMeaning = rootMeaning
        self.relatedWords = relatedWords
        self.usageNotes = usageNotes
        self.frequency = frequency
        self.source = source
        self.userExplanation = nil
        self.userExample = nil
        self.feynmanConfidence = 0
        self.timesReviewed = 0
        self.timesCorrect = 0
        self.lastCorrectDate = nil
        self.averageResponseTime = 0
        self.learningStage = .unseen
        self.previewedDate = nil
        self.quizPassCount = 0
        self.lastQuizDate = nil
        self.nextQuizDue = nil
        self.deepLearnDate = nil
        self.timesQuizFailed = 0
    }

    var isDueForReview: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return Date() >= nextReview
    }

    var masteryScore: Double {
        guard timesReviewed > 0 else { return 0 }
        let accuracyScore = Double(timesCorrect) / Double(timesReviewed)
        let repetitionScore = min(1.0, Double(repetitions) / 5.0)
        let feynmanScore = Double(feynmanConfidence) / 5.0
        return (accuracyScore * 0.4 + repetitionScore * 0.4 + feynmanScore * 0.2) * 100
    }

    var hasFeynmanData: Bool {
        return userExplanation != nil || userExample != nil
    }

    func recordReview(correct: Bool, responseTime: TimeInterval) {
        timesReviewed += 1
        if correct {
            timesCorrect += 1
            lastCorrectDate = Date()
        }

        // Update average response time
        if averageResponseTime == 0 {
            averageResponseTime = responseTime
        } else {
            averageResponseTime = (averageResponseTime * Double(timesReviewed - 1) + responseTime) / Double(timesReviewed)
        }
    }

    // MARK: - Learning Path Methods

    /// Mark word as previewed (seen in flashcard/preview mode)
    func markPreviewed() {
        if learningStage == .unseen {
            learningStage = .previewed
            previewedDate = Date()
            if status == .new {
                status = .learning
            }
        }
    }

    /// Record quiz attempt and update learning stage
    func recordQuizAttempt(passed: Bool) {
        lastQuizDate = Date()

        if passed {
            quizPassCount += 1

            // Move to quizPassed if first pass, or stay there
            if learningStage == .previewed || learningStage == .quizReady || learningStage == .unseen {
                learningStage = .quizPassed
            }

            // Schedule next quiz using spaced repetition intervals
            let intervals = [1, 3, 7, 14, 30, 60] // days
            let intervalIndex = min(quizPassCount - 1, intervals.count - 1)
            let daysUntilNext = intervals[intervalIndex]
            nextQuizDue = Calendar.current.date(byAdding: .day, value: daysUntilNext, to: Date())

        } else {
            timesQuizFailed += 1

            // Reset to shorter interval on failure
            nextQuizDue = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        }
    }

    /// Mark deep learn (Feynman) as completed
    func markDeepLearned(confidence: Int) {
        feynmanConfidence = confidence
        deepLearnDate = Date()

        if confidence >= 4 {
            learningStage = .deepLearned
            updateMasteryStatus()
        }
    }

    /// Update mastery status based on learning path completion
    func updateMasteryStatus() {
        // Mastery requires: quiz passed + deep learned + sufficient repetitions
        let hasPassedQuiz = quizPassCount >= 1
        let hasDeepLearned = learningStage == .deepLearned && feynmanConfidence >= 4
        let hasRetention = quizPassCount >= 3 // Passed quiz at least 3 times over time

        if hasPassedQuiz && hasDeepLearned && hasRetention {
            status = .mastered
        } else if hasPassedQuiz || learningStage != .unseen {
            status = .learning
        }
    }

    /// Check if word is due for quiz review (spaced repetition)
    var isDueForQuiz: Bool {
        guard quizPassCount > 0, let nextDue = nextQuizDue else {
            // Never quizzed or no schedule = ready for quiz
            return learningStage == .previewed || learningStage == .quizReady || learningStage == .quizPassed
        }
        return Date() >= nextDue
    }

    /// Check if word needs deep learning attention
    var needsDeepLearning: Bool {
        // Needs deep learn if: failed quiz multiple times OR passed quiz but not deep learned
        return timesQuizFailed >= 2 || (learningStage == .quizPassed && feynmanConfidence < 4)
    }

    /// Progress through learning path (0.0 to 1.0)
    var learningPathProgress: Double {
        switch learningStage {
        case .unseen: return 0.0
        case .previewed: return 0.2
        case .quizReady: return 0.3
        case .quizPassed: return 0.6
        case .deepLearned: return 1.0
        }
    }
}

// MARK: - Frequency Tier
enum FrequencyTier: String, Codable, CaseIterable {
    case essential = "Essential"    // Must know - appears 70%+ of tests
    case common = "Common"          // Frequently seen - 50-70%
    case uncommon = "Uncommon"      // Occasionally - 20-50%
    case rare = "Rare"              // Sometimes - <20%

    var displayName: String {
        return rawValue
    }

    var color: String {
        switch self {
        case .essential: return "Success"
        case .common: return "Accent"
        case .uncommon: return "Warning"
        case .rare: return "Tertiary"
        }
    }

    var priority: Int {
        switch self {
        case .essential: return 4
        case .common: return 3
        case .uncommon: return 2
        case .rare: return 1
        }
    }
}

// MARK: - Word Source
enum WordSource: String, Codable, CaseIterable {
    case magooshBasic = "Magoosh Basic"
    case magooshCommon = "Magoosh Common"
    case magooshAdvanced = "Magoosh Advanced"
    case barrons = "Barron's"
    case manhattan = "Manhattan"
    case custom = "Custom"

    var displayName: String {
        return rawValue
    }
}