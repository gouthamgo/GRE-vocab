import Foundation
import SwiftData
import SwiftUI

// MARK: - Word Pack Manifest
struct WordPackManifest: Codable {
    let version: String
    let totalWords: Int
    let packs: [WordPackInfo]
}

struct WordPackInfo: Codable {
    let id: String
    let name: String
    let filename: String
    let wordCount: Int
    let difficulty: String
    let frequency: String
    let description: String
    let isDefault: Bool
}

class DataService: DataServiceProtocol {
    static let shared = DataService()

    private let maxWordsPerFile = 200 // Safety limit for modular loading

    private init() {}

    /// Load words from modular word packs
    func loadWordsFromWordPacks(packIds: [String]? = nil) throws -> [WordData] {
        let manifest = try loadManifest()
        var allWords: [WordData] = []

        let packsToLoad = packIds == nil
            ? manifest.packs.filter { $0.isDefault }
            : manifest.packs.filter { packIds!.contains($0.id) }

        for pack in packsToLoad {
            let words = try loadWordPack(filename: pack.filename)
            allWords.append(contentsOf: words)
        }

        return allWords
    }

    /// Load manifest file
    private func loadManifest() throws -> WordPackManifest {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "Data/WordPacks") else {
            // Fallback to flat bundle structure
            guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json") else {
                throw DataServiceError.fileNotFound("manifest.json")
            }
            return try decodeJSON(from: url)
        }
        return try decodeJSON(from: url)
    }

    /// Load a single word pack
    private func loadWordPack(filename: String) throws -> [WordData] {
        let name = filename.replacingOccurrences(of: ".json", with: "")

        // Try subdirectory first, then flat bundle
        var url = Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "Data/WordPacks")
        if url == nil {
            url = Bundle.main.url(forResource: name, withExtension: "json")
        }

        guard let finalUrl = url else {
            print("Warning: Word pack \(filename) not found, skipping")
            return []
        }

        return try decodeJSON(from: finalUrl)
    }

    /// Generic JSON decoder helper
    private func decodeJSON<T: Decodable>(from url: URL) throws -> T {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw DataServiceError.decodingError(error)
        } catch {
            throw DataServiceError.unknown
        }
    }

    /// Get available word packs
    func getAvailableWordPacks() throws -> [WordPackInfo] {
        let manifest = try loadManifest()
        return manifest.packs
    }

    /// Load words from legacy JSON file (backward compatibility)
    func loadWordsFromJSON() throws -> [WordData] {
        // First try modular word packs
        do {
            let words = try loadWordsFromWordPacks()
            if !words.isEmpty {
                return words
            }
        } catch {
            print("Modular loading failed, falling back to legacy: \(error)")
        }

        // Fallback to legacy GREWords.json
        guard let url = Bundle.main.url(forResource: "GREWords", withExtension: "json") else {
            throw DataServiceError.fileNotFound("GREWords.json")
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let words = try decoder.decode([WordData].self, from: data)
            return words
        } catch let error as DecodingError {
            throw DataServiceError.decodingError(error)
        } catch {
            throw DataServiceError.unknown
        }
    }

    /// Initialize database with words from JSON if empty
    func initializeDataIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Word>()

        do {
            let existingWords = try modelContext.fetch(descriptor)
            if existingWords.isEmpty {
                populateInitialData(modelContext: modelContext)
            }
        } catch {
            print("Error checking existing words: \(error)")
        }
    }

    /// Populate database with initial vocabulary
    private func populateInitialData(modelContext: ModelContext) {
        do {
            let wordDataList = try loadWordsFromJSON()

            var commonWords: [Word] = []
            var advancedWords: [Word] = []
            var expertWords: [Word] = []

            for wordData in wordDataList {
                let word = wordData.toWord()
                switch word.difficulty {
                case .common:
                    commonWords.append(word)
                case .advanced:
                    advancedWords.append(word)
                case .expert:
                    expertWords.append(word)
                }
            }

            let commonDeck = Deck(name: "Common", difficulty: .common, words: commonWords)
            let advancedDeck = Deck(name: "Advanced", difficulty: .advanced, words: advancedWords)
            let expertDeck = Deck(name: "Expert", difficulty: .expert, words: expertWords)

            modelContext.insert(commonDeck)
            modelContext.insert(advancedDeck)
            modelContext.insert(expertDeck)

            let progress = UserProgress()
            modelContext.insert(progress)

            try modelContext.save()
        } catch {
            print("Error populating initial data: \(error)")
        }
    }

    /// Get or create user progress
    func getUserProgress(modelContext: ModelContext) throws -> UserProgress {
        let descriptor = FetchDescriptor<UserProgress>()

        do {
            let results = try modelContext.fetch(descriptor)
            if let progress = results.first {
                return progress
            } else {
                let newProgress = UserProgress()
                modelContext.insert(newProgress)
                try modelContext.save()
                return newProgress
            }
        } catch {
            throw DataServiceError.unknown
        }
    }

    /// Get all decks sorted by difficulty
    func getAllDecks(modelContext: ModelContext) throws -> [Deck] {
        let descriptor = FetchDescriptor<Deck>()

        do {
            let decks = try modelContext.fetch(descriptor)
            // Sort by difficulty: Common -> Advanced -> Expert
            return decks.sorted { deck1, deck2 in
                let order: [Difficulty] = [.common, .advanced, .expert]
                let index1 = order.firstIndex(of: deck1.difficulty) ?? 0
                let index2 = order.firstIndex(of: deck2.difficulty) ?? 0
                return index1 < index2
            }
        } catch {
            throw DataServiceError.unknown
        }
    }
}

struct WordData: Codable {
    let term: String
    let definition: String
    let partOfSpeech: String
    let exampleSentence: String
    let difficulty: String

    // Enhanced fields (optional for backward compatibility)
    let synonyms: [String]?
    let antonyms: [String]?
    let mnemonicHint: String?
    let rootWord: String?
    let rootMeaning: String?
    let relatedWords: [String]?
    let usageNotes: String?
    let frequency: String?
    let source: String?

    func toWord() -> Word {
        let diff = Difficulty(rawValue: difficulty) ?? .common
        let freq = FrequencyTier(rawValue: frequency ?? "Common") ?? .common
        let src = WordSource(rawValue: source ?? "Custom") ?? .custom

        return Word(
            term: term,
            definition: definition,
            partOfSpeech: partOfSpeech,
            exampleSentence: exampleSentence,
            difficulty: diff,
            synonyms: synonyms ?? [],
            antonyms: antonyms ?? [],
            mnemonicHint: mnemonicHint,
            rootWord: rootWord,
            rootMeaning: rootMeaning,
            relatedWords: relatedWords ?? [],
            usageNotes: usageNotes,
            frequency: freq,
            source: src
        )
    }
}
