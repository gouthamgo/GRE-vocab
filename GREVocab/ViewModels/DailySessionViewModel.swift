import Foundation
import SwiftData
import SwiftUI

/// ViewModel managing the state and logic for a Daily Session
@Observable
class DailySessionViewModel {
    // MARK: - Session Configuration
    var config: DailySessionConfig

    // MARK: - Current Phase State
    var currentPhase: SessionPhase = .preview
    var stats: DailySessionStats = DailySessionStats()

    // MARK: - Preview Phase State
    var previewIndex: Int = 0
    var isCardFlipped: Bool = false

    // MARK: - Quiz Phase State
    var quizIndex: Int = 0
    var currentQuestion: ActiveRecallQuestion?
    var selectedOption: ActiveRecallQuestion.QuestionOption?
    var userTextInput: String = ""
    var showingQuizAnswer: Bool = false
    var quizAnswerResult: AnswerResult?

    // MARK: - Deep Moment State
    var deepMomentQuestion: DeepMomentQuestion?
    var selectedDeepOption: DeepMomentQuestion.DeepMomentOption?
    var showingDeepAnswer: Bool = false
    var deepAnswerCorrect: Bool = false

    // MARK: - Animation State
    var cardScale: CGFloat = 1.0
    var cardOpacity: Double = 1.0

    // MARK: - Computed Properties

    /// Current word being previewed
    var currentPreviewWord: Word? {
        guard previewIndex < config.previewWords.count else { return nil }
        return config.previewWords[previewIndex]
    }

    /// Current word being quizzed
    var currentQuizWord: Word? {
        guard quizIndex < config.quizWords.count else { return nil }
        return config.quizWords[quizIndex]
    }

    /// Overall progress through the session (0.0 to 1.0)
    var overallProgress: Double {
        switch currentPhase {
        case .preview:
            let previewProgress = config.previewWords.isEmpty ? 0 :
                Double(previewIndex) / Double(config.previewWords.count)
            return previewProgress * 0.2
        case .quiz:
            let quizProgress = config.quizWords.isEmpty ? 0 :
                Double(quizIndex) / Double(config.quizWords.count)
            return 0.2 + (quizProgress * 0.6)
        case .deepMoment:
            return showingDeepAnswer ? 0.95 : 0.85
        case .complete:
            return 1.0
        }
    }

    /// Progress within current phase (0.0 to 1.0)
    var phaseProgress: Double {
        switch currentPhase {
        case .preview:
            guard !config.previewWords.isEmpty else { return 1.0 }
            return Double(previewIndex) / Double(config.previewWords.count)
        case .quiz:
            guard !config.quizWords.isEmpty else { return 1.0 }
            return Double(quizIndex) / Double(config.quizWords.count)
        case .deepMoment:
            return showingDeepAnswer ? 1.0 : 0.0
        case .complete:
            return 1.0
        }
    }

    /// Determines which phases are active for progress display
    var activePhases: [SessionPhase] {
        var phases: [SessionPhase] = []
        if config.hasPreviewPhase { phases.append(.preview) }
        if config.hasQuizPhase { phases.append(.quiz) }
        if config.hasDeepMomentPhase { phases.append(.deepMoment) }
        return phases
    }

    // MARK: - Initialization

    init(config: DailySessionConfig) {
        self.config = config

        // Determine starting phase
        if config.hasPreviewPhase {
            self.currentPhase = .preview
        } else if config.hasQuizPhase {
            self.currentPhase = .quiz
        } else if config.hasDeepMomentPhase {
            self.currentPhase = .deepMoment
        } else {
            self.currentPhase = .complete
        }
    }

    // MARK: - Preview Phase Actions

    func flipCard() {
        isCardFlipped.toggle()
    }

    func nextPreviewWord(modelContext: ModelContext) {
        // Mark current word as previewed
        if let word = currentPreviewWord {
            if word.learningStage == .unseen {
                word.markPreviewed()
                stats.wordsPreviewd += 1
                try? modelContext.save()
            }
        }

        // Move to next word or phase
        previewIndex += 1
        isCardFlipped = false

        if previewIndex >= config.previewWords.count {
            transitionToNextPhase()
        }
    }

    func previousPreviewWord() {
        guard previewIndex > 0 else { return }
        previewIndex -= 1
        isCardFlipped = false
    }

    // MARK: - Quiz Phase Actions

