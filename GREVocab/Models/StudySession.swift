import Foundation
import SwiftData

@Model
class StudySession {
    var id: UUID
    var date: Date
    var wordsStudied: Int
    var correctCount: Int
    var incorrectCount: Int
    var sessionType: String // "review", "deck", "feynman", "quiz"
    var deckName: String?
    var duration: TimeInterval
    var questionTypes: [String] // Track which question types were used

    init(
        sessionType: String = "review",
        deckName: String? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.wordsStudied = 0
        self.correctCount = 0
        self.incorrectCount = 0
        self.sessionType = sessionType
        self.deckName = deckName
        self.duration = 0
        self.questionTypes = []
    }

    var accuracy: Double {
        guard wordsStudied > 0 else { return 0 }
        return Double(correctCount) / Double(wordsStudied) * 100
    }

    func recordAnswer(correct: Bool) {
        wordsStudied += 1
        if correct {
            correctCount += 1
        } else {
            incorrectCount += 1
        }
    }
}

// MARK: - Session Type
enum SessionType: String, Codable, CaseIterable {
    case review = "review"
    case deck = "deck"
    case feynman = "feynman"
    case quiz = "quiz"
    case challenge = "challenge"

    var displayName: String {
        switch self {
        case .review: return "Review"
        case .deck: return "Deck Study"
        case .feynman: return "Feynman Mode"
        case .quiz: return "Quiz"
        case .challenge: return "Challenge"
        }
    }

    var icon: String {
        switch self {
        case .review: return "arrow.clockwise"
        case .deck: return "rectangle.stack"
        case .feynman: return "lightbulb"
        case .quiz: return "questionmark.circle"
        case .challenge: return "flame"
        }
    }
}
