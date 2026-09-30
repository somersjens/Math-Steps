//
//  MathStepsGame.swift
//  Math Steps
//
//  The portrait stepping playfield. Session rules, timing, persistence and
//  rewards stay in MemoryGame/GameViewModel; this file owns the perspective
//  course and the jump, camera-follow, break, fall and restart choreography.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MathStepsPlayfield: View {
    let round: GameRound?
    let selectedOptionID: UUID?
    let brokenOptionIDs: Set<UUID>
    let routeRounds: [GameRound]
    let brokenRouteOptionIDs: Set<UUID>
    let currentStep: Int
    let highestStep: Int
    let maximumSteps: Int
    let character: AnimalCharacter
    let isPad: Bool
    let isLive: Bool
    let isRunning: Bool
    let playsEntrance: Bool
    let playsLevelCompletion: Bool
    let playsTimeOutFinale: Bool
    let reduceMotion: Bool
    let tutorialPlan: ClawTutorialPlan
    let topReserve: CGFloat
    let bottomReserve: CGFloat
    let onSelect: (UUID) -> Bool
    let onRewardArrived: () -> Void
    let onEntranceComplete: () -> Void
    let onLevelCompletionFinished: () -> Void
    let onTimeOutFinished: () -> Void
    let onTutorialMove: () -> Void

    @State private var cameraPhase: CGFloat = 0
    @State private var cameraLaneOffset: CGFloat = 0
    @State private var dogX: CGFloat = 0
    @State private var dogY: CGFloat = 0
    @State private var dogScale: CGFloat = 1
    @State private var dogRotation = 0.0
    @State private var dogOpacity = 1.0
    @State private var dogFrame = 1
    @State private var dogTracksAnswerRow = false
    @State private var jumpProgress: CGFloat = 0
    @State private var jumpDestinationX: CGFloat = 0
    @State private var jumpDestinationY: CGFloat = 0
    @State private var jumpLateralArc: CGFloat = 0
    @State private var jumpHeight: CGFloat = 0
    @State private var landedRound: GameRound?
    @State private var landedLane = 1
    /// The standing answer row stays visually active during flight. Only the
    /// actual landing turns all three numbers into background information.
    @State private var currentRowNumbersMuted = false
    @State private var landingImpact = false
    @State private var hatchOpen = false
    @State private var liftPlatformY: CGFloat = 0
    @State private var liftPlatformVisible = false
    @State private var characterAboveDeck = true
    @State private var pendingWrongID: UUID?
    @State private var crackedID: UUID?
    @State private var brokenID: UUID?
    /// Drives the loose pieces of a failed glass tile. It starts at the exact
    /// contact frame and shares the character's downward acceleration.
    @State private var shatterProgress: CGFloat = 0
    @State private var rewardVisible = false
    @State private var rewardRise: CGFloat = 0
    /// Absolute route position while the camera travels back after a fall.
    /// Nil during normal play; zero means the starting platform is reached.
    @State private var rewindPosition: CGFloat?
    @State private var restartMessageVisible = false
    @State private var entranceCompleted = false
    @State private var victoryChestAttached = false
    @State private var victoryInProgress = false
    /// Locks the destination in world space while the final choreography
    /// runs. Parent game-state updates may reset the normal camera phase, but
    /// the island must not take a small step backward when that happens.
    @State private var victoryGoalDepth: CGFloat?
    @State private var animationToken = 0

    /// The route is planned once. Rendering uses a moving window over those
    /// fixed rounds; the destination sits after the final stored round rather
    /// than after an arbitrary number of visible rows.
    private var routeRoundCount: Int {
        min(maximumSteps, routeRounds.count)
    }

    private var currentRouteIndex: Int {
        guard routeRoundCount > 0 else { return 0 }
        let index = (round?.number ?? (currentStep + 1)) - 1
        return min(max(0, index), routeRoundCount - 1)
    }

    private var remainingFutureRounds: Int {
        max(0, routeRoundCount - currentRouteIndex - 1)
    }

    /// One depth position beyond the last remaining question.
    private var goalCourseDepth: CGFloat {
        CGFloat(remainingFutureRounds + 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = StepCourseLayout(size: proxy.size,
                                          isPad: isPad,
                                          topReserve: topReserve,
                                          bottomReserve: bottomReserve)
            let characterSize = character.id == "dog"
                ? layout.dogSize
                : layout.dogSize / 1.5
            let trackedDogDepth = -cameraPhase
            let renderedDogX = dogTracksAnswerRow
                ? layout.laneOffset(lane: landedLane, at: trackedDogDepth)
                : dogX
            let renderedDogY = dogTracksAnswerRow
                ? layout.y(at: trackedDogDepth) - layout.baseY
                : dogY
            let renderedDogScale = dogTracksAnswerRow
                ? layout.scale(at: trackedDogDepth)
                : dogScale
            let goalDepth = victoryGoalDepth
                ?? max(0, goalCourseDepth - cameraPhase)
            // The construction never ends at the destination itself. Rails
            // continue past the island to a point above the viewport, so the
            // player cannot see a capped-off bridge when the last rows arrive.
            let railEndDepth = layout.offscreenRailDepth
            // Background parallax uses the absolute route position. At a
            // question boundary `cameraPhase` returns to zero while the route
            // index advances by one, so their sum stays perfectly continuous.
            let worldTravel = rewindPosition
                ?? (CGFloat(currentRouteIndex) + cameraPhase)

            ZStack {
                StepSky(character: character, travel: worldTravel)
                FloatingWorld(character: character, isPad: isPad, travel: worldTravel)
                StepCourseRails(layout: layout,
                                character: character,
                                farDepth: railEndDepth)
                if let rewindPosition {
                    rewindRows(layout: layout, position: rewindPosition)
                    if rewindPosition <= 0.001 { startDeck(layout: layout) }
                } else {
                    decorativeRows(layout: layout)
                    if !victoryInProgress {
                        answerTiles(layout: layout)
                    }
                    startDeck(layout: layout)
                }
                // The bridge enters underneath the destination. Drawing the
                // island after the distant rows masks their final edge instead
                // of letting glass continue across the grass.
                goalIsland(layout: layout, depth: goalDepth)
                    .opacity(rewindPosition == nil ? 1 : 0)

                characterBack
                    .overlay(alignment: .center) {
                        if victoryChestAttached {
                            StepGoalChest()
                                .frame(width: characterSize * 0.40,
                                       height: characterSize * 0.24)
                                // In front of the torso: this reads as the dog
                                // carrying the prize, rather than balancing it
                                // on its head during the exit jump.
                                .offset(y: characterSize * 0.14)
                                .transition(.scale(scale: 0.35).combined(with: .opacity))
                        }
                    }
                    .frame(width: characterSize, height: characterSize)
                    .scaleEffect(renderedDogScale)
                    .rotationEffect(.degrees(dogRotation))
                    .opacity(dogOpacity)
                    .position(x: layout.size.width / 2 + renderedDogX,
                              y: layout.baseY - characterSize * 0.43 + renderedDogY)
                    .modifier(StepJumpArcModifier(progress: jumpProgress,
                                                  destinationX: jumpDestinationX,
                                                  destinationY: jumpDestinationY,
                                                  lateralArc: jumpLateralArc,
                                                  height: jumpHeight,
                                                  reduceMotion: reduceMotion))
                    .shadow(color: .black.opacity(0.30),
                            radius: jumpProgress > 0 && jumpProgress < 1 ? 15 : 9,
                            y: jumpProgress > 0 && jumpProgress < 1 ? 14 : 8)
                    .zIndex(characterAboveDeck ? 8 : 3)
                    // The character may overlap the closest answer visually,
                    // but must never steal that tile's tap target.
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                if landingImpact {
                    let impactDepth = -cameraPhase
                    StepLandingImpact(character: character, isPad: isPad)
                        .frame(width: layout.tileWidth * 1.75,
                               height: isPad ? 54 : 38)
                        .position(x: layout.size.width / 2
                                    + layout.laneOffset(lane: landedLane,
                                                        at: impactDepth),
                                  y: layout.y(at: impactDepth)
                                    - layout.tileHeight(at: impactDepth) * 0.42)
                        .zIndex(7)
                        .transition(.scale(scale: 0.55).combined(with: .opacity))
                        .allowsHitTesting(false)
                }

                if hatchOpen, landedRound == nil {
                    if liftPlatformVisible {
                        StepLiftPlatform(character: character, isPad: isPad)
                            .frame(width: layout.liftSize,
                                   height: layout.liftSize * 0.42)
                            .position(x: layout.size.width / 2,
                                      y: layout.baseY + layout.deckHeight * 0.11
                                        + liftPlatformY)
                            .zIndex(7)
                            .allowsHitTesting(false)
                    }
                    StepHatchFrontLip(character: character, isPad: isPad)
                        .frame(width: layout.liftSize,
                               height: layout.liftSize * 0.48)
                        .position(x: layout.size.width / 2,
                                  y: layout.baseY + layout.deckHeight * 0.12)
                        .zIndex(9)
                        .allowsHitTesting(false)
                }

                if rewardVisible { rewardBadge(layout: layout) }

                progressBadge(layout: layout)
                promptBar(width: layout.promptWidth)
                    .position(x: layout.size.width / 2, y: layout.promptY)
                    .opacity(rewindPosition == nil ? 1 : 0)

                if restartMessageVisible { restartBadge(layout: layout) }
            }
            // A failed first sum deliberately presents the exact same planned
            // round again, including the same UUID. Input unlocking is the
            // reliable round boundary for both that case and normal progress.
            .onChange(of: selectedOptionID) { previous, current in
                if previous != nil, current == nil { resetForNextQuestion() }
            }
            .onChange(of: playsEntrance) { _, active in
                if active { playEntrance(layout: layout) }
            }
            .onChange(of: playsLevelCompletion) { _, active in
                if active { playCompletion(layout: layout) }
            }
            .onChange(of: playsTimeOutFinale) { _, active in
                if active { playTimeOut() }
            }
            .onAppear {
#if canImport(UIKit)
                StepDogSpriteCache.prewarm()
#endif
                restoreLandingIfNeeded(layout: layout)
                if playsEntrance { playEntrance(layout: layout) }
            }
        }
        .allowsHitTesting(isRunning)
    }

    // MARK: - Main course

    private func decorativeRows(layout: StepCourseLayout) -> some View {
        let standingIndex = currentRouteIndex
        let visibleFutureCount = min(layout.offscreenRowDepth,
                                     remainingFutureRounds)
        return ZStack {
            if visibleFutureCount > 0 {
                ForEach(Array((1...visibleFutureCount).reversed()), id: \.self) { row in
                    let depth = CGFloat(row) - cameraPhase
                    let perspective = layout.tilePerspective(at: depth)
                    let routeIndex = standingIndex + row
                    StepDecorativeRow(character: character,
                                      isPad: isPad,
                                      round: routeRounds[routeIndex],
                                      brokenOptionIDs: brokenRouteOptionIDs,
                                      perspective: perspective,
                                      activeLane: nil)
                        .frame(width: layout.courseWidth * perspective.bottomScale,
                               height: layout.tileHeight(at: depth))
                        .position(x: layout.courseCenterX(cameraPhase: cameraPhase,
                                                          laneOffset: cameraLaneOffset),
                                  y: layout.y(at: depth))
                        .opacity(layout.opacity(at: depth))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// During a failed-answer return the bridge is not rebuilt at the start.
    /// The already planned rows themselves travel through one continuous
    /// perspective until route position zero is back in front of the player.
    private func rewindRows(layout: StepCourseLayout, position: CGFloat) -> some View {
        let lastVisibleIndex = min(routeRounds.count - 1,
                                   Int(ceil(position)) + layout.offscreenRowDepth)
        return ZStack {
            if lastVisibleIndex >= 0 {
                ForEach(Array(0...lastVisibleIndex).reversed(), id: \.self) { routeIndex in
                    let depth = CGFloat(routeIndex) - position
                    let perspective = layout.tilePerspective(at: depth)
                    let nearEdgeOpacity = depth < -1
                        ? 0
                        : min(1, max(0, Double(depth + 1)))
                    StepDecorativeRow(character: character,
                                      isPad: isPad,
                                      round: routeRounds[routeIndex],
                                      brokenOptionIDs: brokenRouteOptionIDs,
                                      perspective: perspective,
                                      activeLane: nil)
                        .frame(width: layout.courseWidth * perspective.bottomScale,
                               height: layout.tileHeight(at: depth))
                        .position(x: layout.size.width / 2,
                                  y: layout.y(at: depth))
                        .opacity(depth > CGFloat(layout.offscreenRowDepth) + 0.2
                            ? 0
                            : layout.opacity(at: depth) * nearEdgeOpacity)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func answerTiles(layout: StepCourseLayout) -> some View {
        let depth = -cameraPhase
        let perspective = layout.tilePerspective(at: depth)
        return HStack(spacing: 0) {
            ForEach(Array((round?.options ?? []).prefix(3).enumerated()), id: \.element.id) { lane, option in
                // Keep the selected tile alive for the complete failure beat.
                // Replacing it with `BrokenStepGap` as soon as the model marks
                // it missing would remove the shards on their very first frame.
                let isActiveWrongTile = selectedOptionID == option.id
                    && pendingWrongID == option.id
                let isMissing = brokenOptionIDs.contains(option.id) && !isActiveWrongTile
                Group {
                    if isMissing {
                        BrokenStepGap(character: character,
                                      lane: lane,
                                      perspective: perspective)
                            .accessibilityHidden(true)
                    } else {
                        Button {
                            choose(option, lane: lane, layout: layout)
                        } label: {
                            GlassStepTile(text: option.text,
                                          lane: lane,
                                          perspective: perspective,
                                          character: character,
                                          isCracked: crackedID == option.id,
                                          isBroken: brokenID == option.id,
                                          shatterProgress: brokenID == option.id
                                            ? shatterProgress
                                            : 0,
                                          shatterDistance: layout.size.height * 0.72,
                                          isHighlighted: tutorialPlan.highlightsCorrectNut && option.isCorrect,
                                          isNumberMuted: currentRowNumbersMuted)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        // `disabled` changes a Button label's rendering before
                        // the jump has landed. Input is still safely locked by
                        // `choose`, while hit testing avoids that colour flash.
                        .allowsHitTesting(isLive && selectedOptionID == nil)
                        .accessibilityLabel(Text(verbatim: option.text))
                        .accessibilityIdentifier("step-answer-\(lane)")
                    }
                }
                .frame(width: layout.tileWidth * perspective.bottomScale,
                       height: layout.tileHeight(at: depth))
            }
        }
        .frame(width: layout.courseWidth * perspective.bottomScale,
               height: layout.tileHeight(at: depth))
        .position(x: layout.courseCenterX(cameraPhase: cameraPhase,
                                          laneOffset: cameraLaneOffset),
                  y: layout.y(at: depth))
        .zIndex(3)
    }

    private func startDeck(layout: StepCourseLayout) -> some View {
        Group {
            if let landedRound {
                // During the finale this is the last real stone. Keep it at
                // the player's feet while the answer-row renderer is removed;
                // on ordinary jumps it travels behind the camera and exits.
                let depth = victoryInProgress ? -1 : -1 - cameraPhase
                let perspective = layout.tilePerspective(at: depth)
                StepDecorativeRow(character: character,
                                  isPad: isPad,
                                  round: landedRound,
                                  brokenOptionIDs: brokenRouteOptionIDs,
                                  perspective: perspective,
                                  activeLane: nil)
                    .frame(width: layout.courseWidth * perspective.bottomScale,
                           height: layout.tileHeight(at: depth))
                    .position(x: layout.size.width / 2,
                              y: layout.y(at: depth))
            } else {
                let deckDepth = -1 - cameraPhase
                StepStartDeck(character: character,
                              isPad: isPad,
                              hatchOpen: hatchOpen)
                    .frame(width: layout.deckWidth, height: layout.deckHeight)
                    .position(x: layout.size.width / 2,
                              y: layout.y(at: deckDepth) + layout.deckHeight * 0.14)
                    .scaleEffect(1 + cameraPhase * 0.08)
            }
        }
        .zIndex(4)
        .allowsHitTesting(false)
    }

    private func goalIsland(layout: StepCourseLayout, depth: CGFloat) -> some View {
        // The destination always exists in world space. At long distance its
        // natural perspective position and size keep it fully above the
        // viewport; near the end it follows the same depth curve as the rows
        // and therefore enters without a separate pop-in animation.
        let width = layout.goalWidth(at: depth)
        return StepGoalIsland(character: character,
                              isPad: isPad,
                              hidesChest: victoryChestAttached)
            .frame(width: width, height: width * 0.47)
            .position(x: layout.size.width / 2,
                      y: layout.y(at: depth))
            .allowsHitTesting(false)
    }

    // MARK: - HUD

    private func promptBar(width: CGFloat) -> some View {
        Text(verbatim: round?.question.prompt ?? "")
            .font(.system(size: isPad ? 43 : 28, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.06, green: 0.20, blue: 0.43))
            .minimumScaleFactor(0.42)
            .lineLimit(1)
            .padding(.horizontal, isPad ? 28 : 18)
            .frame(width: max(170, width), height: isPad ? 86 : 62)
            .background {
                RoundedRectangle(cornerRadius: isPad ? 25 : 18, style: .continuous)
                    .fill(LinearGradient(colors: [Color.white,
                                                  Color(red: 1.0, green: 0.97, blue: 0.88)],
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .overlay {
                        RoundedRectangle(cornerRadius: isPad ? 25 : 18, style: .continuous)
                            .stroke(LinearGradient(colors: [Color(red: 1.0, green: 0.83, blue: 0.28),
                                                            Color(red: 0.98, green: 0.55, blue: 0.07)],
                                                   startPoint: .top,
                                                   endPoint: .bottom),
                                    lineWidth: isPad ? 7 : 5)
                    }
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.75))
                            .frame(height: isPad ? 4 : 3)
                            .padding(.horizontal, isPad ? 27 : 20)
                            .padding(.top, isPad ? 8 : 6)
                    }
            }
            .shadow(color: Color(red: 0.02, green: 0.25, blue: 0.58).opacity(0.30),
                    radius: 9, y: 6)
            .id(round?.id)
            .transition(.scale(scale: 0.94).combined(with: .opacity))
            .accessibilityIdentifier("claw-prompt")
    }

    private func progressBadge(layout: StepCourseLayout) -> some View {
        HStack(spacing: isPad ? 12 : 8) {
            Image(systemName: "pawprint.fill")
                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.12))
            Text(verbatim: "\(LN(currentStep)) / \(LN(maximumSteps))")
            Rectangle()
                .fill(.white.opacity(0.28))
                .frame(width: 1, height: isPad ? 25 : 18)
            Image(systemName: "star.fill")
                .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.12))
            Text(verbatim: LN(highestStep))
        }
        .font(.system(size: isPad ? 21 : 14, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, isPad ? 18 : 12)
        .padding(.vertical, isPad ? 11 : 8)
        .background(Color(red: 0.03, green: 0.18, blue: 0.40).opacity(0.92), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.24), radius: 5, y: 3)
        .position(x: layout.size.width / 2,
                  y: layout.promptY + (isPad ? 68 : 50))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(currentStep), \(highestStep)"))
    }

    private func rewardBadge(layout: StepCourseLayout) -> some View {
        HStack(spacing: 5) {
            Text(verbatim: "+1")
                .font(.system(size: isPad ? 25 : 18, weight: .black, design: .rounded))
            CurrencyIcon(size: isPad ? 28 : 20)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0.03, green: 0.18, blue: 0.40).opacity(0.92), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 1))
        .position(x: layout.size.width / 2,
                  y: layout.baseY - layout.dogSize - rewardRise)
        .transition(.scale.combined(with: .opacity))
        .zIndex(9)
    }

    private func restartBadge(layout: StepCourseLayout) -> some View {
        HStack(spacing: isPad ? 12 : 8) {
            Image(systemName: "arrow.counterclockwise")
            Text("Terug naar de start")
        }
        .font(.system(size: isPad ? 25 : 17, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, isPad ? 22 : 16)
        .padding(.vertical, isPad ? 13 : 10)
        .background(Color(red: 0.06, green: 0.20, blue: 0.43).opacity(0.94), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.65), lineWidth: 2))
        .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
        .position(x: layout.size.width / 2, y: layout.size.height * 0.48)
        .transition(.scale(scale: 0.86).combined(with: .opacity))
        .zIndex(20)
    }

    // MARK: - Character choreography

    private var characterBack: some View {
        Group {
            if character.id == "dog" {
                StepDogSprite(frame: dogFrame)
            } else {
                HooklessCharacterArtwork(character: character)
            }
        }
    }

    private func choose(_ option: AnswerOption, lane: Int, layout: StepCourseLayout) {
        guard isLive, selectedOptionID == nil else { return }
        onTutorialMove()
        guard onSelect(option.id) else { return }

        animationToken &+= 1
        let token = animationToken
        animateDogJump(token: token)

        if option.isCorrect {
            playCorrectJump(toLane: lane,
                            token: token,
                            layout: layout)
        } else {
            playWrongJump(optionID: option.id,
                          lane: lane,
                          token: token,
                          layout: layout)
        }
    }

    private func animateDogJump(token: Int) {
        guard character.id == "dog" else { return }
        let timeline: [(frame: Int, time: Double)] = reduceMotion
            ? [(2, 0), (4, 0.04), (6, 0.08), (8, 0.12), (1, 0.17)]
            : [(2, 0), (3, 0.08), (4, 0.17), (5, 0.28),
               (6, 0.40), (7, 0.51), (8, 0.60), (1, 0.70)]
        for cue in timeline {
            DispatchQueue.main.asyncAfter(deadline: .now() + cue.time) {
                guard animationToken == token else { return }
                dogFrame = cue.frame
            }
        }
    }

    private func playCorrectJump(toLane lane: Int,
                                 token: Int,
                                 layout: StepCourseLayout) {
        let forwardX = layout.laneOffset(lane: lane, at: 0)
        let forwardY = layout.answerY - layout.baseY
        let standingX = layout.laneOffset(lane: lane, at: -1)
        cameraLaneOffset = 0
        hatchOpen = false
        currentRowNumbersMuted = false
        dogTracksAnswerRow = false
        jumpProgress = 0
        jumpDestinationX = forwardX - dogX
        jumpDestinationY = forwardY - dogY
        jumpLateralArc = (forwardX - dogX) * 0.08
        jumpHeight = layout.jumpHeight

        // Phase one: the dog really travels to the answer row while the world
        // remains still. This makes the choice readable and removes the slight
        // counter-motion caused by moving the camera during the jump itself.
        withAnimation(.timingCurve(0.24, 0.05, 0.24, 1,
                                   duration: reduceMotion ? 0.18 : 0.70)) {
            jumpProgress = 1
            dogScale = layout.scale(at: 0)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.18 : 0.70)) {
            guard animationToken == token else { return }
            landedLane = lane
            var landingTransaction = Transaction()
            landingTransaction.disablesAnimations = true
            withTransaction(landingTransaction) {
                dogX = forwardX
                dogY = forwardY
                jumpProgress = 0
                jumpDestinationX = 0
                jumpDestinationY = 0
                jumpLateralArc = 0
                jumpHeight = 0
            }
            rewardRise = 0
            rewardVisible = true
            withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                landingImpact = true
                rewardRise = isPad ? 52 : 34
            }
            // Only contact turns this completed row into background context.
            withAnimation(.easeOut(duration: reduceMotion ? 0.05 : 0.18)) {
                currentRowNumbersMuted = true
            }
            onRewardArrived()
        }

        // Phase two: after the landing, the camera catches up. The dog and its
        // tile follow the exact same perspective curve to the standing plane.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.20 : 0.74)) {
            guard animationToken == token else { return }
            dogTracksAnswerRow = true
            withAnimation(.timingCurve(0.32, 0.0, 0.20, 1,
                                       duration: reduceMotion ? 0.15 : 0.40)) {
                cameraPhase = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.35 : 1.14)) {
            guard animationToken == token else { return }
            var standingTransaction = Transaction()
            standingTransaction.disablesAnimations = true
            withTransaction(standingTransaction) {
                dogTracksAnswerRow = false
                dogX = standingX
                dogY = 0
                dogScale = 1
                landedRound = round
                landedLane = lane
            }
            withAnimation(.easeOut(duration: 0.16)) { landingImpact = false }
        }
    }

    private func playWrongJump(optionID: UUID,
                               lane: Int,
                               token: Int,
                               layout: StepCourseLayout) {
        // Until the dog has actually landed, this is deliberately identical
        // to a correct jump. The engine already knows the answer is wrong, but
        // the view withholds that information until the glass gives way.
        let forwardX = layout.laneOffset(lane: lane, at: 0)
        let forwardY = layout.answerY - layout.baseY
        let fallDirection: Double = forwardX < dogX ? -22 : 22
        pendingWrongID = optionID
        crackedID = nil
        brokenID = nil
        shatterProgress = 0
        cameraLaneOffset = 0
        currentRowNumbersMuted = false
        dogTracksAnswerRow = false
        jumpProgress = 0
        jumpDestinationX = forwardX - dogX
        jumpDestinationY = forwardY - dogY
        jumpLateralArc = (forwardX - dogX) * 0.08
        jumpHeight = layout.jumpHeight
        withAnimation(.timingCurve(0.24, 0.05, 0.24, 1,
                                   duration: reduceMotion ? 0.18 : 0.70)) {
            jumpProgress = 1
            dogScale = layout.scale(at: 0)
        }

        // Contact is the failure event: glass disappears into loose pieces and
        // the character starts falling on this same frame. There is no stable
        // standing pose on a tile the engine already knows is wrong.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.18 : 0.70)) {
            guard animationToken == token else { return }
            landedLane = lane
            var impactTransaction = Transaction()
            impactTransaction.disablesAnimations = true
            withTransaction(impactTransaction) {
                dogX = forwardX
                dogY = forwardY
                jumpProgress = 0
                jumpDestinationX = 0
                jumpDestinationY = 0
                jumpLateralArc = 0
                jumpHeight = 0
                crackedID = optionID
                brokenID = optionID
                shatterProgress = 0
            }
            withAnimation(.spring(response: 0.22, dampingFraction: 0.62)) {
                landingImpact = true
            }

            let outsideBoard = layout.size.height - layout.baseY
                + layout.dogSize * 1.35
            // Give SwiftUI one render pass with the fragments still occupying
            // the plate. On the next frame they and the character receive the
            // same falling animation, so the sheet visibly bursts instead of
            // cross-fading directly to already-displaced pieces.
            DispatchQueue.main.async {
                guard animationToken == token else { return }
                withAnimation(.easeIn(duration: reduceMotion ? 0.18 : 0.62)) {
                    shatterProgress = 1
                    dogY = outsideBoard
                    dogRotation = fallDirection
                    dogScale = 1
                    dogOpacity = 1
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.05 : 0.10)) {
                guard animationToken == token else { return }
                withAnimation(.easeOut(duration: reduceMotion ? 0.05 : 0.12)) {
                    landingImpact = false
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.45 : 1.46)) {
            guard animationToken == token else { return }
            dogFrame = 1
            dogOpacity = 0
            landedRound = nil
            restartMessageVisible = true

            let failedIndex = max(0, (round?.number ?? (currentStep + 1)) - 1)
            // The camera never advanced during the jump, so its absolute route
            // position is the current question index—not one step beyond it.
            rewindPosition = CGFloat(failedIndex)
            cameraPhase = 0
            DispatchQueue.main.async {
                guard animationToken == token else { return }
                withAnimation(.timingCurve(0.30, 0.02, 0.18, 1,
                                           duration: reduceMotion ? 0.16 : 0.62)) {
                    rewindPosition = 0
                }
            }
        }

        // Only after the camera has arrived at route position zero does the
        // hatch open and bring the character back onto the starting platform.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.64 : 2.12)) {
            guard animationToken == token else { return }
            cameraPhase = 0
            cameraLaneOffset = 0
            jumpProgress = 0
            jumpDestinationX = 0
            jumpDestinationY = 0
            jumpLateralArc = 0
            jumpHeight = 0
            landedRound = nil
            landedLane = 1
            dogX = 0
            dogY = isPad ? 150 : 105
            dogRotation = 0
            dogScale = 0.88
            dogOpacity = 0.68
            crackedID = nil
            hatchOpen = true
            characterAboveDeck = false
            liftPlatformVisible = true
            liftPlatformY = isPad ? 165 : 116
            dogY = liftPlatformY
        }

        // The opening gets its own readable beat. The lift then rises as a
        // single object instead of appearing and moving in the same frame.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.69 : 2.28)) {
            guard animationToken == token else { return }
            withAnimation(.spring(response: reduceMotion ? 0.18 : 0.46,
                                  dampingFraction: 0.76)) {
                dogY = 0
                liftPlatformY = 0
                dogScale = 1
                dogOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.83 : 2.68)) {
            guard animationToken == token else { return }
            characterAboveDeck = true
            liftPlatformVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.86 : 2.73)) {
            guard animationToken == token else { return }
            withAnimation(.easeInOut(duration: reduceMotion ? 0.08 : 0.18)) {
                hatchOpen = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.88 : 2.82)) {
            guard animationToken == token else { return }
            withAnimation(.easeOut(duration: 0.16)) { restartMessageVisible = false }
        }
    }

    private func resetForNextQuestion() {
        // The selected answer also clears when the final round ends. At that
        // boundary the finale owns the camera and character state; treating it
        // as an ordinary next question is what made the island visibly wiggle.
        guard !playsLevelCompletion, !victoryInProgress else { return }
        animationToken &+= 1
        pendingWrongID = nil
        crackedID = nil
        brokenID = nil
        shatterProgress = 0
        rewardVisible = false
        rewardRise = 0
        currentRowNumbersMuted = false
        landingImpact = false
        cameraPhase = 0
        cameraLaneOffset = 0
        jumpProgress = 0
        jumpDestinationX = 0
        jumpDestinationY = 0
        jumpLateralArc = 0
        jumpHeight = 0
        rewindPosition = nil
        dogTracksAnswerRow = false
        characterAboveDeck = true
        liftPlatformVisible = false
        liftPlatformY = 0
        victoryChestAttached = false
        victoryGoalDepth = nil
        if currentStep == 0 {
            landedRound = nil
            landedLane = 1
            dogX = 0
        }
        dogFrame = 1
        withAnimation(.easeOut(duration: reduceMotion ? 0.05 : 0.16)) {
            dogY = 0
            dogScale = 1
            dogRotation = 0
            dogOpacity = 1
            restartMessageVisible = false
            hatchOpen = false
        }
    }

    private func restoreLandingIfNeeded(layout: StepCourseLayout) {
        guard currentStep > 0, landedRound == nil else { return }
        let previousIndex = min(currentStep - 1, routeRounds.count - 1)
        guard routeRounds.indices.contains(previousIndex) else { return }
        let previous = routeRounds[previousIndex]
        let lane = previous.options.firstIndex(where: \.isCorrect) ?? 1
        landedRound = previous
        landedLane = lane
        dogX = layout.laneOffset(lane: lane, at: -1)
    }

    private func playEntrance(layout: StepCourseLayout) {
        guard !entranceCompleted else {
            onEntranceComplete()
            return
        }
        entranceCompleted = true
        animationToken &+= 1
        let token = animationToken
        victoryChestAttached = false
        victoryInProgress = false
        victoryGoalDepth = nil
        currentRowNumbersMuted = false
        dogTracksAnswerRow = false
        hatchOpen = true
        characterAboveDeck = false
        liftPlatformVisible = true
        liftPlatformY = layout.deckHeight * 0.88
        dogY = liftPlatformY
        dogScale = 0.88
        dogOpacity = 0.72
        dogFrame = 1

        // Let the iris finish opening before the platform rises through it.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.04 : 0.18)) {
            guard animationToken == token else { return }
            withAnimation(.spring(response: reduceMotion ? 0.18 : 0.58,
                                  dampingFraction: 0.76)) {
                dogY = 0
                liftPlatformY = 0
                dogScale = 1
                dogOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.25 : 0.82)) {
            guard animationToken == token else { return }
            characterAboveDeck = true
            liftPlatformVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.30 : 0.90)) {
            guard animationToken == token else { return }
            withAnimation(.easeInOut(duration: reduceMotion ? 0.08 : 0.20)) {
                hatchOpen = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.38 : 1.10)) {
            guard animationToken == token else { return }
            onEntranceComplete()
        }
    }

    private func playCompletion(layout: StepCourseLayout) {
        animationToken &+= 1
        let token = animationToken
        victoryInProgress = true
        victoryChestAttached = false
        rewardVisible = false
        landingImpact = false
        let lockedGoalDepth = max(0, goalCourseDepth - cameraPhase)
        victoryGoalDepth = lockedGoalDepth
        let destinationBaseY = layout.y(at: lockedGoalDepth)
            + layout.goalWidth(at: lockedGoalDepth) * 0.08
        let targetDogY = destinationBaseY - layout.baseY

        jumpProgress = 0
        jumpDestinationX = -dogX
        jumpDestinationY = targetDogY - dogY
        jumpLateralArc = -dogX * 0.06
        jumpHeight = layout.jumpHeight * 0.78
        animateDogJump(token: token)

        // One final, readable jump from the last glass row onto the island.
        withAnimation(.timingCurve(0.24, 0.05, 0.24, 1,
                                   duration: reduceMotion ? 0.22 : 0.82)) {
            jumpProgress = 1
            dogScale = 0.62
            dogRotation = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.20 : 0.82)) {
            guard animationToken == token else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dogX = 0
                dogY = targetDogY
                jumpProgress = 0
                jumpDestinationX = 0
                jumpDestinationY = 0
                jumpLateralArc = 0
                jumpHeight = 0
                dogFrame = 1
            }
        }

        // The island chest transfers into the dog's arms, then both leave the
        // board together in one celebratory jump above the viewport.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.28 : 1.02)) {
            guard animationToken == token else { return }
            withAnimation(.spring(response: 0.30, dampingFraction: 0.60)) {
                victoryChestAttached = true
                dogY = targetDogY - (isPad ? 10 : 6)
                dogRotation = -3
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.40 : 1.72)) {
            guard animationToken == token else { return }
            animateDogJump(token: token)
            withAnimation(.timingCurve(0.24, 0.02, 0.26, 1,
                                       duration: reduceMotion ? 0.24 : 0.88)) {
                dogY = -layout.size.height
                dogScale = 0.82
                dogRotation = -7
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.72 : 2.72)) {
            guard animationToken == token else { return }
            onLevelCompletionFinished()
        }
    }

    private func playTimeOut() {
        animationToken &+= 1
        withAnimation(.easeOut(duration: 0.25)) {
            dogScale = 0.92
            dogRotation = -5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
            onTimeOutFinished()
        }
    }
}

