import Foundation
import SwiftData

@Model
class Deck {
    var name: String
    var difficulty: Difficulty
    @Relationship(deleteRule: .cascade) var words: [Word] = []

    init(name: String, difficulty: Difficulty, words: [Word] = []) {
        self.name = name
        self.difficulty = difficulty
        self.words = words
    }

    var totalWords: Int { words.count }
    var newCount: Int { words.filter { $0.status == .new }.count }
    var learningCount: Int { words.filter { $0.status == .learning }.count }
    var masteredCount: Int { words.filter { $0.status == .mastered }.count }
    var dueForReviewCount: Int { words.filter { $0.isDueForReview }.count }
    var progress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredCount) / Double(totalWords)
    }
}