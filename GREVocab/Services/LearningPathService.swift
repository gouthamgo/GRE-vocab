import Foundation
import SwiftData

/// Manages the learning path flow: Preview → Quiz → DeepLearn
/// Handles word queuing, stage progression, and recommendations
final class LearningPathService {
    static let shared = LearningPathService()
    private init() {}

    // MARK: - Word Queues

    /// Get words ready for preview (never seen)
    func getPreviewQueue(from words: [Word], limit: Int = 20) -> [Word] {
        return Array(
            words
                .filter { $0.learningStage == .unseen }
                .sorted { $0.frequency.priority > $1.frequency.priority }
                .prefix(limit)
        )
    }

    /// Get words ready for quiz
    /// Includes: previewed words + words due for spaced repetition review
    func getQuizQueue(from words: [Word], limit: Int = 20) -> [Word] {
        let readyForFirstQuiz = words.filter {
            $0.learningStage == .previewed || $0.learningStage == .quizReady
        }

        let dueForReview = words.filter {
            ($0.learningStage == .quizPassed || $0.learningStage == .deepLearned) && $0.isDueForQuiz
        }

        // Prioritize: due reviews first, then new quiz candidates
        let combined = dueForReview + readyForFirstQuiz
        return Array(combined.prefix(limit))
    }

    /// Get words that need deep learning (Feynman mode)
    func getDeepLearnQueue(from words: [Word], limit: Int = 10) -> [Word] {
        return Array(
            words
                .filter { $0.needsDeepLearning }
                .sorted { $0.timesQuizFailed > $1.timesQuizFailed }
                .prefix(limit)
        )
    }

    /// Get struggling words (failed quiz 2+ times)
    func getStrugglingWords(from words: [Word]) -> [Word] {
        return words.filter { $0.timesQuizFailed >= 2 }
    }

    // MARK: - Statistics

    /// Learning path statistics for a set of words
    func getStats(for words: [Word]) -> LearningPathStats {
        let unseen = words.filter { $0.learningStage == .unseen }.count
        let previewed = words.filter { $0.learningStage == .previewed }.count
        let quizReady = words.filter { $0.learningStage == .quizReady }.count
        let quizPassed = words.filter { $0.learningStage == .quizPassed }.count
        let deepLearned = words.filter { $0.learningStage == .deepLearned }.count
        let mastered = words.filter { $0.status == .mastered }.count

        let readyForQuiz = getQuizQueue(from: words, limit: 1000).count
        let needsDeepLearn = getDeepLearnQueue(from: words, limit: 1000).count
        let struggling = getStrugglingWords(from: words).count

        return LearningPathStats(
            total: words.count,
            unseen: unseen,
            previewed: previewed,
            quizReady: quizReady,
            quizPassed: quizPassed,
            deepLearned: deepLearned,
            mastered: mastered,
            readyForQuiz: readyForQuiz,
            needsDeepLearn: needsDeepLearn,
            struggling: struggling
        )
    }

    // MARK: - Recommendations

    /// Get the recommended next action for the user
    func getRecommendation(for words: [Word]) -> LearningRecommendation {
        let stats = getStats(for: words)

        // Priority 1: Struggling words need deep learning
        if stats.struggling > 0 {
            return .deepLearn(count: stats.struggling, reason: "These words need extra attention")
        }

        // Priority 2: Words due for quiz review (spaced repetition)
        let dueForReview = words.filter {
            ($0.learningStage == .quizPassed || $0.learningStage == .deepLearned) && $0.isDueForQuiz
        }.count

        if dueForReview > 0 {
            return .quiz(count: dueForReview, reason: "Keep your memory fresh")
        }

        // Priority 3: Previewed words ready for quiz
        if stats.previewed > 0 {
            return .quiz(count: stats.previewed, reason: "Prove you know these words")
        }

        // Priority 4: Words that passed quiz but need deep learning
        if stats.needsDeepLearn > 0 {
            return .deepLearn(count: stats.needsDeepLearn, reason: "Lock in your knowledge")
        }

        // Priority 5: New words to preview
        if stats.unseen > 0 {
            return .preview(count: min(20, stats.unseen), reason: "Learn new words")
        }

        // All caught up!
        return .allCaughtUp
    }

    // MARK: - Daily Session Builder