/// One continuous, animatable flight path. `progress` is interpolated by
/// SwiftUI, so the sine arc is recalculated every frame instead of connecting
/// two separately animated positions with a visible kink.
private struct StepJumpArcModifier: AnimatableModifier {
    var progress: CGFloat
    let destinationX: CGFloat
    let destinationY: CGFloat
    let lateralArc: CGFloat
    let height: CGFloat
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let p = min(1, max(0, progress))
        let arc = reduceMotion ? 0 : sin(.pi * p)
        let x = destinationX * p + lateralArc * arc
        let y = destinationY * p - height * arc
        let flightScale = 1 - arc * (reduceMotion ? 0 : 0.08)
        let tilt = Double(arc * min(1, abs(lateralArc) / 90))
            * (lateralArc < 0 ? -3 : 3)

        content
            .offset(x: x, y: y)
            .scaleEffect(flightScale, anchor: .bottom)
            .rotationEffect(.degrees(tilt))
    }
}

private struct StepLandingImpact: View {
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        ZStack {
            Ellipse()
                .stroke(.white.opacity(0.88), lineWidth: isPad ? 4 : 3)
            Ellipse()
                .stroke(character.color.opacity(0.78), lineWidth: isPad ? 9 : 6)
                .scaleEffect(0.72)
            HStack(spacing: isPad ? 54 : 36) {
                Circle().fill(.white.opacity(0.86))
                Circle().fill(.white.opacity(0.86))
            }
            .frame(height: isPad ? 10 : 7)
        }
        .shadow(color: character.skyColor.opacity(0.82), radius: isPad ? 10 : 7)
    }
}

