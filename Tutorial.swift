//
//  Tutorial.swift
//  Math Steps
//
//  The guided first game. It teaches the current stepping rules in four beats:
//  two safe answers, an intentional fall, the timer, and the finish-line prize.
//  Scoring still runs through `MemoryGame`, so every answer here counts.
//

import SwiftUI
import Combine

enum TutorialStyle {
    static let timerRed = Color(red: 0.88, green: 0.10, blue: 0.14)
    static let scoreYellow = Color(red: 1.00, green: 0.78, blue: 0.06)
}

// MARK: - Steps

/// The four in-game steps, in the order they are played.
enum TutorialStep: Int, CaseIterable, Identifiable {
    /// Two rounds with the wrong tiles already missing.
    case chooseCorrect = 1
    /// Normal three-answer play, held until the first fall is fully complete.
    case chooseWrong
    /// Timed play starts here; three further correct landings reveal the prize.
    case timer
    /// Short closing message while normal timed play continues.
    case finishLine

    var id: Int { rawValue }

    var messageKey: String {
        switch self {
        case .chooseCorrect: return "tutorial.steps.chooseCorrect"
        case .chooseWrong:   return "tutorial.steps.chooseWrong"
        case .timer:         return "tutorial.steps.timer"
        case .finishLine:    return "tutorial.steps.finishLine"
        }
    }

    static let finishLineMessageDuration = 5.0
}

// MARK: - Controller

/// Runs the script: holds the current step, hands the claw machine its plan,
/// and moves on the moment the step's own condition is met.
@MainActor
final class TutorialController: ObservableObject {
    @Published private(set) var step: TutorialStep?

    /// The session being taught. Weak, so the controller can never keep a
    /// finished game alive.
    private weak var model: GameViewModel?
    /// Invalidates the pending close of the last message when the run is left,
    /// restarted or finished first.
    private var generation = 0
    private var openingCorrectAnswers = 0
    private var correctAnswersAfterFall = 0
    private var waitsForWrongFall = false
    /// Once installed, the two safe opening rows keep their missing lanes for
    /// this entire run, including after the tutorial message has disappeared.
    private var keepsOpeningGaps = false

    var isActive: Bool { step != nil }

    /// The line currently on screen. Only English copy ships in this first pass;
    /// the localization layer falls back to it for every other app language.
    var message: String? {
        step.map { L(key: $0.messageKey) }
    }

    /// What the claw machine should allow while a step is being taught.
    var clawPlan: ClawTutorialPlan {
        var plan = Self.clawPlan(for: step)
        plan.hidesIncorrectAnswers = keepsOpeningGaps
        return plan
    }

    // MARK: Lifecycle

    /// Starts the walkthrough on a session that has just opened its first round.
    func begin(model: GameViewModel) {
        guard step == nil else { return }
        self.model = model
        openingCorrectAnswers = 0
        correctAnswersAfterFall = 0
        waitsForWrongFall = false
        keepsOpeningGaps = true
        model.setTutorialClockPaused(true)
        model.onAnswerResolved = { [weak self] isCorrect, _ in
            self?.answerResolved(isCorrect: isCorrect)
        }
        // This walkthrough is complete inside the game. Clear the legacy
        // menu-score hint so the four requested steps remain the whole script.
        GameSettings.tutorialHomeHintPending = false
        enter(.chooseCorrect)
    }

    /// Ends the walkthrough and hands the level back to timed play.
    func finish(keepOpeningGaps: Bool = true) {
        if !keepOpeningGaps { keepsOpeningGaps = false }
        guard step != nil else { return }
        generation &+= 1
        release()
        withAnimation(.easeOut(duration: 0.32)) {
            step = nil
        }
    }

    /// Leaving the game screen: the same tidy-up, without the animation of a
    /// view that is on its way out.
    func cancel() {
        guard step != nil else { return }
        generation &+= 1
        keepsOpeningGaps = false
        release(resumeClock: false)
        step = nil
    }

    private func release(resumeClock: Bool = true) {
        model?.setTutorialClockPaused(false, resumeClock: resumeClock)
        model?.onAnswerResolved = nil
    }

    /// Reported by the session for every answer it accepts.
    private func answerResolved(isCorrect: Bool) {
        guard let step else { return }
        switch step {
        case .chooseCorrect:
            if isCorrect { openingCorrectAnswers += 1 }
        case .chooseWrong:
            if !isCorrect { waitsForWrongFall = true }
        case .timer:
            if isCorrect { correctAnswersAfterFall += 1 }
        case .finishLine:
            break
        }
    }