    func loadCurrentQuizQuestion() {
        guard let word = currentQuizWord else {
            // No quiz words available, transition to next phase
            transitionToNextPhase()
            return
        }

        // Generate a random question for this word
        currentQuestion = QuestionGenerator.generateRandomQuestion(
            for: word,
            allWords: config.quizWords
        )

        // Reset quiz state
        selectedOption = nil
        userTextInput = ""
        showingQuizAnswer = false
        quizAnswerResult = nil
    }

    func selectQuizOption(_ option: ActiveRecallQuestion.QuestionOption) {
        selectedOption = option
    }

    func submitQuizAnswer() {
        guard let question = currentQuestion else { return }

        if question.type == .definitionRecall {
            // Text-based answer
            quizAnswerResult = QuestionGenerator.validateTextAnswer(
                userInput: userTextInput,
                correctAnswer: question.correctAnswer,
                questionType: question.type
            )
        } else {
            // Multiple choice
            guard let selected = selectedOption else { return }
            quizAnswerResult = AnswerResult(
                isCorrect: selected.isCorrect,
                score: selected.isCorrect ? 100 : 0,
                feedback: selected.isCorrect ? "Excellent!" : "Not quite right."
            )
        }

        showingQuizAnswer = true
    }

    func skipQuizQuestion() {
        quizAnswerResult = AnswerResult(
            isCorrect: false,
            score: 0,
            feedback: "Review the answer to learn."
        )
        showingQuizAnswer = true
    }

    func proceedFromQuiz(recordedAsCorrect: Bool, modelContext: ModelContext) {
        // Update stats
        if recordedAsCorrect {
            stats.quizCorrect += 1
        } else {
            stats.quizIncorrect += 1
        }

        // Update word's learning data
        if let word = currentQuizWord {
            word.recordQuizAttempt(passed: recordedAsCorrect)
            try? modelContext.save()
        }

        // Move to next question or phase
        quizIndex += 1

        if quizIndex >= config.quizWords.count {
            transitionToNextPhase()
        } else {
            // Reset and load next question
            loadCurrentQuizQuestion()
        }
    }

    // MARK: - Deep Moment Actions

    func loadDeepMomentQuestion() {
        guard let word = config.deepLearnWord else {
            // No deep learn word available, transition to next phase
            transitionToNextPhase()
            return
        }
        deepMomentQuestion = DeepMomentGenerator.generateQuestion(for: word)
        selectedDeepOption = nil
        showingDeepAnswer = false
        deepAnswerCorrect = false
    }

    func selectDeepOption(_ option: DeepMomentQuestion.DeepMomentOption) {
        selectedDeepOption = option
    }

    func submitDeepAnswer(modelContext: ModelContext) {
        guard let selected = selectedDeepOption else { return }

        deepAnswerCorrect = selected.isCorrect
        showingDeepAnswer = true
        stats.deepMomentCompleted = true
        stats.deepMomentCorrect = selected.isCorrect

        // Update word if correct
        if let word = config.deepLearnWord, selected.isCorrect {
            word.markDeepLearned(confidence: 4)
            try? modelContext.save()
        }
    }

    func finishDeepMoment() {
        transitionToNextPhase()
    }

    func skipDeepMoment() {
        stats.deepMomentCompleted = true
        transitionToNextPhase()
    }

    // MARK: - Phase Transitions

    private func transitionToNextPhase() {
        switch currentPhase {
        case .preview:
            // Check if quiz phase has content before entering
            if config.hasQuizPhase && quizIndex < config.quizWords.count {
                currentPhase = .quiz
                loadCurrentQuizQuestion()
            } else if config.hasDeepMomentPhase {
                currentPhase = .deepMoment
                loadDeepMomentQuestion()
            } else {
                currentPhase = .complete
            }
        case .quiz:
            if config.hasDeepMomentPhase && config.deepLearnWord != nil {
                currentPhase = .deepMoment
                loadDeepMomentQuestion()
            } else {
                currentPhase = .complete
            }
        case .deepMoment:
            currentPhase = .complete
        case .complete:
            break
        }
    }

    // MARK: - Session Management

    func startSession() {
        // Reset all state
        previewIndex = 0
        quizIndex = 0
        isCardFlipped = false
        stats = DailySessionStats()

        // Determine starting phase
        if config.hasPreviewPhase {
            currentPhase = .preview
        } else if config.hasQuizPhase {
            currentPhase = .quiz
            loadCurrentQuizQuestion()
        } else if config.hasDeepMomentPhase {
            currentPhase = .deepMoment
            loadDeepMomentQuestion()
        } else {
            currentPhase = .complete
        }
    }
}