// MARK: - Perspective layout

private struct StepTilePerspective {
    /// Scale of the support grid at the lower edge of the tile. The row frame
    /// uses this width so its lower corners sit exactly on the four beams.
    let bottomScale: CGFloat
    /// Scale along the full tile height, expressed relative to its lower edge.
    /// Using the full sample set avoids the visible overshoot that a single
    /// quadratic approximation produced on the large nearest row.
    let scaleRatios: [CGFloat]
}

private struct StepCourseLayout {
    let size: CGSize
    let isPad: Bool
    let topReserve: CGFloat
    let bottomReserve: CGFloat

    var promptY: CGFloat { topReserve + (isPad ? 54 : 45) }
    var promptWidth: CGFloat { min(size.width - (isPad ? 210 : 116), isPad ? 590 : 430) }
    /// The former horizon sat well inside the playfield, making both the last
    /// rail caps and the final rendered row visible. Put the convergence point
    /// just above the physical screen instead; HUD elements mask the bridge as
    /// it travels through the top safe-area band.
    var horizonY: CGFloat { isPad ? -56 : -44 }
    /// Keep the near end below the physical screen edge. Besides grounding the
    /// character lower in the frame, this lets the start deck continue past
    /// the home-indicator area instead of ending over a strip of empty sky.
    var baseY: CGFloat {
        min(size.height - bottomReserve - (isPad ? 34 : 20),
            size.height * 0.90)
    }
    /// Every row, including the answer row and landing row, uses the same
    /// perspective ratio. The iPad's taller course needs a slightly stronger
    /// contraction to preserve the established landing position.
    private var perspectiveRatio: CGFloat { isPad ? 0.73 : 0.75 }
    /// Width now contracts more slowly than before. Distant rails remain wide
    /// enough to read as four separate supports instead of merging to a spike.
    private var widthDecay: CGFloat { 0.88 }
    /// This floor is only reached after the rails are already above the screen.
    /// Keeping it below the visible scale prevents the old mid-curve kink.
    private var minimumCourseScale: CGFloat { 0.12 }
    private var goalWidthDecay: CGFloat { 0.84 }
    /// Ten rows put the last rendered glass completely above the viewport;
    /// rails continue farther still so their rounded caps are never visible.
    var offscreenRowDepth: Int { 10 }
    var offscreenRailDepth: CGFloat { 18 }
    var answerY: CGFloat { y(at: 0) }
    /// The bridge starts wider than the viewport, so the two outside supports
    /// leave the start deck just beyond the screen edges. The answer row has
    /// already converged enough to remain completely tappable.
    var courseWidth: CGFloat {
        min(size.width + (isPad ? 48 : 28), isPad ? 980 : 560)
    }
    /// The three lane cells meet on the centre of their support beams. Their
    /// own glass strokes remain the visible seam; a separate layout gap would
    /// make the plates float beside the construction again.
    var tileWidth: CGFloat { courseWidth / 3 }
    /// The authored dog has generous transparent canvas around it. At this
    /// size its visible body is roughly 50% larger than the first prototype.
    var dogSize: CGFloat { isPad ? 285 : 189 }
    /// The trapezoid's narrow top edge must also overhang the viewport; merely
    /// making its wider bottom edge screen-wide still exposes both side cuts.
    var deckWidth: CGFloat { size.width * 1.20 }
    var deckHeight: CGFloat { isPad ? 190 : 132 }
    var liftSize: CGFloat { min(deckHeight * 0.78, dogSize * 0.68) }
    var jumpHeight: CGFloat { min(isPad ? 210 : 145, (baseY - answerY) * 0.72) }
    private func naturalScale(at depth: CGFloat) -> CGFloat {
        if depth <= -1 { return 1 }
        if depth < 0 { return 0.92 - depth * 0.08 }
        return 0.92 * pow(widthDecay, depth)
    }

