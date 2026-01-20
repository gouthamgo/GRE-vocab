import Foundation
import SwiftData

protocol DataServiceProtocol {
    func loadWordsFromJSON() throws -> [WordData]
    func loadWordsFromWordPacks(packIds: [String]?) throws -> [WordData]
    func getAvailableWordPacks() throws -> [WordPackInfo]
    func initializeDataIfNeeded(modelContext: ModelContext)
    func getUserProgress(modelContext: ModelContext) throws -> UserProgress
    func getAllDecks(modelContext: ModelContext) throws -> [Deck]
}
