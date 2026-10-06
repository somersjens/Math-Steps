//
//  PromoTrailerDirector.swift
//  Math Steps
//
//  Drives production MathStepsPlayfield callbacks through one deterministic
//  run: two successes, a real fall/restart, then the five-step completion.
//

import SwiftUI
import Combine

@MainActor
final class PromoTrailerDirector: ObservableObject {
    @Published private(set) var characterID = "dog"
    @Published private(set) var headlineText = PromoTrailerScript.jumpHeadline
    @Published private(set) var headlineOpacity: Double = 1
    @Published private(set) var themeFlash: Double = 0

    @Published private(set) var round = PromoTrailerScript.rounds[0]
    @Published private(set) var selectedOptionID: UUID?
    @Published private(set) var brokenOptionIDs: Set<UUID> = []
    @Published private(set) var brokenRouteOptionIDs: Set<UUID> = []
    @Published private(set) var currentStep = 0
    @Published private(set) var highestStep = 0
    @Published private(set) var visibleScore = 0
    @Published private(set) var scriptedSelection: StepScriptedSelection?
    @Published private(set) var playsEntrance = false
    @Published private(set) var playsLevelCompletion = false

    @Published private(set) var iconOpacity: Double = 0
    @Published private(set) var iconScale: CGFloat = 0.86
    @Published private(set) var iconRotation: Double = -9
    @Published private(set) var backgroundBlur: CGFloat = 0
    @Published private(set) var isFinished = false

    let clock = GameClock()

    private enum Pass { case opening, replay }
    private var pass: Pass = .opening
    private var roundIndex = 0
    private var selectionToken = 0
    private var pendingWasCorrect = false
    private var pendingRaisedHighWater = false
    private var elapsed: TimeInterval = 0
    private var lastElapsed: TimeInterval = 0
    private var iconRevealAt: TimeInterval?
    private var finishAt: TimeInterval?
    private var hasPlayedCharacterUnlock = false
    private var audioCues: [(time: TimeInterval, file: String, volume: Float)] = []

    init() {
        clock.configure(total: 42, remaining: 42)
    }

    var character: AnimalCharacter { CharacterCatalog.character(id: characterID) }
    var routeRounds: [GameRound] { PromoTrailerScript.rounds }
    var maximumSteps: Int { PromoTrailerScript.rounds.count }
    var isLive: Bool { selectedOptionID == nil && !playsLevelCompletion }
    var trailerAudioCues: [(time: TimeInterval, file: String, volume: Float)] { audioCues }

    func start() {
        guard !playsEntrance else { return }
        playsEntrance = true
        cue("sfx_session_start", volume: 0.18, at: 0.76)
        print("PROMO_TRAILER_BEAT entrance")
    }

    func tick(elapsed: TimeInterval) {
        let dt = max(0, elapsed - lastElapsed)
        self.elapsed = elapsed
        lastElapsed = elapsed
        if !playsLevelCompletion { clock.advance(by: dt) }

        guard let iconRevealAt else {
            if elapsed >= PromoTrailerRuntime.maximumDuration { isFinished = true }
            return
        }
        let local = max(0, elapsed - iconRevealAt)
        let t = min(1, local / PromoTrailerScript.iconSpinDuration)
        let eased = 1 - pow(1 - t, 3)
        iconOpacity = eased
        iconScale = 0.86 + 0.14 * CGFloat(eased)
        iconRotation = -9 * (1 - eased)
        if let finishAt, elapsed >= finishAt { isFinished = true }
    }

    func entranceCompleted() {
        // Let the opening sum breathe once the dog has fully entered.
        after(1.15) { [weak self] in self?.selectCorrect() }
    }

    @discardableResult
    func acceptSelection(_ optionID: UUID) -> Bool {
        guard selectedOptionID == nil,
              let option = round.options.first(where: { $0.id == optionID }),
              !brokenOptionIDs.contains(optionID)
        else { return false }

        selectedOptionID = optionID
        pendingWasCorrect = option.isCorrect
        pendingRaisedHighWater = false
        cue("sfx_answer_tap", volume: 0.17)

        if option.isCorrect {
            currentStep += 1
            if currentStep > highestStep {
                highestStep = currentStep
                pendingRaisedHighWater = true
            }
            cue("sfx_card_reveal", volume: 0.22, at: elapsed + 0.76)
        } else {
            brokenOptionIDs.insert(optionID)
            brokenRouteOptionIDs.insert(optionID)
            // Match the production failure exactly: the glass/fall effect is
            // the only cue played at contact, at its normal gameplay level.
            cue("sfx_fall_down", volume: 0.16, at: elapsed + 0.76)
        }
        return true
    }