    private func naturalGoalScale(at depth: CGFloat) -> CGFloat {
        if depth <= -1 { return 1 }
        if depth < 0 { return 0.92 - depth * 0.08 }
        return 0.92 * pow(goalWidthDecay, depth)
    }

    func scale(at depth: CGFloat) -> CGFloat {
        max(minimumCourseScale, naturalScale(at: depth))
    }

    func y(at depth: CGFloat) -> CGFloat {
        horizonY + (baseY - horizonY) * pow(perspectiveRatio, depth + 1)
    }

    func tileHeight(at depth: CGFloat) -> CGFloat {
        tileWidth * (isPad ? 0.52 : 0.56) * scale(at: depth)
    }
    func rowWidth(at depth: CGFloat) -> CGFloat { courseWidth * scale(at: depth) }

    func goalWidth(at depth: CGFloat) -> CGFloat {
        // Unlike the rails, the island is allowed to keep shrinking beyond
        // the minimum course width. This keeps it genuinely hidden above the
        // screen until the final stretch, then lets it grow in naturally.
        let minimum = size.width * (isPad ? 0.11 : 0.10)
        let maximum = min(size.width * (isPad ? 0.70 : 0.78),
                          isPad ? 560 : 340)
        let naturalRowWidth = courseWidth * naturalGoalScale(at: depth)
        return min(maximum, max(minimum, naturalRowWidth * 1.18))
    }