    /// Called on the exact visual landing frame, after the answer was accepted.
    /// Keeping transitions here prevents missing tutorial tiles from popping
    /// back into the row while the character is still jumping toward it.
    func correctLandingCompleted() {
        guard let step else { return }
        if step == .chooseCorrect, openingCorrectAnswers >= 2 {
            enter(.chooseWrong)
        } else if step == .timer, correctAnswersAfterFall >= 3 {
            enter(.finishLine)
        }
    }

    /// Called after the complete fall-and-respawn choreography. The timer is
    /// released here, so none of the player's level time is spent beforehand.
    func wrongFallCompleted() {
        guard step == .chooseWrong, waitsForWrongFall else { return }
        waitsForWrongFall = false
        enter(.timer)
        model?.setTutorialClockPaused(false)
    }

    // MARK: Steps

    private func enter(_ step: TutorialStep) {
        generation &+= 1
        let token = generation

        // The message and its visual hints animate internally; the plan itself
        // changes without moving the playfield's hit regions.
        self.step = step

        if step == .finishLine {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + TutorialStep.finishLineMessageDuration
            ) { [weak self] in
                guard let self, self.generation == token, self.step == step else { return }
                self.finish()
            }
        }
    }

    private static func clawPlan(for step: TutorialStep?) -> ClawTutorialPlan {
        guard let step else { return ClawTutorialPlan() }
        var plan = ClawTutorialPlan()
        plan.isActive = true
        switch step {
        case .chooseCorrect:
            plan.highlightsCorrectNut = true
        case .timer:
            plan.highlightsTimer = true
        case .finishLine:
            plan.highlightsScore = true
        case .chooseWrong:
            break
        }
        return plan
    }
}

// MARK: - Message

/// The line the tutorial is currently teaching, shown under the HUD.
struct TutorialMessageCard: View {
    let text: String
    let theme: AnimalCharacter
    var isPad: Bool = AppLayout.isPad
    var highlightsTimer = false
    var highlightsScore = false

    private var styledText: AttributedString {
        var copy = AttributedString(text)
        copy.font = .system(size: isPad ? 19 : 14.5,
                            weight: .bold,
                            design: .rounded)
        copy.foregroundColor = theme.deepColor
        if highlightsTimer, let timer = copy.range(of: "timer") {
            copy[timer].foregroundColor = TutorialStyle.timerRed
            copy[timer].font = .system(size: isPad ? 19 : 14.5,
                                       weight: .black,
                                       design: .rounded)
        }
        if highlightsScore, let score = copy.range(of: "score") {
            copy[score].foregroundColor = TutorialStyle.scoreYellow
            copy[score].font = .system(size: isPad ? 19 : 14.5,
                                       weight: .black,
                                       design: .rounded)
        }
        return copy
    }

    var body: some View {
        Text(styledText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isPad ? 16 : 12)
        .padding(.vertical, isPad ? 12 : 9)
        .background {
            RoundedRectangle(cornerRadius: isPad ? 24 : 20, style: .continuous)
                .fill(.white.opacity(0.95))
                .overlay {
                    RoundedRectangle(cornerRadius: isPad ? 24 : 20, style: .continuous)
                        .stroke(.white, lineWidth: 2)
                }
                .shadow(color: theme.deepColor.opacity(0.24), radius: 12, y: 6)
        }
        .frame(maxWidth: isPad ? 620 : 420)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - "Before the first point" notice

/// Shown when the tutorial is asked for after the first point was earned.
/// Same card, same button as everything else the level screen puts up.
struct TutorialNoticeCard: View {
    let theme: AnimalCharacter
    let onDismiss: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isPad: Bool {
        AppLayout.isPad && horizontalSizeClass != .compact
    }
    private var scale: CGFloat { isPad ? 1.2 : 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 14 * scale) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 30 * scale, weight: .bold))
                    .foregroundStyle(theme.deepColor)
                    .frame(width: 62 * scale, height: 62 * scale)
                    .background(theme.skyColor, in: Circle())

                Text("tutorial.notice.title")
                    .font(.system(size: 22 * scale, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.deepColor)
                    .multilineTextAlignment(.center)

                Text("tutorial.notice.message")
                    .font(.system(size: 15 * scale, weight: .regular))
                    .foregroundStyle(theme.deepColor.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onDismiss) {
                    Text("common.ok")
                        .font(.system(size: 17 * scale, weight: .heavy))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14 * scale)
                        .foregroundStyle(.white)
                        .background(theme.deepColor,
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tutorial-notice-ok")
            }
            .padding(26 * scale)
            .frame(maxWidth: 340 * scale)
            // Same light fill as the start/pause card: `.background` turns
            // black in Dark Mode against this card's deep-purple copy.
            .background(Color.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.deepColor.opacity(0.14), lineWidth: 1))
            .shadow(color: theme.deepColor.opacity(0.3), radius: 20, y: 10)
            .padding(24)
        }
    }
}