    /// Build a daily session configuration with appropriate words for each phase
    /// - Parameters:
    ///   - words: All available words
    ///   - previewCount: Number of new words to preview (default 2-3)
    ///   - quizGoal: Total quiz questions goal (default 5-8)
    /// - Returns: A configured DailySessionConfig
    func buildDailySession(
        from words: [Word],
        previewCount: Int = 3,
        quizGoal: Int = 6
    ) -> DailySessionConfig {
        // 1. Get new words for preview (unseen words)
        let previewWords = Array(getPreviewQueue(from: words, limit: previewCount))

        // 2. Get words for quiz - mix of new previewed and review
        // First, get words due for review (spaced repetition)
        let dueForReview = words.filter {
            ($0.learningStage == .quizPassed || $0.learningStage == .deepLearned) && $0.isDueForQuiz
        }

        // Then get previewed words ready for first quiz
        let readyForFirstQuiz = words.filter {
            $0.learningStage == .previewed || $0.learningStage == .quizReady
        }

        // Combine: prioritize review, then first quiz candidates
        // Include the preview words (they'll be marked as previewed before quiz)
        var quizCandidates = Array(dueForReview.prefix(quizGoal / 2))
        let remainingSlots = quizGoal - quizCandidates.count
        quizCandidates.append(contentsOf: readyForFirstQuiz.prefix(remainingSlots))

        // Add preview words to quiz (they'll be previewed first)
        if quizCandidates.count < quizGoal {
            let additionalFromPreview = previewWords.prefix(quizGoal - quizCandidates.count)
            quizCandidates.append(contentsOf: additionalFromPreview)
        }

        // Shuffle for variety
        let quizWords = quizCandidates.shuffled()

        // 3. Get a word for deep moment (only if there's a struggling word)
        let deepLearnWord = getDeepLearnQueue(from: words, limit: 1).first

        return DailySessionConfig(
            previewWords: previewWords,
            quizWords: Array(quizWords.prefix(quizGoal)),
            deepLearnWord: deepLearnWord
        )
    }

    /// Check if a daily session is available (has content to show)
    func hasDailySessionContent(for words: [Word]) -> Bool {
        let config = buildDailySession(from: words)
        return !config.isEmpty
    }

    /// Get a summary of what the daily session will contain
    func getDailySessionSummary(for words: [Word]) -> (preview: Int, quiz: Int, deepLearn: Bool) {
        let config = buildDailySession(from: words)
        return (
            preview: config.previewWords.count,
            quiz: config.quizWords.count,
            deepLearn: config.deepLearnWord != nil
        )
    }

    // MARK: - Progress Recording

    /// Record that user previewed words
    func recordPreview(words: [Word], modelContext: ModelContext) {
        for word in words {
            word.markPreviewed()
        }
        try? modelContext.save()
    }

    /// Record quiz results
    func recordQuizResults(results: [(word: Word, passed: Bool)], modelContext: ModelContext) {
        for result in results {
            result.word.recordQuizAttempt(passed: result.passed)
        }
        try? modelContext.save()
    }

    /// Record deep learning completion
    func recordDeepLearn(word: Word, confidence: Int, modelContext: ModelContext) {
        word.markDeepLearned(confidence: confidence)
        try? modelContext.save()
    }
}

// MARK: - Supporting Types

struct LearningPathStats {
    let total: Int
    let unseen: Int
    let previewed: Int
    let quizReady: Int
    let quizPassed: Int
    let deepLearned: Int
    let mastered: Int
    let readyForQuiz: Int
    let needsDeepLearn: Int
    let struggling: Int

    var inProgress: Int {
        return previewed + quizReady + quizPassed
    }

    var completionPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(mastered) / Double(total) * 100
    }

    var learningPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(deepLearned + quizPassed) / Double(total) * 100
    }
}

enum LearningRecommendation: Equatable {
    case preview(count: Int, reason: String)
    case quiz(count: Int, reason: String)
    case deepLearn(count: Int, reason: String)
    case allCaughtUp

    var title: String {
        switch self {
        case .preview: return "Preview New Words"
        case .quiz: return "Quiz Yourself"
        case .deepLearn: return "Deep Practice"
        case .allCaughtUp: return "All Caught Up!"
        }
    }

    var icon: String {
        switch self {
        case .preview: return "eye.fill"
        case .quiz: return "questionmark.circle.fill"
        case .deepLearn: return "lightbulb.fill"
        case .allCaughtUp: return "checkmark.seal.fill"
        }
    }

    var color: String {
        switch self {
        case .preview: return "accent"
        case .quiz: return "tertiary"
        case .deepLearn: return "warning"
        case .allCaughtUp: return "success"
        }
    }

    var count: Int {
        switch self {
        case .preview(let count, _): return count
        case .quiz(let count, _): return count
        case .deepLearn(let count, _): return count
        case .allCaughtUp: return 0
        }
    }

    var reason: String {
        switch self {
        case .preview(_, let reason): return reason
        case .quiz(_, let reason): return reason
        case .deepLearn(_, let reason): return reason
        case .allCaughtUp: return "Great work! Come back tomorrow."
        }
    }
}