    func laneOffset(lane: Int, at depth: CGFloat) -> CGFloat {
        CGFloat(min(max(lane, 0), 2) - 1) * tileWidth * scale(at: depth)
    }

    func laneDividerOffset(side: CGFloat, at depth: CGFloat) -> CGFloat {
        side * tileWidth * 0.5 * scale(at: depth)
    }

    private func depth(at verticalPosition: CGFloat) -> CGFloat {
        let distance = max(0.5, verticalPosition - horizonY)
        let fullDistance = max(1, baseY - horizonY)
        return log(distance / fullDistance) / log(perspectiveRatio) - 1
    }

    func tilePerspective(at depth: CGFloat) -> StepTilePerspective {
        let centerY = y(at: depth)
        let halfHeight = tileHeight(at: depth) / 2
        let bottomDepth = self.depth(at: centerY + halfHeight)
        let bottomScale = scale(at: bottomDepth)
        let sampleCount = 24
        var ratios = (0...sampleCount).map { sample in
            let progress = CGFloat(sample) / CGFloat(sampleCount)
            let verticalPosition = centerY - halfHeight
                + progress * halfHeight * 2
            return scale(at: self.depth(at: verticalPosition)) / bottomScale
        }
        // Remove floating-point drift at the shared lower corners.
        ratios[ratios.count - 1] = 1
        return StepTilePerspective(
            bottomScale: bottomScale,
            scaleRatios: ratios
        )
    }

    /// Horizontal position of one of the four continuous supports. These are
    /// the exact outside edges and lane seams used by every tile row.
    func supportOffset(boundary: Int, at depth: CGFloat) -> CGFloat {
        switch min(max(boundary, 0), 3) {
        case 0:
            return -rowWidth(at: depth) / 2
        case 1:
            return laneDividerOffset(side: -1, at: depth)
        case 2:
            return laneDividerOffset(side: 1, at: depth)
        default:
            return rowWidth(at: depth) / 2
        }
    }

