import Foundation

/// Service for predicting GRE Verbal scores based on user performance
///
/// GRE Verbal Reasoning scores range from 130-170 in 1-point increments.
/// This service estimates a user's likely score based on:
/// - Number of words mastered
/// - Quiz accuracy
/// - Response time
/// - Learning stage distribution
class ScorePredictorService {

    static let shared = ScorePredictorService()

    private init() {}

    // MARK: - Score Constants

    /// Base score (50th percentile) for a new user
    private let baseScore: Int = 145

    /// Minimum possible GRE Verbal score
    private let minScore: Int = 130

    /// Maximum possible GRE Verbal score
    private let maxScore: Int = 170

    // MARK: - Score Calculation

    /// Calculate estimated GRE Verbal score
    /// - Parameters:
    ///   - masteredWords: Number of words the user has mastered
    ///   - totalWords: Total words in the system
    ///   - accuracy: Overall quiz accuracy (0.0 - 1.0)
    ///   - avgResponseTime: Average response time in seconds
    ///   - deepLearnedCount: Words that have been deep learned
    /// - Returns: Estimated GRE Verbal score (130-170)
    func calculateScore(
        masteredWords: Int,
        totalWords: Int,
        accuracy: Double,
        avgResponseTime: Double = 10.0,
        deepLearnedCount: Int = 0
    ) -> Int {
        // Word mastery contribution (0-15 points)
        // Every ~33 words mastered = +1 point, max 15 points for 500 words
        let wordMasteryBonus = min(15, masteredWords / 33)

        // Accuracy contribution (-5 to +5 points)
        // 70% accuracy = 0 bonus
        // 90%+ = +5, 50% = -5
        let accuracyNormalized = accuracy - 0.7
        let accuracyBonus = Int(accuracyNormalized * 25)
        let clampedAccuracyBonus = max(-5, min(5, accuracyBonus))

        // Speed bonus (0-3 points)
        // Fast AND accurate responses indicate strong knowledge
        let speedBonus: Int
        if avgResponseTime < 5.0 && accuracy > 0.8 {
            speedBonus = 3
        } else if avgResponseTime < 8.0 && accuracy > 0.7 {
            speedBonus = 1
        } else {
            speedBonus = 0
        }

        // Deep learning bonus (0-2 points)
        // Users who use Feynman technique retain better
        let deepLearnBonus = min(2, deepLearnedCount / 25)

        // Calculate total score
        let estimatedScore = baseScore + wordMasteryBonus + clampedAccuracyBonus + speedBonus + deepLearnBonus

        // Clamp to valid GRE range
        return min(maxScore, max(minScore, estimatedScore))
    }

    /// Calculate score from word statistics
    /// - Parameters:
    ///   - masteredCount: Number of mastered words
    ///   - deepLearnedCount: Number of deep learned words
    ///   - totalCount: Total words in system
    ///   - totalStudied: Total words studied
    ///   - totalCorrect: Total correct answers
    ///   - avgResponseTime: Average response time
    func calculateScoreFromStats(
        masteredCount: Int,
        deepLearnedCount: Int,
        totalCount: Int,
        totalStudied: Int,
        totalCorrect: Int,
        avgResponseTime: Double = 10.0
    ) -> Int {
        let accuracy: Double
        if totalStudied > 0 {
            accuracy = Double(totalCorrect) / Double(totalStudied)
        } else {
            accuracy = 0.7  // Default assumption
        }

        return calculateScore(
            masteredWords: masteredCount,
            totalWords: totalCount,
            accuracy: accuracy,
            avgResponseTime: avgResponseTime,
            deepLearnedCount: deepLearnedCount
        )
    }

    // MARK: - Score Insights

    /// Get a description of what the score means
    func getScoreDescription(_ score: Int) -> String {
        switch score {
        case 170:
            return "Perfect! Top 1% of test takers"
        case 165...169:
            return "Excellent! Top 5% of test takers"
        case 160...164:
            return "Great! Top 15% of test takers"
        case 155...159:
            return "Good! Above average"
        case 150...154:
            return "Average performance"
        case 145...149:
            return "Below average - keep practicing!"
        case 140...144:
            return "Needs improvement"
        default:
            return "Keep studying to improve!"
        }
    }

    /// Get percentile estimate for a score
    func getPercentile(_ score: Int) -> Int {
        // Approximate percentiles based on ETS data
        switch score {
        case 170: return 99
        case 169: return 99
        case 168: return 98
        case 167: return 97
        case 166: return 96
        case 165: return 95
        case 164: return 93
        case 163: return 91
        case 162: return 88
        case 161: return 86
        case 160: return 83
        case 159: return 80
        case 158: return 77
        case 157: return 73
        case 156: return 69
        case 155: return 65
        case 154: return 61
        case 153: return 56
        case 152: return 52
        case 151: return 47
        case 150: return 43
        case 149: return 38
        case 148: return 34
        case 147: return 30
        case 146: return 26
        case 145: return 22
        case 144: return 19
        case 143: return 16
        case 142: return 13
        case 141: return 10
        case 140: return 8
        default:
            if score > 170 { return 99 }
            return max(1, score - 130)
        }
    }

    /// Get recommendation to reach target score
    func getRecommendation(currentScore: Int, targetScore: Int, daysRemaining: Int?) -> String {
        let pointsNeeded = targetScore - currentScore

        if pointsNeeded <= 0 {
            return "You're on track to meet your goal!"
        }

        // Estimate words needed per point
        let wordsPerPoint = 33
        let additionalWordsNeeded = pointsNeeded * wordsPerPoint

        if let days = daysRemaining, days > 0 {
            let wordsPerDay = max(5, additionalWordsNeeded / days)
            return "Study \(wordsPerDay) more words/day to reach \(targetScore)"
        }

        return "Master \(additionalWordsNeeded) more words to reach \(targetScore)"
    }

    // MARK: - Readiness Calculation

    /// Calculate overall GRE readiness percentage
    func calculateReadiness(
        masteredWords: Int,
        totalWords: Int,
        currentScore: Int,
        targetScore: Int
    ) -> Double {
        // Word mastery component (50% weight)
        let wordReadiness = min(1.0, Double(masteredWords) / Double(max(1, totalWords)))

        // Score progress component (50% weight)
        let scoreProgress: Double
        if targetScore > baseScore {
            scoreProgress = Double(currentScore - baseScore) / Double(targetScore - baseScore)
        } else {
            scoreProgress = currentScore >= targetScore ? 1.0 : 0.5
        }

        let overallReadiness = (wordReadiness * 0.5) + (min(1.0, scoreProgress) * 0.5)
        return min(1.0, max(0.0, overallReadiness))
    }

    // MARK: - Score Projection

    /// Project score based on current learning rate
    func projectScore(
        currentScore: Int,
        wordsLearnedPerDay: Double,
        daysRemaining: Int
    ) -> Int {
        // Estimate additional points based on projected word mastery
        let projectedWords = Int(wordsLearnedPerDay * Double(daysRemaining))
        let additionalPoints = projectedWords / 33

        return min(maxScore, currentScore + additionalPoints)
    }

    /// Get color for score display
    func scoreColor(for score: Int, target: Int? = nil) -> ScoreColorCategory {
        if let target = target {
            if score >= target { return .success }
            if score >= target - 5 { return .warning }
            return .needsWork
        }

        // General categorization
        switch score {
        case 160...170: return .success
        case 150...159: return .warning
        default: return .needsWork
        }
    }

    enum ScoreColorCategory {
        case success
        case warning
        case needsWork
    }
}
