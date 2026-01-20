import Foundation
import SwiftData
import SwiftUI

// Track status changes for session summary
struct WordStatusChange: Identifiable {
    let id = UUID()
    let word: Word
    let previousStatus: WordStatus
    let newStatus: WordStatus
    let previousRepetitions: Int
    let newRepetitions: Int

    var leveledUp: Bool {
        return newRepetitions > previousRepetitions
    }

    var justMastered: Bool {
        return previousStatus != .mastered && newStatus == .mastered
    }

    var startedLearning: Bool {
        return previousStatus == .new && newStatus == .learning
    }
}

@Observable
class FlashcardViewModel {
    var currentDeck: Deck?
    var studyWords: [Word] = []
    var currentIndex: Int = 0
    var isShowingDefinition: Bool = false
    var sessionCorrect: Int = 0
    var sessionIncorrect: Int = 0
    var isSessionComplete: Bool = false

    // Session tracking for summary
    var statusChanges: [WordStatusChange] = []
    var strugglingWords: [Word] = [] // Words answered wrong 2+ times this session
    private var wordWrongCounts: [String: Int] = [:] // Track wrong answers per word

    private let spacedRepetitionService: SpacedRepetitionServiceProtocol
    private let textToSpeechService: TextToSpeechServiceProtocol

    init(spacedRepetitionService: SpacedRepetitionServiceProtocol = SpacedRepetitionService.shared, textToSpeechService: TextToSpeechServiceProtocol = TextToSpeechService.shared) {
        self.spacedRepetitionService = spacedRepetitionService
        self.textToSpeechService = textToSpeechService
    }

    var currentWord: Word? {
        guard currentIndex < studyWords.count else { return nil }
        return studyWords[currentIndex]
    }

    var progress: Double {
        guard !studyWords.isEmpty else { return 0 }
        return Double(currentIndex) / Double(studyWords.count)
    }

    var remainingWords: Int {
        max(0, studyWords.count - currentIndex)
    }

    func startSession(deck: Deck) {
        currentDeck = deck
        studyWords = spacedRepetitionService.getWordsForReview(
            from: deck.words,
            limit: 20
        )
        resetSessionTracking()
    }

    func startReviewSession(from decks: [Deck]) {
        let allWords = decks.flatMap { $0.words }
        studyWords = getSmartStudyWords(from: allWords, limit: 20)
        resetSessionTracking()
    }

    private func resetSessionTracking() {
        currentIndex = 0
        sessionCorrect = 0
        sessionIncorrect = 0
        isShowingDefinition = false
        isSessionComplete = false
        statusChanges = []
        strugglingWords = []
        wordWrongCounts = [:]
    }

    /// Smart word selection that prioritizes:
    /// 1. Due words (nextReviewDate < now)
    /// 2. Learning words (0 < repetitions < 5)
    /// 3. New words (to fill daily goal)
    func getSmartStudyWords(from allWords: [Word], limit: Int = 20) -> [Word] {
        let now = Date()
        var selectedWords: [Word] = []

        // Priority 1: Due words (scheduled for review)
        let dueWords = allWords.filter { word in
            if let nextReview = word.nextReviewDate {
                return nextReview <= now
            }
            return false
        }.sorted { word1, word2 in
            // Sort by how overdue they are (most overdue first)
            guard let date1 = word1.nextReviewDate, let date2 = word2.nextReviewDate else {
                return false
            }
            return date1 < date2
        }
        selectedWords.append(contentsOf: dueWords.prefix(limit))

        // Priority 2: Learning words (started but not mastered)
        if selectedWords.count < limit {
            let learningWords = allWords.filter { word in
                word.status == .learning && !selectedWords.contains { $0.id == word.id }
            }.sorted { word1, word2 in
                // Sort by repetitions (fewer repetitions = needs more practice)
                word1.repetitions < word2.repetitions
            }
            let needed = limit - selectedWords.count
            selectedWords.append(contentsOf: learningWords.prefix(needed))
        }

        // Priority 3: New words (to fill remaining slots)
        if selectedWords.count < limit {
            let newWords = allWords.filter { word in
                word.status == .new && !selectedWords.contains { $0.id == word.id }
            }.shuffled() // Randomize new words for variety
            let needed = limit - selectedWords.count
            selectedWords.append(contentsOf: newWords.prefix(needed))
        }

        // Shuffle the final selection for a good mix during study
        return selectedWords.shuffled()
    }

    func flipCard() {
        isShowingDefinition.toggle()
    }

    func processResponse(knewIt: Bool, userProgress: UserProgress) {
        guard let word = currentWord else { return }

        // Capture state before processing
        let previousStatus = word.status
        let previousRepetitions = word.repetitions

        // Process the response
        spacedRepetitionService.processSwipeResponse(word: word, knewIt: knewIt)
        userProgress.recordStudy(correct: knewIt)

        // Track status change
        let statusChange = WordStatusChange(
            word: word,
            previousStatus: previousStatus,
            newStatus: word.status,
            previousRepetitions: previousRepetitions,
            newRepetitions: word.repetitions
        )
        statusChanges.append(statusChange)

        // Track correct/incorrect
        if knewIt {
            sessionCorrect += 1
        } else {
            sessionIncorrect += 1
            // Track struggling words
            let count = (wordWrongCounts[word.term] ?? 0) + 1
            wordWrongCounts[word.term] = count
            if count >= 2 && !strugglingWords.contains(where: { $0.id == word.id }) {
                strugglingWords.append(word)
            }
        }

        moveToNextWord()
    }

    // Session summary computed properties
    var wordsMastered: [Word] {
        statusChanges.filter { $0.justMastered }.map { $0.word }
    }

    var wordsLeveledUp: [WordStatusChange] {
        statusChanges.filter { $0.leveledUp && !$0.justMastered }
    }

    var wordsStartedLearning: [Word] {
        statusChanges.filter { $0.startedLearning }.map { $0.word }
    }

    var hasStrugglingWords: Bool {
        !strugglingWords.isEmpty
    }

    private func moveToNextWord() {
        isShowingDefinition = false

        if currentIndex + 1 >= studyWords.count {
            isSessionComplete = true
        } else {
            currentIndex += 1
        }
    }

    func restartSession() {
        if let deck = currentDeck {
            startSession(deck: deck)
        }
    }

    func checkAnswer(userInput: String, word: Word) -> Bool {
        // Simple keyword matching for now
        let keywords = word.definition.lowercased().split(separator: " ").filter { !$0.isEmpty && $0.count > 3 }
        let lowercasedInput = userInput.lowercased()

        for keyword in keywords {
            if lowercasedInput.contains(keyword) {
                return true
            }
        }
        return false
    }
}