    func courseCenterX(cameraPhase: CGFloat, laneOffset: CGFloat) -> CGFloat {
        size.width / 2 - laneOffset * cameraPhase * scale(at: -cameraPhase)
    }

    func opacity(at depth: CGFloat) -> Double {
        max(0.12, min(1, 1.08 - Double(depth) * 0.11))
    }
}

// MARK: - Course art

private struct StepCourseRails: View {
    let layout: StepCourseLayout
    let character: AnimalCharacter
    let farDepth: CGFloat

    var body: some View {
        Canvas { context, _ in
            let center = layout.size.width / 2
            let beamWidth: CGFloat = layout.isPad ? 16 : 11
            let innerWidth: CGFloat = layout.isPad ? 11 : 8
            let nearDepth: CGFloat = -1
            // Rails are permanent world construction, not part of the tile
            // that may leave the viewport. Continue them vertically behind
            // the character and just beyond the lower screen edge.
            let nearY = layout.size.height + beamWidth
            let farY = layout.y(at: farDepth)
            let beamGradient = Gradient(colors: [character.deepColor,
                                                  character.color,
                                                  character.skyColor])

            func strokeBeam(_ path: Path, width: CGFloat) {
                context.stroke(path, with: .color(.black.opacity(0.22)),
                               style: StrokeStyle(lineWidth: width + 6,
                                                  lineCap: .round,
                                                  lineJoin: .round))
                context.stroke(path,
                               with: .linearGradient(beamGradient,
                                                     startPoint: CGPoint(x: center, y: nearY),
                                                     endPoint: CGPoint(x: center, y: farY)),
                               style: StrokeStyle(lineWidth: width,
                                                  lineCap: .round,
                                                  lineJoin: .round))
                context.stroke(path, with: .color(.white.opacity(0.24)),
                               style: StrokeStyle(lineWidth: max(1.5, width * 0.20),
                                                  lineCap: .round))
            }

            // Sample the same depth curve that sizes and positions every row.
            // The former straight lines converged too early and consequently
            // crossed the first tiles instead of staying beneath their seams.
            for boundary in 0..<4 {
                let width = boundary == 0 || boundary == 3
                    ? beamWidth
                    : innerWidth
                var support = Path()
                support.move(to: CGPoint(x: center
                                            + layout.supportOffset(boundary: boundary,
                                                                   at: nearDepth),
                                         y: nearY))

                let sampleCount = 180
                for sample in 0...sampleCount {
                    let progress = CGFloat(sample) / CGFloat(sampleCount)
                    let depth = nearDepth + (farDepth - nearDepth) * progress
                    support.addLine(to: CGPoint(
                        x: center + layout.supportOffset(boundary: boundary,
                                                         at: depth),
                        y: layout.y(at: depth)
                    ))
                }
                strokeBeam(support, width: width)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct StepDecorativeRow: View {
    let character: AnimalCharacter
    let isPad: Bool
    let round: GameRound?
    let brokenOptionIDs: Set<UUID>
    let perspective: StepTilePerspective
    let activeLane: Int?

    var body: some View {
        GeometryReader { proxy in
            let width = max(1, proxy.size.width / 3)
            HStack(spacing: 0) {
                ForEach(Array((round?.options ?? []).prefix(3).enumerated()),
                        id: \.element.id) { lane, option in
                    Group {
                        if brokenOptionIDs.contains(option.id) {
                            BrokenStepGap(character: character,
                                          lane: lane,
                                          perspective: perspective)
                        } else {
                            GlassStepTile(text: option.text,
                                          lane: lane,
                                          perspective: perspective,
                                          character: character,
                                          isCracked: false,
                                          isBroken: false,
                                          shatterProgress: 0,
                                          shatterDistance: 0,
                                          isHighlighted: false,
                                          isNumberMuted: activeLane != lane)
                        }
                    }
                    .frame(width: width, height: proxy.size.height)
                }
            }
        }
    }
}

private struct BrokenStepGap: View {
    let character: AnimalCharacter
    let lane: Int
    let perspective: StepTilePerspective

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                BridgeLaneTileShape(lane: lane, perspective: perspective)
                    .stroke(character.skyColor.opacity(0.24),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 7]))

                ForEach(0..<3, id: \.self) { shard in
                    ShardShape()
                        .fill(LinearGradient(colors: [.white.opacity(0.70),
                                                      character.color.opacity(0.36)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: proxy.size.width * (shard == 1 ? 0.22 : 0.15),
                               height: proxy.size.height * (shard == 1 ? 0.25 : 0.18))
                        .rotationEffect(.degrees(Double(shard * 37 - 24)))
                        .offset(x: proxy.size.width * CGFloat(shard - 1) * 0.22,
                                y: proxy.size.height * (0.30 + CGFloat(shard % 2) * 0.12))
                }
            }
        }
    }
}

private struct ShardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.72))
        path.addLine(to: CGPoint(x: rect.width * 0.24, y: rect.maxY))
        path.addLine(to: .zero)
        path.closeSubpath()
        return path
    }
}

private struct StepStartDeck: View {
    let character: AnimalCharacter
    let isPad: Bool
    let hatchOpen: Bool

    var body: some View {
        GeometryReader { proxy in
            let hatchHeight = proxy.size.height * 0.68
            let hatchWidth = hatchHeight * 1.20
            let deckGradient = LinearGradient(colors: [Color.white.opacity(0.95),
                                                        Color(red: 0.35, green: 0.83, blue: 1.0),
                                                        character.color.opacity(0.62)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
            ZStack {
                GlassPerspectiveShape(inset: 0.035)
                    .fill(Color(red: 0.08, green: 0.37, blue: 0.60))
                    .offset(y: proxy.size.height * 0.12)

                GlassPerspectiveShape(inset: 0.045)
                    .fill(deckGradient)
                    .overlay {
                        GlassPerspectiveShape(inset: 0.045)
                            .stroke(character.skyColor, lineWidth: isPad ? 7 : 5)
                    }
                    .shadow(color: Color(red: 0.03, green: 0.20, blue: 0.44).opacity(0.34),
                            radius: 12, y: 9)

                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width * 0.16, y: proxy.size.height * 0.22))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.48, y: proxy.size.height * 0.09))
                }
                .stroke(.white.opacity(0.74),
                        style: StrokeStyle(lineWidth: isPad ? 4 : 2.5, lineCap: .round))

                // A flush oval iris replaces the permanent outlined square.
                // Closed, only a hairline seam remains in the glass. Opening
                // reveals the shaft while both surface halves slide sideways.
                ZStack {
                    Capsule()
                        .fill(LinearGradient(colors: [Color(red: 0.02, green: 0.12, blue: 0.25),
                                                      Color(red: 0.02, green: 0.30, blue: 0.46)],
                                             startPoint: .top,
                                             endPoint: .bottom))
                        .opacity(hatchOpen ? 1 : 0)

                    ForEach([-1.0, 1.0], id: \.self) { side in
                        Rectangle()
                            .fill(deckGradient)
                            .frame(width: hatchWidth * 0.52, height: hatchHeight)
                            .offset(x: CGFloat(side) * hatchWidth
                                        * (hatchOpen ? 0.68 : 0.25))
                            // When closed, the real deck surface is visible;
                            // no subtly mismatched oval patch remains behind.
                            .opacity(hatchOpen ? 1 : 0)
                    }

                    Rectangle()
                        .fill(Color(red: 0.04, green: 0.27, blue: 0.43).opacity(0.24))
                        .frame(width: isPad ? 2 : 1.5,
                               height: hatchHeight * 0.56)
                        .opacity(hatchOpen ? 0 : 1)
                }
                .frame(width: hatchWidth, height: hatchHeight)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color(red: 0.04, green: 0.22, blue: 0.39),
                                lineWidth: isPad ? 8 : 5)
                        .opacity(hatchOpen ? 1 : 0)
                }
                .shadow(color: .black.opacity(hatchOpen ? 0.48 : 0), radius: 8, y: 4)
                .animation(.timingCurve(0.30, 0.02, 0.20, 1,
                                        duration: 0.30),
                           value: hatchOpen)
            }
        }
    }
}

private struct StepLiftPlatform: View {
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [Color.white.opacity(0.94),
                                          Color(red: 0.30, green: 0.80, blue: 0.98),
                                          character.color.opacity(0.62)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.82), lineWidth: isPad ? 5 : 3)
            }
            .shadow(color: .black.opacity(0.34), radius: 6, y: 4)
    }
}

