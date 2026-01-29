import Foundation
import SwiftUI

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Basic"
    case medium = "Common"
    case hard = "Advanced"

    var displayName: String {
        rawValue
    }

    var themeColor: Color {
        switch self {
        case .easy: return AppTheme.Colors.success
        case .medium: return AppTheme.Colors.warning
        case .hard: return AppTheme.Colors.error
        }
    }

    var icon: String {
        switch self {
        case .easy: return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.fill"
        }
    }

    /// Whether this difficulty level requires premium subscription
    var isPremium: Bool {
        switch self {
        case .easy: return false
        case .medium, .hard: return false // All free for now
        }
    }
}

enum WordStatus: String, Codable {
    case new
    case learning
    case mastered
}

// MARK: - Learning Stage
/// Tracks where user is in the learning path: Preview → Quiz → DeepLearn
enum LearningStage: String, Codable, CaseIterable {
    case unseen = "unseen"           // Never encountered
    case previewed = "previewed"     // Saw in preview/flashcard mode
    case quizReady = "quizReady"     // Ready to be quizzed
    case quizPassed = "quizPassed"   // Passed quiz at least once
    case deepLearned = "deepLearned" // Completed Feynman mode

    var displayName: String {
        switch self {
        case .unseen: return "New"
        case .previewed: return "Previewed"
        case .quizReady: return "Quiz Ready"
        case .quizPassed: return "Quiz Passed"
        case .deepLearned: return "Deep Learned"
        }
    }

    var icon: String {
        switch self {
        case .unseen: return "sparkles"
        case .previewed: return "eye.fill"
        case .quizReady: return "questionmark.circle"
        case .quizPassed: return "checkmark.circle.fill"
        case .deepLearned: return "lightbulb.fill"
        }
    }

    var color: Color {
        switch self {
        case .unseen: return AppTheme.Colors.textTertiary
        case .previewed: return AppTheme.Colors.accent.opacity(0.6)
        case .quizReady: return AppTheme.Colors.tertiary
        case .quizPassed: return AppTheme.Colors.success.opacity(0.7)
        case .deepLearned: return AppTheme.Colors.warning
        }
    }

    /// The next stage in the learning path
    var nextStage: LearningStage? {
        switch self {
        case .unseen: return .previewed
        case .previewed: return .quizReady
        case .quizReady: return .quizPassed
        case .quizPassed: return .deepLearned
        case .deepLearned: return nil
        }
    }

    /// Whether this stage counts toward mastery
    var contributesToMastery: Bool {
        switch self {
        case .unseen, .previewed, .quizReady: return false
        case .quizPassed, .deepLearned: return true
        }
    }
}
