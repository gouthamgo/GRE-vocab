import Foundation

enum ResponseQuality: Int {
    case completeBlackout = 0      // Complete failure to recall
    case incorrect = 1              // Incorrect response, but upon seeing correct answer, remembered
    case incorrectEasyRecall = 2    // Incorrect response, but correct answer seemed easy to recall
    case correctDifficult = 3       // Correct response with serious difficulty
    case correctHesitation = 4      // Correct response after hesitation
    case perfectResponse = 5        // Perfect response with no hesitation

    static func fromSwipe(knewIt: Bool) -> ResponseQuality {
        return knewIt ? .correctHesitation : .incorrect
    }
}

class SpacedRepetitionService: SpacedRepetitionServiceProtocol {
    static let shared = SpacedRepetitionService()

    private init() {}

    /// SM-2 Algorithm Implementation
    /// Updates the word's spaced repetition properties based on response quality
    func processResponse(word: Word, quality: ResponseQuality) {
        let q = Double(quality.rawValue)

        // Update ease factor
        // EF' = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
        let newEaseFactor = word.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        word.easeFactor = max(1.3, newEaseFactor) // EF should never go below 1.3

        if quality.rawValue < 3 {
            // If response quality is less than 3, restart repetitions
            word.repetitions = 0
            word.interval = 1
        } else {
            // Successful recall
            word.repetitions += 1

            switch word.repetitions {
            case 1:
                word.interval = 1
            case 2:
                word.interval = 6
            default:
                word.interval = Int(Double(word.interval) * word.easeFactor)
            }
        }

        // Set next review date
        word.lastReviewDate = Date()
        word.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: word.interval,
            to: Date()
        )

        // Update word status based on progress
        if word.repetitions >= 5 {
            word.status = .mastered
        } else if word.repetitions > 0 {
            word.status = .learning
        } else {
            word.status = .new
        }
    }

    /// Process a simple "knew it" or "didn't know it" response
    func processSwipeResponse(word: Word, knewIt: Bool) {
        let quality = ResponseQuality.fromSwipe(knewIt: knewIt)
        processResponse(word: word, quality: quality)
    }

    /// Get words that are due for review, sorted by priority
    func getWordsForReview(from words: [Word], limit: Int = 20) -> [Word] {
        let dueWords = words.filter { $0.isDueForReview }

        // Sort by priority: new words first, then by next review date
        let sorted = dueWords.sorted { word1, word2 in
            // New words have higher priority
            if word1.repetitions == 0 && word2.repetitions > 0 {
                return true
            }
            if word2.repetitions == 0 && word1.repetitions > 0 {
                return false
            }

            // Then sort by next review date (earlier dates first)
            let date1 = word1.nextReviewDate ?? Date.distantPast
            let date2 = word2.nextReviewDate ?? Date.distantPast
            return date1 < date2
        }

        return Array(sorted.prefix(limit))
    }

    /// Calculate estimated time until word is mastered
    func estimatedDaysToMastery(for word: Word) -> Int {
        let remainingReps = max(0, 5 - word.repetitions)
        var totalDays = 0
        var interval = word.interval
        let ef = word.easeFactor

        for i in 0..<remainingReps {
            if word.repetitions + i == 0 {
                interval = 1
            } else if word.repetitions + i == 1 {
                interval = 6
            } else {
                interval = Int(Double(interval) * ef)
            }
            totalDays += interval
        }

        return totalDays
    }
}