private struct StepHatchFrontLip: View {
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        ZStack {
            Capsule()
                .stroke(Color(red: 0.04, green: 0.22, blue: 0.39),
                        lineWidth: isPad ? 8 : 5)
            Capsule()
                .fill(LinearGradient(colors: [character.skyColor,
                                              Color(red: 0.08, green: 0.37, blue: 0.60)],
                                     startPoint: .top,
                                     endPoint: .bottom))
                .scaleEffect(x: 0.94, y: 0.36, anchor: .bottom)
        }
        .mask(alignment: .bottom) {
            Rectangle().frame(height: isPad ? 38 : 27)
        }
        .shadow(color: .black.opacity(0.34), radius: 5, y: 3)
    }
}

private struct StepGoalIsland: View {
    let character: AnimalCharacter
    let isPad: Bool
    let hidesChest: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Ellipse()
                    .fill(character.deepColor.opacity(0.38))
                    .frame(width: proxy.size.width * 0.84, height: proxy.size.height * 0.62)
                    .offset(y: proxy.size.height * 0.22)
                Ellipse()
                    .fill(LinearGradient(colors: [Color(red: 0.69, green: 0.91, blue: 0.25),
                                                  Color(red: 0.24, green: 0.66, blue: 0.18)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.60)
                    .offset(y: proxy.size.height * 0.03)
                if !hidesChest {
                    StepGoalChest()
                    .frame(width: proxy.size.width * 0.28, height: proxy.size.height * 0.36)
                    .offset(y: -proxy.size.height * 0.16)
                    .transition(.scale(scale: 0.35).combined(with: .opacity))
                }
                ForEach([-1.0, 1.0], id: \.self) { side in
                    VStack(spacing: 0) {
                        FlagShape()
                            .fill(side < 0 ? Color.pink : Color.orange)
                            .frame(width: proxy.size.width * 0.15, height: proxy.size.height * 0.18)
                        Rectangle()
                            .fill(Color.white.opacity(0.90))
                            .frame(width: 3, height: proxy.size.height * 0.30)
                    }
                    .offset(x: proxy.size.width * 0.28 * side, y: -proxy.size.height * 0.04)
                }
            }
        }
        .shadow(color: .black.opacity(0.22), radius: 7, y: 5)
    }
}

private struct StepGoalChest: View {
    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: proxy.size.height * 0.22,
                             style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.68, blue: 0.10),
                                              Color(red: 0.76, green: 0.30, blue: 0.03)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay {
                    Image(systemName: "star.fill")
                        .font(.system(size: proxy.size.height * 0.48, weight: .black))
                        .foregroundStyle(Color.yellow)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: proxy.size.height * 0.22,
                                     style: .continuous)
                        .stroke(.white.opacity(0.24), lineWidth: 1.5)
                }
                .shadow(color: .black.opacity(0.24), radius: 4, y: 3)
        }
    }
}

private struct FlagShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.28))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.62))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.76))
        path.closeSubpath()
        return path
    }
}

// MARK: - Background

private struct StepSky: View {
    let character: AnimalCharacter
    let travel: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [Color(red: 0.10, green: 0.57, blue: 0.96),
                                        Color(red: 0.29, green: 0.75, blue: 1.0),
                                        character.skyColor, Color.white],
                               startPoint: .top, endPoint: .bottom)
                Circle()
                    .fill(.white.opacity(0.30))
                    .frame(width: proxy.size.width * 0.74)
                    .blur(radius: 34)
                    .position(x: proxy.size.width * 0.18,
                              y: proxy.size.height
                                * (0.22 + sin(travel * 0.24) * 0.018))
                ForEach(0..<8, id: \.self) { index in
                    let cloudWidth = CGFloat(76 + index * 17)
                    let cloudHeight = CGFloat(38 + index % 3 * 8)
                    let margin = cloudHeight
                    let span = proxy.size.height + margin * 2
                    let unwrappedY = proxy.size.height * CGFloat(14 + index * 11) / 100
                        + travel * CGFloat(10 + index * 2)
                    let wrappedY = (unwrappedY + margin)
                        .truncatingRemainder(dividingBy: span) - margin
                    StepCloud(seed: index)
                        .frame(width: cloudWidth, height: cloudHeight)
                        .position(x: proxy.size.width * CGFloat((index * 41 + 7) % 108) / 100,
                                  y: wrappedY)
                        .opacity(0.54 + Double(index % 3) * 0.10)
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct FloatingWorld: View {
    let character: AnimalCharacter
    let isPad: Bool
    let travel: CGFloat

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<7, id: \.self) { index in
                    let islandHeight = isPad
                        ? CGFloat(135 + index * 7)
                        : CGFloat(78 + index * 4)
                    let margin = islandHeight
                    let span = proxy.size.height + margin * 2
                    let unwrappedY = proxy.size.height
                        * CGFloat(0.28 + Double(index) * 0.105)
                        + travel * CGFloat(9 + index * 3)
                    let wrappedY = (unwrappedY + margin)
                        .truncatingRemainder(dividingBy: span) - margin
                    FloatingIsland(character: character, seed: index)
                        .frame(width: isPad ? CGFloat(150 + index * 8) : CGFloat(86 + index * 5),
                               height: islandHeight)
                        .position(x: index.isMultiple(of: 2) ? proxy.size.width * 0.08 : proxy.size.width * 0.92,
                                  y: wrappedY)
                        .opacity(0.66 + Double(index % 2) * 0.20)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FloatingIsland: View {
    let character: AnimalCharacter
    let seed: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width * 0.12, y: proxy.size.height * 0.23))
                    path.addCurve(to: CGPoint(x: proxy.size.width * 0.88, y: proxy.size.height * 0.23),
                                  control1: CGPoint(x: proxy.size.width * 0.30, y: proxy.size.height * 0.08),
                                  control2: CGPoint(x: proxy.size.width * 0.70, y: proxy.size.height * 0.08))
                    path.addLine(to: CGPoint(x: proxy.size.width * 0.65, y: proxy.size.height * 0.94))
                    path.addCurve(to: CGPoint(x: proxy.size.width * 0.12, y: proxy.size.height * 0.23),
                                  control1: CGPoint(x: proxy.size.width * 0.48, y: proxy.size.height),
                                  control2: CGPoint(x: proxy.size.width * 0.22, y: proxy.size.height * 0.58))
                    path.closeSubpath()
                }
                .fill(LinearGradient(colors: [character.deepColor.opacity(0.74),
                                              Color(red: 0.34, green: 0.28, blue: 0.52).opacity(0.72)],
                                     startPoint: .top, endPoint: .bottom))
                Ellipse()
                    .fill(LinearGradient(colors: [Color(red: 0.76, green: 0.93, blue: 0.29),
                                                  Color(red: 0.28, green: 0.66, blue: 0.18)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: proxy.size.width * 0.92, height: proxy.size.height * 0.30)
                    .offset(y: proxy.size.height * 0.08)
                Circle()
                    .fill(Color(red: 0.20, green: 0.58, blue: 0.20))
                    .frame(width: proxy.size.width * 0.25)
                    .offset(x: (seed.isMultiple(of: 2) ? -1 : 1) * proxy.size.width * 0.18,
                            y: -proxy.size.height * 0.02)
            }
        }
    }
}

private struct StepCloud: View {
    let seed: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Capsule().fill(.white)
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.58)
                    .offset(y: proxy.size.height * 0.18)
                Circle().fill(.white)
                    .frame(width: proxy.size.height * 0.74)
                    .offset(x: -proxy.size.width * 0.20, y: -proxy.size.height * 0.03)
                Circle().fill(.white.opacity(seed.isMultiple(of: 2) ? 0.96 : 0.90))
                    .frame(width: proxy.size.height * 0.92)
                    .offset(x: proxy.size.width * 0.08, y: -proxy.size.height * 0.10)
            }
            .blur(radius: 2.2)
            .shadow(color: Color.blue.opacity(0.14), radius: 7, y: 5)
        }
    }
}

