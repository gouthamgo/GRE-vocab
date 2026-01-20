import Foundation

struct InputWord: Codable {
    let word: String
    let meaning: String
}

struct InputJSON: Codable {
    let words: [InputWord]
    let advanced_words: [InputWord]
}

struct WordData: Codable {
    let term: String
    let definition: String
    let partOfSpeech: String
    let exampleSentence: String
    let difficulty: String
}

let tempFileURL = URL(fileURLWithPath: "temp_word_list.json")
let outputURL = URL(fileURLWithPath: "GREVocab/Data/GREWords.json")

do {
    let data = try Data(contentsOf: tempFileURL)
    let decoder = JSONDecoder()
    let inputJSON = try decoder.decode(InputJSON.self, from: data)

    var wordDataList: [WordData] = []

    // Process common words
    for word in inputJSON.words {
        wordDataList.append(WordData(term: word.word,
                                     definition: word.meaning,
                                     partOfSpeech: "n.",
                                     exampleSentence: "This is an example sentence.",
                                     difficulty: "Common"))
    }

    // Process advanced words
    for word in inputJSON.advanced_words {
        wordDataList.append(WordData(term: word.word,
                                     definition: word.meaning,
                                     partOfSpeech: "n.",
                                     exampleSentence: "This is an example sentence.",
                                     difficulty: "Advanced"))
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    let newData = try encoder.encode(wordDataList)
    try newData.write(to: outputURL)

    print("Successfully converted word list.")
} catch {
    print("Error converting word list: \(error)")
}
