import Foundation
import SwiftData
import SwiftUI

@Observable
class DeckViewModel {
    var decks: [Deck] = []
    var selectedDifficulty: Difficulty?
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
    }

    var filteredDecks: [Deck] {
        if let difficulty = selectedDifficulty {
            return decks.filter { $0.difficulty == difficulty }
        }
        return decks
    }



    var basicDecks: [Deck] {
        decks.filter { $0.difficulty == .easy }
    }

    var commonDecks: [Deck] {
        decks.filter { $0.difficulty == .medium }
    }

    var advancedDecks: [Deck] {
        decks.filter { $0.difficulty == .hard }
    }

    var totalWords: Int {
        decks.reduce(0) { $0 + $1.totalWords }
    }

    var totalMastered: Int {
        decks.reduce(0) { $0 + $1.masteredCount }
    }

    var totalNew: Int {
        decks.reduce(0) { $0 + $1.newCount }
    }

    var totalLearning: Int {
        decks.reduce(0) { $0 + $1.learningCount }
    }

    var overallProgress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(totalMastered) / Double(totalWords)
    }

    func loadDecks(modelContext: ModelContext) {
        do {
            decks = try dataService.getAllDecks(modelContext: modelContext)
        } catch {
            print("Error loading decks: \(error)")
        }
    }
}