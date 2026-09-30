//
//  RoundFactory.swift
//  Elephant Challenge: Math Memory
//
//  Builds one complete round: the question, the answer cards in their final
//  shuffled positions.
//
//  Answer positions are decided here, once, before the cards become visible —
//  the UI never re-orders them afterwards.
//

import Foundation

// MARK: - Answer card

nonisolated public struct AnswerOption: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let text: String
    public let isCorrect: Bool

    public init(id: UUID = UUID(), text: String, isCorrect: Bool) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
    }
}

// MARK: - Round

nonisolated public struct GameRound: Identifiable, Equatable, Sendable {
    public let id: UUID
    /// 1-based position in the session.
    public let number: Int
    public let question: MathQuestion
    /// Exactly one option has `isCorrect == true`.
    public let options: [AnswerOption]
    /// A grabable shell that currently prints this sum's answer. Grabbing is
    /// scored by printed value; this id is the claw's preferred target. Nil
    /// for scripted rounds that still score through `options`.
    public let targetNutID: UUID?
    public init(id: UUID = UUID(),
                number: Int,
                question: MathQuestion,
                options: [AnswerOption],
                targetNutID: UUID? = nil) {
        self.id = id
        self.number = number
        self.question = question
        self.options = options
        self.targetNutID = targetNutID
    }

    public var correctOption: AnswerOption? {
        options.first { $0.isCorrect }
    }
}

// MARK: - Factory

nonisolated public final class RoundFactory {
    private let generator: QuestionGenerator
    private let random: RandomSource
    /// Kept separate from question generation so laying out answers never
    /// changes which sums a seed produces. The round number makes the layout
    /// reproducible after pausing and rebuilding a session.
    private let answerPositionSeed: UInt64

    public init(level: MathLevel,
                mixedVariant: MixedVariant = .all,
                mode: PracticeMode = .mixed,
                seed: UInt64? = nil) {
        let random = RandomSource(seed: seed)
        self.random = random
        self.answerPositionSeed = (seed ?? UInt64.random(in: 1...UInt64.max))
            ^ 0xA24B_AED4_963E_E407
        self.generator = QuestionGenerator(level: level,
                                           mode: mode,
                                           mixedVariant: mixedVariant,
                                           random: random)
    }

    public func reset() {
        generator.reset()
    }

    /// Builds the round for a given 1-based round number.
    public func makeRound(number: Int) -> GameRound {
        let question = generator.next(requiredDistractors: GameConfig.distractorCount)
        return makeRound(number: number, question: question)
    }

    /// A full board of sums, preferring a different printed answer each time
    /// so the claw pile is not stacked with identical shells.
    public func makeSession(count: Int) -> [GameRound] {
        var used: Set<AnswerValue> = []
        return (1...count).map { number in
            let question = generator.next(requiredDistractors: GameConfig.distractorCount,
                                          excludingAnswers: used)
            used.insert(AnswerValue(question.correctAnswer))
            return makeRound(number: number, question: question)
        }
    }

    /// Lays a already-chosen question onto a round so a claw pile can reorder
    /// the session's sums without asking the generator for new ones.
    public func makeRound(number: Int,
                          question: MathQuestion,
                          targetNutID: UUID? = nil) -> GameRound {
        GameRound(number: number,
                  question: question,
                  options: makeOptions(for: question, roundNumber: number),
                  targetNutID: targetNutID)
    }

    /// One correct card plus the required number of unique wrong cards. The
    /// wrong values keep their ascending order, while the correct card gets a
    /// balanced-random lane. Repeats are allowed, but no lane can ever lead a
    /// different lane by more than two appearances.
    private func makeOptions(for question: MathQuestion,
                             roundNumber: Int) -> [AnswerOption] {
        var options = [AnswerOption(text: question.correctAnswer, isCorrect: true)]
        var used: Set<AnswerValue> = [AnswerValue(question.correctAnswer)]
        for candidate in question.distractors {
            guard options.count <= GameConfig.distractorCount else { break }
            let value = AnswerValue(candidate)
            guard !used.contains(value) else { continue }
            used.insert(value)
            options.append(AnswerOption(text: candidate, isCorrect: false))
        }
        let ordered = options.sorted { AnswerValue($0.text) < AnswerValue($1.text) }
        guard let correct = ordered.first(where: \.isCorrect) else { return ordered }
        var laidOut = ordered.filter { !$0.isCorrect }
        let lane = min(correctLane(forRound: roundNumber), laidOut.count)
        laidOut.insert(correct, at: lane)
        return laidOut
    }

    /// Replays the tiny deterministic lane sequence up to `roundNumber`.
    /// A lane remains eligible until it is two uses ahead of the least-used
    /// lane. This preserves natural-looking consecutive repeats without the
    /// long-term centre bias caused by sorting around the correct answer.
    private func correctLane(forRound roundNumber: Int) -> Int {
        let laneCount = GameConfig.answerBubbleCount
        guard laneCount > 1 else { return 0 }

        var generator = SeededGenerator(seed: answerPositionSeed)
        var counts = Array(repeating: 0, count: laneCount)
        var selected = 0

        for _ in 0..<max(1, roundNumber) {
            let minimum = counts.min() ?? 0
            let eligible = counts.indices.filter { counts[$0] <= minimum + 1 }
            selected = eligible.randomElement(using: &generator) ?? 0
            counts[selected] += 1
        }
        return selected
    }
}
