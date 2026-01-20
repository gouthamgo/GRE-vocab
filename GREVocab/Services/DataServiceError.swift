import Foundation

enum DataServiceError: Error {
    case fileNotFound(String)
    case dataCorrupted
    case decodingError(Error)
    case unknown
}
