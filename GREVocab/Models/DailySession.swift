import Foundation
import SwiftData

// MARK: - Session Phase
/// Tracks the current phase within a daily session
enum SessionPhase: String, CaseIterable {
    case preview
    case quiz
    case deepMoment
    case complete

    var displayName: String {
        switch self {
        case .preview: return "New Words"
        case .quiz: return "Quiz"
        case .deepMoment: return "Deep Moment"
        case .complete: return "Complete"
        }
    }

    var icon: String {
        switch self {
        case .preview: return "eye.fill"
        case .quiz: return "questionmark.circle.fill"
        case .deepMoment: return "lightbulb.fill"
        case .complete: return "checkmark.seal.fill"
        }
    }

    /// Progress percentage at the start of this phase
    var progressStart: Double {
        switch self {
        case .preview: return 0.0
        case .quiz: return 0.2
        case .deepMoment: return 0.8
        case .complete: return 1.0
        }
    }
}

// MARK: - Daily Session Configuration
/// Configuration for a daily learning session
struct DailySessionConfig: Identifiable {
    let id = UUID()
    let previewWords: [Word]
    let quizWords: [Word]
    let deepLearnWord: Word?

    /// Total number of items in the session
    var totalItems: Int {
        previewWords.count + quizWords.count + (deepLearnWord != nil ? 1 : 0)
    }

    /// Whether the session has any content
    var isEmpty: Bool {
        previewWords.isEmpty && quizWords.isEmpty && deepLearnWord == nil
    }

    /// Whether preview phase should be shown
    var hasPreviewPhase: Bool {
        !previewWords.isEmpty
    }

    /// Whether quiz phase should be shown
    var hasQuizPhase: Bool {
        !quizWords.isEmpty
    }

    /// Whether deep moment phase should be shown
    var hasDeepMomentPhase: Bool {
        deepLearnWord != nil
    }
}

// MARK: - Session Statistics
/// Tracks statistics during a daily session
struct DailySessionStats {
    var wordsPreviewd: Int = 0
    var quizCorrect: Int = 0
    var quizIncorrect: Int = 0
    var deepMomentCompleted: Bool = false
    var deepMomentCorrect: Bool = false

    var totalQuestions: Int {
        quizCorrect + quizIncorrect
    }

    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(quizCorrect) / Double(totalQuestions) * 100
    }

    var totalWordsLearned: Int {
        wordsPreviewd + quizCorrect + (deepMomentCorrect ? 1 : 0)
    }
}

// MARK: - Deep Moment Question
/// A simplified deep learning question with multiple choice options
struct DeepMomentQuestion {
    let word: Word
    let prompt: String
    let options: [DeepMomentOption]
    let correctExplanation: String

    struct DeepMomentOption: Identifiable {
        let id = UUID()
        let text: String
        let isCorrect: Bool
    }
}

// MARK: - Deep Moment Generator
class DeepMomentGenerator {

    /// Generate a deep moment question for a struggling word
    static func generateQuestion(for word: Word) -> DeepMomentQuestion {
        // Create explanation options based on the word
        let correctExplanation = generateCorrectExplanation(for: word)
        let wrongExplanations = generateWrongExplanations(for: word)

        var options = wrongExplanations.map {
            DeepMomentQuestion.DeepMomentOption(text: $0, isCorrect: false)
        }
        options.append(DeepMomentQuestion.DeepMomentOption(text: correctExplanation, isCorrect: true))
        options.shuffle()

        return DeepMomentQuestion(
            word: word,
            prompt: "Which explanation best captures the meaning of \"\(word.term)\"?",
            options: options,
            correctExplanation: correctExplanation
        )
    }

    private static func generateCorrectExplanation(for word: Word) -> String {
        // Use the definition as the base for the correct explanation
        // Slightly rephrase it if possible
        let definition = word.definition

        // If there's a mnemonic hint, incorporate it
        if let mnemonic = word.mnemonicHint, !mnemonic.isEmpty {
            return "\(definition) (Think: \(mnemonic))"
        }

        return definition
    }

    private static func generateWrongExplanations(for word: Word) -> [String] {
        var wrong: [String] = []

        // Use antonyms if available to create a wrong explanation
        if !word.antonyms.isEmpty, let antonym = word.antonyms.first {
            wrong.append("Similar in meaning to \"\(antonym)\"")
        }

        // Create a plausible but wrong explanation
        let partOfSpeech = word.partOfSpeech
        switch partOfSpeech.lowercased() {
        case "noun":
            wrong.append("A type of action or behavior")
            wrong.append("A descriptive quality or characteristic")
        case "verb":
            wrong.append("A person, place, or thing")
            wrong.append("A quality used to describe something")
        case "adjective":
            wrong.append("An action word describing movement")
            wrong.append("A specific person or location")
        case "adverb":
            wrong.append("A physical object or item")
            wrong.append("A state of being or existence")
        default:
            wrong.append("The opposite meaning of what it actually is")
            wrong.append("A common misconception about this word")
        }

        // Ensure we have exactly 3 wrong options
        while wrong.count < 3 {
            wrong.append("A word with an unrelated meaning")
        }

        return Array(wrong.prefix(3))
    }
}
