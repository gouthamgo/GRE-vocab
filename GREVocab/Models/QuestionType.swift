import Foundation
import SwiftUI

// MARK: - Question Type Enum
enum QuestionType: String, CaseIterable, Identifiable {
    case definitionRecall = "Definition Recall"
    case sentenceCompletion = "Sentence Completion"
    case synonymSelection = "Synonym Selection"
    case antonymSelection = "Antonym Selection"
    case definitionMatch = "Definition Match"
    case wordFromDefinition = "Word from Definition"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .definitionRecall: return "text.cursor"
        case .sentenceCompletion: return "text.insert"
        case .synonymSelection: return "equal.circle"
        case .antonymSelection: return "arrow.left.arrow.right"
        case .definitionMatch: return "arrow.triangle.merge"
        case .wordFromDefinition: return "lightbulb"
        }
    }

    var description: String {
        switch self {
        case .definitionRecall:
            return "Type the definition from memory"
        case .sentenceCompletion:
            return "Fill in the blank with the correct word"
        case .synonymSelection:
            return "Choose the word with similar meaning"
        case .antonymSelection:
            return "Choose the word with opposite meaning"
        case .definitionMatch:
            return "Match the word to its definition"
        case .wordFromDefinition:
            return "Identify the word from its definition"
        }
    }

    var color: Color {
        switch self {
        case .definitionRecall: return AppTheme.Colors.accent
        case .sentenceCompletion: return AppTheme.Colors.success
        case .synonymSelection: return Color.blue
        case .antonymSelection: return Color.orange
        case .definitionMatch: return Color.purple
        case .wordFromDefinition: return Color.pink
        }
    }

    /// Checks if this question type can be used for a given word
    func isAvailable(for word: Word) -> Bool {
        switch self {
        case .definitionRecall, .sentenceCompletion, .definitionMatch, .wordFromDefinition:
            return true
        case .synonymSelection:
            return !word.synonyms.isEmpty
        case .antonymSelection:
            return !word.antonyms.isEmpty
        }
    }

    /// Get available question types for a word
    static func availableTypes(for word: Word) -> [QuestionType] {
        return QuestionType.allCases.filter { $0.isAvailable(for: word) }
    }
}

// MARK: - Question Model
struct ActiveRecallQuestion {
    let word: Word
    let type: QuestionType
    let prompt: String
    let options: [QuestionOption]?
    let correctAnswer: String
    let hint: String?

    struct QuestionOption: Identifiable {
        let id = UUID()
        let text: String
        let isCorrect: Bool
    }
}

// MARK: - Question Generator
class QuestionGenerator {

    /// Generate a question for a word with a specific type
    static func generateQuestion(for word: Word, type: QuestionType, allWords: [Word]) -> ActiveRecallQuestion {
        switch type {
        case .definitionRecall:
            return generateDefinitionRecall(word: word)
        case .sentenceCompletion:
            return generateSentenceCompletion(word: word, allWords: allWords)
        case .synonymSelection:
            return generateSynonymSelection(word: word, allWords: allWords)
        case .antonymSelection:
            return generateAntonymSelection(word: word, allWords: allWords)
        case .definitionMatch:
            return generateDefinitionMatch(word: word, allWords: allWords)
        case .wordFromDefinition:
            return generateWordFromDefinition(word: word, allWords: allWords)
        }
    }

    /// Generate a random question type for a word
    static func generateRandomQuestion(for word: Word, allWords: [Word]) -> ActiveRecallQuestion {
        let availableTypes = QuestionType.availableTypes(for: word)
        let randomType = availableTypes.randomElement() ?? .definitionRecall
        return generateQuestion(for: word, type: randomType, allWords: allWords)
    }

    // MARK: - Question Generators

    private static func generateDefinitionRecall(word: Word) -> ActiveRecallQuestion {
        return ActiveRecallQuestion(
            word: word,
            type: .definitionRecall,
            prompt: "What is the definition of \"\(word.term)\"?",
            options: nil,
            correctAnswer: word.definition,
            hint: word.mnemonicHint
        )
    }

    private static func generateSentenceCompletion(word: Word, allWords: [Word]) -> ActiveRecallQuestion {
        // Create a sentence with the word blanked out
        let sentence = word.exampleSentence
        let blankSentence = sentence.replacingOccurrences(
            of: word.term,
            with: "_____",
            options: .caseInsensitive
        )

        // Generate wrong options from other words
        let wrongWords = allWords
            .filter { $0.term != word.term && $0.partOfSpeech == word.partOfSpeech }
            .shuffled()
            .prefix(3)
            .map { $0.term }

        var options = wrongWords.map { ActiveRecallQuestion.QuestionOption(text: $0, isCorrect: false) }
        options.append(ActiveRecallQuestion.QuestionOption(text: word.term, isCorrect: true))
        options.shuffle()

        return ActiveRecallQuestion(
            word: word,
            type: .sentenceCompletion,
            prompt: blankSentence,
            options: options,
            correctAnswer: word.term,
            hint: "Part of speech: \(word.partOfSpeech)"
        )
    }

