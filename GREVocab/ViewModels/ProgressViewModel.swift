import Foundation
import SwiftData
import SwiftUI

// MARK: - Timeframe Enum
enum StatsTimeframe: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case all = "All Time"

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: Date())
        case .all:
            return nil
        }
    }
}

@Observable
class ProgressViewModel {
    var userProgress: UserProgress?
    var decks: [Deck] = []
    var studySessions: [StudySession] = []
    var selectedTimeframe: StatsTimeframe = .week
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
    }

    var totalWords: Int {
        decks.reduce(0) { $0 + $1.totalWords }
    }

    var masteredWords: Int {
        decks.reduce(0) { $0 + $1.masteredCount }
    }

    var learningWords: Int {
        decks.reduce(0) { $0 + $1.learningCount }
    }

    var newWords: Int {
        decks.reduce(0) { $0 + $1.newCount }
    }

    var dueForReview: Int {
        decks.reduce(0) { $0 + $1.dueForReviewCount }
    }

    var overallProgress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }

    // MARK: - Learning Path Statistics

    /// Words never seen
    var unseenWords: Int {
        allWords.filter { $0.learningStage == .unseen }.count
    }

    /// Words previewed but not yet quizzed
    var previewedWords: Int {
        allWords.filter { $0.learningStage == .previewed }.count
    }

    /// Words that passed quiz at least once
    var quizPassedWords: Int {
        allWords.filter { $0.learningStage == .quizPassed }.count
    }

    /// Words that completed deep learning
    var deepLearnedWords: Int {
        allWords.filter { $0.learningStage == .deepLearned }.count
    }

    /// Words ready for quiz (previewed or quiz-ready)
    var quizReadyWords: Int {
        allWords.filter { $0.learningStage == .previewed || $0.learningStage == .quizReady }.count
    }

    /// Words that need deep learning (struggling or passed but not deep learned)
    var needsDeepLearnWords: Int {
        allWords.filter { $0.needsDeepLearning }.count
    }

    /// Words struggling (failed quiz 2+ times)
    var strugglingWords: Int {
        allWords.filter { $0.timesQuizFailed >= 2 }.count
    }

    /// Words due for quiz review (spaced repetition)
    var dueForQuizReview: Int {
        allWords.filter { $0.isDueForQuiz && $0.quizPassCount > 0 }.count
    }

    /// Learning path progress percentage
    var learningPathProgress: Double {
        guard totalWords > 0 else { return 0 }
        // Weight: unseen=0, previewed=0.2, quizPassed=0.6, deepLearned=1.0
        let score = allWords.reduce(0.0) { $0 + $1.learningPathProgress }
        return score / Double(totalWords)
    }

    // MARK: - Time-filtered Statistics

    var filteredSessions: [StudySession] {
        guard let startDate = selectedTimeframe.startDate else {
            return studySessions
        }
        return studySessions.filter { $0.date >= startDate }
    }

    var filteredWordsStudied: Int {
        filteredSessions.reduce(0) { $0 + $1.wordsStudied }
    }

    var filteredCorrectCount: Int {
        filteredSessions.reduce(0) { $0 + $1.correctCount }
    }

    var filteredIncorrectCount: Int {
        filteredSessions.reduce(0) { $0 + $1.incorrectCount }
    }

    var filteredAccuracy: Double {
        let total = filteredWordsStudied
        guard total > 0 else { return 0 }
        return Double(filteredCorrectCount) / Double(total) * 100
    }

    var filteredSessionsCount: Int {
        filteredSessions.count
    }

    var filteredStudyTime: TimeInterval {
        filteredSessions.reduce(0) { $0 + $1.duration }
    }

    var formattedFilteredStudyTime: String {
        let totalSeconds = Int(filteredStudyTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var averageSessionAccuracy: Double {
        guard !filteredSessions.isEmpty else { return 0 }
        let totalAccuracy = filteredSessions.reduce(0.0) { $0 + $1.accuracy }
        return totalAccuracy / Double(filteredSessions.count)
    }

    // MARK: - Chart Data

    /// Data point for the activity chart
    struct DailyActivityData: Identifiable {
        let id = UUID()
        let date: Date
        let wordsStudied: Int
        let accuracy: Double

        var dayLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }

    /// Get daily activity data for the past 7 days
    var weeklyActivityData: [DailyActivityData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let daySessions = studySessions.filter {
                $0.date >= dayStart && $0.date < dayEnd
            }

            let wordsStudied = daySessions.reduce(0) { $0 + $1.wordsStudied }
            let totalCorrect = daySessions.reduce(0) { $0 + $1.correctCount }
            let accuracy = wordsStudied > 0 ? Double(totalCorrect) / Double(wordsStudied) * 100 : 0

            return DailyActivityData(date: date, wordsStudied: wordsStudied, accuracy: accuracy)
        }
    }

    // MARK: - Difficult Words

    var allWords: [Word] = []

    /// Words that the user struggles with most (low ease factor, high error rate)
    var difficultWords: [Word] {
        allWords
            .filter { $0.timesReviewed >= 2 } // Only include words that have been reviewed
            .sorted { word1, word2 in
                // Sort by error rate (lower accuracy = more difficult)
                let accuracy1 = word1.timesReviewed > 0 ? Double(word1.timesCorrect) / Double(word1.timesReviewed) : 1.0
                let accuracy2 = word2.timesReviewed > 0 ? Double(word2.timesCorrect) / Double(word2.timesReviewed) : 1.0

                if accuracy1 != accuracy2 {
                    return accuracy1 < accuracy2 // Lower accuracy = more difficult
                }
                // Secondary sort by ease factor
                return word1.easeFactor < word2.easeFactor
            }
            .prefix(10)
            .map { $0 }
    }

    func load(modelContext: ModelContext) {
        do {
            userProgress = try dataService.getUserProgress(modelContext: modelContext)
        } catch {
            print("Error loading user progress: \(error)")
        }

        let deckDescriptor = FetchDescriptor<Deck>()
        do {
            decks = try modelContext.fetch(deckDescriptor)
        } catch {
            print("Error loading decks: \(error)")
        }

        // Load study sessions
        let sessionDescriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        do {
            studySessions = try modelContext.fetch(sessionDescriptor)
        } catch {
            print("Error loading study sessions: \(error)")
        }

        // Load all words for difficult words analysis
        let wordDescriptor = FetchDescriptor<Word>()
        do {
            allWords = try modelContext.fetch(wordDescriptor)
        } catch {
            print("Error loading words: \(error)")
        }
    }
}