    func rewardArrived() {
        if pendingRaisedHighWater {
            visibleScore = highestStep
            // The second opening reward arrives immediately before the
            // intentional wrong selection. Keep that beat audibly unambiguous:
            // select, then the production fall cue — never a stray success cue.
            if !(pass == .opening && roundIndex == 2) {
                cue("score_increase_main", volume: 0.16)
            }
        }
    }

    func correctLandingCompleted() {
        guard pendingWasCorrect else { return }
        let completedIndex = roundIndex
        pendingWasCorrect = false

        if pass == .replay, completedIndex == PromoTrailerScript.rounds.count - 1 {
            selectedOptionID = nil
            playsLevelCompletion = true
            headlineOpacity = 0
            cue("sfx_level_complete", volume: 0.24)
            print("PROMO_TRAILER_BEAT completion t=\(String(format: "%.2f", elapsed))")
            return
        }

        roundIndex += 1
        round = PromoTrailerScript.rounds[roundIndex]
        selectedOptionID = nil

        if pass == .opening {
            // New sums get enough screen time to be read before the answer.
            after(1.25) { [weak self] in
                guard let self else { return }
                self.roundIndex == 2 ? self.selectWrong54() : self.selectCorrect()
            }
            return
        }

        switch roundIndex {
        case 1:
            transition(to: "lion", selectionDelay: 1.05)
        case 2:
            transition(to: "crab", selectionDelay: 1.05)
        case 3:
            transition(to: "penguin", selectionDelay: 1.45)
        case 4:
            headlineText = PromoTrailerScript.dailyHeadline
            transition(to: "dog", selectionDelay: 1.45)
        default:
            after(0.30) { [weak self] in self?.selectCorrect() }
        }
    }

    func wrongFallCompleted() {
        guard !pendingWasCorrect, pass == .opening else { return }
        pass = .replay
        roundIndex = 0
        round = PromoTrailerScript.rounds[0]
        currentStep = 0
        selectedOptionID = nil
        headlineText = PromoTrailerScript.unlockHeadline
        headlineOpacity = 1
        print("PROMO_TRAILER_BEAT restart t=\(String(format: "%.2f", elapsed))")
        // This stone was already solved before the fall, so its replay can be
        // a little brisker than a newly introduced sum.
        after(0.50) { [weak self] in self?.selectCorrect() }
    }

    func levelCompletionFinished() {
        guard iconRevealAt == nil else { return }
        iconRevealAt = elapsed + 0.04
        finishAt = elapsed + 0.04
            + PromoTrailerScript.iconSpinDuration
            + PromoTrailerScript.iconHold
        withAnimation(.easeInOut(duration: 0.55)) { backgroundBlur = 3.0 }
        print("PROMO_TRAILER_BEAT icon t=\(String(format: "%.2f", elapsed))")
    }

    private func selectCorrect() {
        guard let id = round.correctOption?.id else { return }
        trigger(id)
    }

    private func selectWrong54() {
        trigger(PromoTrailerScript.wrong54ID)
    }

    private func trigger(_ optionID: UUID) {
        selectionToken += 1
        scriptedSelection = StepScriptedSelection(token: selectionToken,
                                                  optionID: optionID)
        let answer = round.options.first(where: { $0.id == optionID })?.text ?? "?"
        print("PROMO_TRAILER_JUMP q=\(round.question.prompt) answer=\(answer) character=\(characterID) t=\(String(format: "%.2f", elapsed))")
    }

    private func transition(to id: String, selectionDelay: TimeInterval) {
        guard characterID != id else {
            after(selectionDelay) { [weak self] in self?.selectCorrect() }
            return
        }
        withAnimation(.easeInOut(duration: 0.30)) { themeFlash = 1 }
        after(0.30) { [weak self] in
            guard let self else { return }
            self.characterID = id
            if !self.hasPlayedCharacterUnlock {
                self.hasPlayedCharacterUnlock = true
                self.cue("sfx_character_unlock", volume: 0.18)
            }
            withAnimation(.easeOut(duration: 0.68)) { self.themeFlash = 0 }
        }
        after(selectionDelay) { [weak self] in self?.selectCorrect() }
    }

    private func cue(_ file: String, volume: Float, at time: TimeInterval? = nil) {
        audioCues.append((time ?? elapsed, file, volume))
    }

    private func after(_ delay: TimeInterval, _ work: @escaping @MainActor () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { work() }
    }
}
