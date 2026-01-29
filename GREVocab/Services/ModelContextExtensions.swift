import Foundation
import SwiftData
import os.log

// MARK: - Safe Save Extension for ModelContext
extension ModelContext {
    /// Logger for ModelContext operations
    private static let logger = Logger(subsystem: "com.ganguly.GREVocab", category: "ModelContext")

    /// Safely save the context with proper error handling and logging
    /// - Parameter operation: Description of the operation being performed (for logging)
    /// - Throws: The underlying save error if save fails
    func safeSave(operation: String = "unknown") throws {
        do {
            try save()
        } catch {
            Self.logger.error("Failed to save ModelContext during '\(operation)': \(error.localizedDescription)")
            throw error
        }
    }

    /// Attempt to save the context, logging any errors but not throwing
    /// Use this only for non-critical operations where failure is acceptable
    /// - Parameter operation: Description of the operation being performed (for logging)
    /// - Returns: True if save succeeded, false otherwise
    @discardableResult
    func trySave(operation: String = "unknown") -> Bool {
        do {
            try save()
            return true
        } catch {
            Self.logger.warning("Non-critical save failed during '\(operation)': \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Data Integrity Error
enum DataIntegrityError: LocalizedError {
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case corruptedData(String)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .corruptedData(let details):
            return "Data integrity issue: \(details)"
        }
    }
}
