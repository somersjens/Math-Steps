//
//  PromoTrailerScript.swift
//  Math Steps
//
//  Fixed route used only by the development App Store capture. The route is
//  fed to MathStepsPlayfield, so movement, failure, restart and completion all
//  remain the production choreography.
//

import Foundation

enum PromoTrailerScript {
    static let jumpHeadline = "Jump on the right answer"
    static let unlockHeadline = "Unlock new characters"
    static let dailyHeadline = "Improve your math every day"

    /// Hold starts only after the icon has settled upright at full size.
    static let iconHold: TimeInterval = 2.0
    static let iconSpinDuration: TimeInterval = 0.92

    static let rounds: [GameRound] = [
        round(1, prompt: "9 + 5 = ?", correct: "14", options: ["13", "14", "15"], kind: .addition),
        round(2, prompt: "7 × 3 = ?", correct: "21", options: ["18", "21", "24"], kind: .multiplication),
        round(3, prompt: "7 × 8 = ?", correct: "56", options: ["54", "56", "63"], kind: .multiplication),
        round(4, prompt: "12 + 7 = ?", correct: "19", options: ["18", "19", "21"], kind: .addition),
        round(5, prompt: "6 × 4 = ?", correct: "24", options: ["20", "24", "28"], kind: .multiplication),
    ]

    static var wrong54ID: UUID { rounds[2].options[0].id }

    private static func round(_ number: Int,
                              prompt: String,
                              correct: String,
                              options: [String],
                              kind: QuestionKind) -> GameRound {
        let question = MathQuestion(prompt: prompt,
                                    correctAnswer: correct,
                                    distractors: options.filter { $0 != correct },
                                    sourceLevel: 1,
                                    kind: kind)
        return GameRound(
            id: uuid(number * 10),
            number: number,
            question: question,
            options: options.enumerated().map { index, value in
                AnswerOption(id: uuid(number * 10 + index + 1),
                             text: value,
                             isCorrect: value == correct)
            }
        )
    }

    private static func uuid(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "A9915EED-0000-4000-8000-%012d", value))!
    }
}
