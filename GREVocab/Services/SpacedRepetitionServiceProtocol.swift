import Foundation

protocol SpacedRepetitionServiceProtocol {
    func processResponse(word: Word, quality: ResponseQuality)
    func processSwipeResponse(word: Word, knewIt: Bool)
    func getWordsForReview(from words: [Word], limit: Int) -> [Word]
    func estimatedDaysToMastery(for word: Word) -> Int
}