    private static func generateSynonymSelection(word: Word, allWords: [Word]) -> ActiveRecallQuestion {
        guard !word.synonyms.isEmpty else {
            return generateDefinitionRecall(word: word)
        }

        let correctSynonym = word.synonyms.randomElement()!

        // Get wrong options - other words that are NOT synonyms
        let wrongWords = allWords
            .filter { $0.term != word.term && !word.synonyms.contains($0.term) }
            .shuffled()
            .prefix(3)
            .map { $0.term }

        var options = wrongWords.map { ActiveRecallQuestion.QuestionOption(text: $0, isCorrect: false) }
        options.append(ActiveRecallQuestion.QuestionOption(text: correctSynonym, isCorrect: true))
        options.shuffle()

        return ActiveRecallQuestion(
            word: word,
            type: .synonymSelection,
            prompt: "Which word is a synonym of \"\(word.term)\"?",
            options: options,
            correctAnswer: correctSynonym,
            hint: word.definition
        )
    }

    private static func generateAntonymSelection(word: Word, allWords: [Word]) -> ActiveRecallQuestion {
        guard !word.antonyms.isEmpty else {
            return generateDefinitionRecall(word: word)
        }

        let correctAntonym = word.antonyms.randomElement()!

        // Get wrong options - use synonyms if available, otherwise random words
        var wrongOptions: [String] = []
        if !word.synonyms.isEmpty {
            wrongOptions.append(contentsOf: word.synonyms.prefix(2))
        }

        let additionalWrong = allWords
            .filter { $0.term != word.term && !word.antonyms.contains($0.term) }
            .shuffled()
            .prefix(3 - wrongOptions.count)
            .map { $0.term }
        wrongOptions.append(contentsOf: additionalWrong)

        var options = wrongOptions.prefix(3).map { ActiveRecallQuestion.QuestionOption(text: $0, isCorrect: false) }
        options.append(ActiveRecallQuestion.QuestionOption(text: correctAntonym, isCorrect: true))
        options.shuffle()

        return ActiveRecallQuestion(
            word: word,
            type: .antonymSelection,
            prompt: "Which word is an antonym of \"\(word.term)\"?",
            options: options,
            correctAnswer: correctAntonym,
            hint: word.definition
        )
    }

    private static func generateDefinitionMatch(word: Word, allWords: [Word]) -> ActiveRecallQuestion {
        // Show the word, pick the correct definition from options
        let wrongDefinitions = allWords
            .filter { $0.term != word.term }
            .shuffled()
            .prefix(3)
            .map { $0.definition }

        var options = wrongDefinitions.map { ActiveRecallQuestion.QuestionOption(text: $0, isCorrect: false) }
        options.append(ActiveRecallQuestion.QuestionOption(text: word.definition, isCorrect: true))
        options.shuffle()

        return ActiveRecallQuestion(
            word: word,
            type: .definitionMatch,
            prompt: "Select the correct definition of \"\(word.term)\":",
            options: options,
            correctAnswer: word.definition,
            hint: word.exampleSentence
        )
    }

    private static func generateWordFromDefinition(word: Word, allWords: [Word]) -> ActiveRecallQuestion {
        // Show the definition, pick the correct word from options
        let wrongWords = allWords
            .filter { $0.term != word.term }
            .shuffled()
            .prefix(3)
            .map { $0.term }

        var options = wrongWords.map { ActiveRecallQuestion.QuestionOption(text: $0, isCorrect: false) }
        options.append(ActiveRecallQuestion.QuestionOption(text: word.term, isCorrect: true))
        options.shuffle()

        return ActiveRecallQuestion(
            word: word,
            type: .wordFromDefinition,
            prompt: word.definition,
            options: options,
            correctAnswer: word.term,
            hint: "Part of speech: \(word.partOfSpeech)"
        )
    }
}

// MARK: - Answer Validation
extension QuestionGenerator {

    /// Validate a text answer for definition recall
    static func validateTextAnswer(userInput: String, correctAnswer: String, questionType: QuestionType) -> AnswerResult {
        let normalizedInput = userInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAnswer = correctAnswer.lowercased()

        // Empty input
        if normalizedInput.isEmpty {
            return AnswerResult(isCorrect: false, score: 0, feedback: "Please enter an answer")
        }

        // Exact match
        if normalizedInput == normalizedAnswer {
            return AnswerResult(isCorrect: true, score: 100, feedback: "Perfect!")
        }

        // Keyword matching for definitions
        if questionType == .definitionRecall {
            let keywords = extractKeywords(from: normalizedAnswer)
            let matchedKeywords = keywords.filter { normalizedInput.contains($0) }
            let matchRatio = Double(matchedKeywords.count) / Double(max(keywords.count, 1))

            if matchRatio >= 0.6 {
                return AnswerResult(
                    isCorrect: true,
                    score: Int(matchRatio * 100),
                    feedback: "Good recall! You captured the key concepts."
                )
            } else if matchRatio >= 0.3 {
                return AnswerResult(
                    isCorrect: false,
                    score: Int(matchRatio * 100),
                    feedback: "Partial understanding. Review the full definition."
                )
            }
        }

        return AnswerResult(isCorrect: false, score: 0, feedback: "Not quite. Keep practicing!")
    }

    private static func extractKeywords(from text: String) -> [String] {
        let stopWords = Set(["a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
                             "to", "of", "in", "for", "on", "with", "at", "by", "from", "or", "and"])
        return text
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
            .filter { $0.count > 2 && !stopWords.contains($0) }
    }
}

// MARK: - Answer Result
struct AnswerResult {
    let isCorrect: Bool
    let score: Int // 0-100
    let feedback: String
}