private struct StepCloudCurtain: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(0.38)
                ForEach(0..<8, id: \.self) { index in
                    StepCloud(seed: index)
                        .frame(width: proxy.size.width * 0.58, height: proxy.size.height * 0.15)
                        .position(x: proxy.size.width * (index.isMultiple(of: 2) ? 0.18 : 0.80),
                                  y: proxy.size.height * CGFloat(0.13 + Double(index) * 0.115))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Tile and character art

private struct GlassStepTile: View {
    let text: String
    let lane: Int
    let perspective: StepTilePerspective
    let character: AnimalCharacter
    let isCracked: Bool
    let isBroken: Bool
    let shatterProgress: CGFloat
    let shatterDistance: CGFloat
    let isHighlighted: Bool
    let isNumberMuted: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Group {
                    BridgeLaneTileShape(lane: lane, perspective: perspective)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.96),
                                                      Color(red: 0.36, green: 0.84, blue: 1.0).opacity(0.92),
                                                      character.color.opacity(0.50)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .overlay {
                            BridgeLaneTileShape(lane: lane, perspective: perspective)
                                .stroke(character.skyColor, lineWidth: 2.5)
                        }
                        .overlay {
                            BridgeLaneTileShape(lane: lane, perspective: perspective)
                                .stroke(.white.opacity(0.40), lineWidth: 1)
                                .padding(5)
                        }
                        .background {
                            BridgeLaneTileShape(lane: lane, perspective: perspective)
                                .fill(Color(red: 0.10, green: 0.45, blue: 0.68))
                                .offset(y: proxy.size.height * 0.14)
                        }
                        .shadow(color: Color(red: 0.03, green: 0.20, blue: 0.44).opacity(0.32),
                                radius: 7, y: 7)

                    Path { path in
                        path.move(to: CGPoint(x: proxy.size.width * 0.18,
                                              y: proxy.size.height * 0.22))
                        path.addLine(to: CGPoint(x: proxy.size.width * 0.50,
                                                y: proxy.size.height * 0.10))
                    }
                    .stroke(.white.opacity(0.70),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))

                    if !text.isEmpty {
                        Text(verbatim: text)
                            .font(.system(size: min(proxy.size.width * 0.30, 42),
                                          weight: .black, design: .rounded))
                            .foregroundStyle(Color(red: 0.03, green: 0.18, blue: 0.43)
                                .opacity(isNumberMuted ? 0.34 : 1))
                            .minimumScaleFactor(0.42)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .shadow(color: .white.opacity(0.88), radius: 1)
                    }
                    if isHighlighted {
                        BridgeLaneTileShape(lane: lane, perspective: perspective)
                            .stroke(.white, style: StrokeStyle(lineWidth: 4, dash: [8, 6]))
                            .shadow(color: character.color, radius: 10)
                    }
                    if isCracked {
                        GlassCracks()
                            .stroke(Color(red: 0.04, green: 0.18, blue: 0.38).opacity(0.84),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .padding(7)
                    }
                }
                .opacity(isBroken ? 0 : 1)

                if isBroken {
                    GlassShatterLayer(character: character,
                                      progress: shatterProgress,
                                      fallDistance: shatterDistance)
                }
            }
        }
    }
}

/// Eighteen small, irregular pieces cover the former plate at progress zero.
/// Every piece has its own sideways impulse and spin, while all of them use
/// the same accelerating fall as the character.
private struct GlassShatterLayer: View {
    let character: AnimalCharacter
    let progress: CGFloat
    let fallDistance: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let p = min(1, max(0, progress))
            ZStack {
                ForEach(0..<18, id: \.self) { index in
                    let column = index % 6
                    let row = index / 6
                    let direction: CGFloat = column < 3 ? -1 : 1
                    let alternating: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                    let drift = direction * (0.20 + CGFloat((index * 7) % 5) * 0.09)
                        + alternating * 0.05
                    let spin = Double((index.isMultiple(of: 2) ? -1 : 1)
                                      * (95 + (index * 41) % 210))
                    let delayedFall = p * p
                    let pieceWidth = proxy.size.width
                        * (0.145 + CGFloat((index * 5) % 4) * 0.012)
                    let pieceHeight = proxy.size.height
                        * (0.29 + CGFloat((index * 5) % 3) * 0.025)

                    GlassFragmentShape(variant: index % 4)
                        .fill(LinearGradient(colors: [Color.white.opacity(0.92),
                                                      Color(red: 0.42,
                                                            green: 0.88,
                                                            blue: 1.0).opacity(0.82),
                                                      character.color.opacity(0.48)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .overlay {
                            GlassFragmentShape(variant: index % 4)
                                .stroke(.white.opacity(0.78), lineWidth: 1)
                        }
                        .frame(width: pieceWidth, height: pieceHeight)
                        .rotation3DEffect(.degrees(Double(p) * Double(80 + (index * 29) % 170)),
                                          axis: (x: 1, y: alternating, z: 0),
                                          perspective: 0.55)
                        .rotationEffect(.degrees(Double((index % 5) - 2) * 3 + spin * Double(p)))
                        .scaleEffect(1 - p * 0.18)
                        .position(x: proxy.size.width
                                    * (CGFloat(column) + 0.5) / 6,
                                  y: proxy.size.height
                                    * (CGFloat(row) + 0.5) / 3)
                        .offset(x: proxy.size.width * drift * p,
                                y: delayedFall
                                    * (fallDistance
                                       + proxy.size.height * CGFloat((index * 11) % 5) * 0.28))
                        .shadow(color: character.skyColor.opacity(0.30), radius: 2, y: 2)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct GlassFragmentShape: Shape {
    let variant: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch variant {
        case 0:
            path.move(to: CGPoint(x: rect.width * 0.12, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.16))
            path.addLine(to: CGPoint(x: rect.width * 0.82, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.72))
        case 1:
            path.move(to: CGPoint(x: rect.width * 0.28, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.30))
            path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.84))
            path.addLine(to: CGPoint(x: rect.width * 0.08, y: rect.height * 0.18))
        case 2:
            path.move(to: CGPoint(x: 0, y: rect.height * 0.16))
            path.addLine(to: CGPoint(x: rect.width * 0.78, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.76))
            path.addLine(to: CGPoint(x: rect.width * 0.32, y: rect.maxY))
        default:
            path.move(to: CGPoint(x: rect.width * 0.18, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.10))
            path.addLine(to: CGPoint(x: rect.width * 0.90, y: rect.height * 0.72))
            path.addLine(to: CGPoint(x: rect.width * 0.44, y: rect.maxY))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.56))
        }
        path.closeSubpath()
        return path
    }
}

/// The four boundaries are sampled from the exact same curve as the support
/// beams. Adjacent lanes reuse one boundary, so their shared seam cannot drift
/// apart; the outside edges curve with the two outer beams as well.
private struct BridgeLaneTileShape: Shape {
    let lane: Int
    let perspective: StepTilePerspective

    func path(in rect: CGRect) -> Path {
        let safeLane = min(max(lane, 0), 2)
        let leftBoundary = CGFloat(safeLane) - 1.5
        let rightBoundary = leftBoundary + 1
        let ratios = perspective.scaleRatios.count > 1
            ? perspective.scaleRatios
            : [1, 1]

        func point(boundary: CGFloat, sample: Int) -> CGPoint {
            let progress = CGFloat(sample) / CGFloat(ratios.count - 1)
            return CGPoint(
                x: (boundary * ratios[sample] - leftBoundary) * rect.width,
                y: rect.minY + progress * rect.height
            )
        }

        var path = Path()
        path.move(to: point(boundary: leftBoundary, sample: 0))
        path.addLine(to: point(boundary: rightBoundary, sample: 0))
        for sample in 1..<ratios.count {
            path.addLine(to: point(boundary: rightBoundary, sample: sample))
        }
        for sample in stride(from: ratios.count - 1, through: 0, by: -1) {
            path.addLine(to: point(boundary: leftBoundary, sample: sample))
        }
        path.closeSubpath()
        return path
    }
}

private struct GlassPerspectiveShape: Shape {
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * inset, y: 0))
        path.addLine(to: CGPoint(x: rect.width * (1 - inset), y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct GlassCracks: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        let ends = [CGPoint(x: rect.minX, y: rect.minY + 4),
                    CGPoint(x: rect.maxX - 3, y: rect.minY),
                    CGPoint(x: rect.maxX, y: rect.maxY - 5),
                    CGPoint(x: rect.width * 0.28, y: rect.maxY),
                    CGPoint(x: rect.minX, y: rect.midY)]
        for (index, end) in ends.enumerated() {
            path.move(to: center)
            let kink = CGPoint(x: (center.x + end.x) / 2 + (index.isMultiple(of: 2) ? 5 : -5),
                               y: (center.y + end.y) / 2)
            path.addLine(to: kink)
            path.addLine(to: end)
        }
        return path
    }
}

private struct StepDogSprite: View {
    let frame: Int

    var body: some View {
#if canImport(UIKit)
        Image(uiImage: StepDogSpriteCache.image(frame: frame))
            .resizable()
            .scaledToFit()
            .id(frame)
#else
        Image("1.\(min(max(frame, 1), 8))")
            .resizable()
            .scaledToFit()
            .id(frame)
#endif
    }
}

#if canImport(UIKit)
private enum StepDogSpriteCache {
    private static let lock = NSLock()
    private static var images: [Int: UIImage] = [:]

    static func image(frame: Int) -> UIImage {
        let frame = min(max(frame, 1), 8)
        lock.lock()
        if let cached = images[frame] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        // The on-screen dog is at most 285pt. A 720px prepared image keeps the
        // authored fur crisp on Retina screens without uploading all eight
        // original 1254px canvases during every jump.
        let prepared = DisplayPreparedImage.make(named: "1.\(frame)", maxPixel: 720)
        lock.lock()
        images[frame] = prepared
        lock.unlock()
        return prepared
    }

    static func prewarm() {
        for frame in 1...8 { _ = image(frame: frame) }
    }
}
#endif
