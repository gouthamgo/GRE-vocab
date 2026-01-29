import Foundation
import SwiftUI

// MARK: - Input Validation Utilities
enum InputValidation {
    // MARK: - Constants
    /// Maximum length for user explanation text fields
    static let maxExplanationLength = 1000

    /// Maximum length for user example sentences
    static let maxExampleLength = 500

    /// Maximum length for quiz answer input
    static let maxQuizAnswerLength = 200

    /// Maximum length for search queries
    static let maxSearchQueryLength = 100

    // MARK: - Validation Functions

    /// Sanitize text input by trimming whitespace and limiting length
    /// - Parameters:
    ///   - text: The input text to sanitize
    ///   - maxLength: Maximum allowed length
    /// - Returns: Sanitized text
    static func sanitize(_ text: String, maxLength: Int) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > maxLength {
            return String(trimmed.prefix(maxLength))
        }
        return trimmed
    }

    /// Validate that text is not empty after trimming
    static func isNotEmpty(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Check if text contains potentially dangerous characters
    /// (For future use if we add backend/API integration)
    static func containsSuspiciousPatterns(_ text: String) -> Bool {
        let suspiciousPatterns = [
            "<script",
            "javascript:",
            "data:",
            "onclick",
            "onerror",
            "onload"
        ]

        let lowercased = text.lowercased()
        return suspiciousPatterns.contains { lowercased.contains($0) }
    }

    /// Sanitize text for safe display (strip HTML tags)
    static func stripHtmlTags(_ text: String) -> String {
        text.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression,
            range: nil
        )
    }
}

// MARK: - View Modifier for Limited Text Input
struct LimitedTextFieldModifier: ViewModifier {
    @Binding var text: String
    let maxLength: Int

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { _, newValue in
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
    }
}

extension View {
    /// Limit text field input to a maximum length
    func limitText(_ binding: Binding<String>, to maxLength: Int) -> some View {
        modifier(LimitedTextFieldModifier(text: binding, maxLength: maxLength))
    }
}

// MARK: - Secure Text Storage (for future use)
/// Helper to validate data before persistence
enum DataValidation {
    /// Validate word data before saving
    static func validateWord(term: String, definition: String) -> Result<Void, ValidationError> {
        if term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure(.emptyField("term"))
        }
        if definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .failure(.emptyField("definition"))
        }
        if term.count > 100 {
            return .failure(.tooLong("term", maxLength: 100))
        }
        if definition.count > 500 {
            return .failure(.tooLong("definition", maxLength: 500))
        }
        return .success(())
    }

    enum ValidationError: LocalizedError {
        case emptyField(String)
        case tooLong(String, maxLength: Int)
        case invalidFormat(String)

        var errorDescription: String? {
            switch self {
            case .emptyField(let field):
                return "\(field.capitalized) cannot be empty"
            case .tooLong(let field, let maxLength):
                return "\(field.capitalized) is too long (max \(maxLength) characters)"
            case .invalidFormat(let field):
                return "\(field.capitalized) has an invalid format"
            }
        }
    }
}
