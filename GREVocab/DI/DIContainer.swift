import Foundation

class DIContainer: ObservableObject {
    let dataService: DataServiceProtocol
    let spacedRepetitionService: SpacedRepetitionServiceProtocol
    let textToSpeechService: TextToSpeechServiceProtocol

    init(dataService: DataServiceProtocol = DataService.shared,
         spacedRepetitionService: SpacedRepetitionServiceProtocol = SpacedRepetitionService.shared,
         textToSpeechService: TextToSpeechServiceProtocol = TextToSpeechService.shared) {
        self.dataService = dataService
        self.spacedRepetitionService = spacedRepetitionService
        self.textToSpeechService = textToSpeechService
    }
}
