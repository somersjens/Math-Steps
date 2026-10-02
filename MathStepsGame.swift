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

private struct QueuedStepAnswer: Equatable {
    let roundID: UUID
    let optionID: UUID
    let lane: Int
}

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
    let bottomReserve: CGFloat
    /// Centre of the score capsule in this playfield's coordinate space.
    /// Keeping the destination explicit makes the reward flight land on the
    /// HUD on every device size instead of aiming at a tuned screen corner.
    let scoreTarget: CGPoint
    let onSelect: (UUID) -> Bool
    let onRewardArrived: () -> Void
    let onCorrectLanding: () -> Void
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
    // A new run opens on the level card. Keep the character fully below the
    // stage until the entrance choreography has positioned it in the shaft;
    // otherwise its first, standing frame flashes behind the card.
    @State private var dogOpacity = 0.0
    /// Advances only the small sprite view. Keeping authored frame changes out
    /// of this parent prevents them from interrupting an in-flight camera and
    /// answer-label animation.
    @State private var dogAnimationID = 0
    @State private var jumpProgress: CGFloat = 0
    @State private var jumpDestinationX: CGFloat = 0
    @State private var jumpDestinationY: CGFloat = 0
    @State private var jumpLateralArc: CGFloat = 0
    @State private var jumpHeight: CGFloat = 0
    @State private var jumpFallsThrough = false
    @State private var jumpFallDestinationY: CGFloat = 0
    @State private var jumpFallRotation = 0.0
    @State private var landedRound: GameRound?
    @State private var landedLane = 1
    /// The standing answer row stays visually active during flight. Only the
    /// actual landing turns all three numbers into background information.
    @State private var currentRowNumbersMuted = false
    @State private var landingImpact = false
    @State private var landingBurstProgress: CGFloat = 0
    @State private var hatchOpen = false
    @State private var liftPlatformY: CGFloat = 0
    @State private var liftPlatformVisible = false
    @State private var liftPlatformAboveDeck = false
    @State private var characterAboveDeck = true
    @State private var pendingWrongID: UUID?
    @State private var crackedID: UUID?
    @State private var brokenID: UUID?
    /// Drives the loose pieces of a failed glass tile. It starts at the exact
    /// contact frame and shares the character's downward acceleration.
    @State private var shatterProgress: CGFloat = 0
    @State private var rewardVisible = false
    @State private var rewardFlightProgress: CGFloat = 0
    @State private var rewardSource = CGPoint.zero
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
    /// Remains true across the brief parent-state hand-off after a landing.
    /// A tap on the newly revealed row is queued until the completed jump has
    /// been committed locally, preventing two camera phases from overlapping.
    @State private var answerJumpInProgress = false
    @State private var queuedAnswer: QueuedStepAnswer?
    /// The model may publish the next round while the landing impact is still
    /// finishing. Do not normalize the camera in that render pass: remember
    /// the requested reset and apply it when the local jump actually ends.
    @State private var nextQuestionResetPending = false
    /// Continuous world-space progress owned by the renderer. The model
    /// publishes `round`, `currentStep` and `selectedOptionID` separately; using
    /// any combination of those values directly can move the finish island for
    /// one intermediate render at every round boundary.
    @State private var routeProgress: CGFloat = 0
    /// Absolute route boundary immediately before the tile that caused the
    /// latest fall. Subtracting world travel keeps the marker fixed to the
    /// course while the player climbs toward and eventually past it.
    @State private var checkpointBoundary: CGFloat?

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

    /// Places the character's authored ground-contact point exactly at the
    /// centre of the square lift, rather than tuning it with a visual offset.
    private func startPadDogY(layout: StepCourseLayout) -> CGFloat {
        layout.liftCenterY(cameraPhase: 0) - layout.baseY
    }

    /// Model advancement and the local camera reset arrive in two consecutive
    /// SwiftUI updates. Render a newly opened round at phase zero immediately,
    /// so its labels never spend one frame on the previous row's position.
    private var renderedCameraPhase: CGFloat {
        if selectedOptionID == nil,
           rewindPosition == nil,
           !victoryInProgress {
            return 0
        }
        return cameraPhase
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = StepCourseLayout(size: proxy.size,
                                          isPad: isPad,
                                          bottomReserve: bottomReserve)
            let characterSize = character.id == "dog"
                ? layout.dogSize
                : layout.dogSize / 1.5
            let characterFootprint = StepCharacterFootprint(
                character: character,
                renderedSide: characterSize
            )
            let visualCameraPhase = renderedCameraPhase
            let goalDepth = victoryGoalDepth
                ?? max(0, CGFloat(routeRoundCount) - routeProgress)
            // The four supports belong to the route itself. End them inside
            // the destination's landing collar: the island then hides their
            // caps and the bridge never appears to continue past the finish.
            let railEndDepth = goalDepth
            // Background parallax and the finish island share the same
            // renderer-owned world position. This remains continuous while
            // the model publishes the next question in several updates.
            let worldTravel = rewindPosition ?? routeProgress

            ZStack {
                StepSky(character: character, travel: worldTravel)
                FloatingWorld(character: character, isPad: isPad, travel: worldTravel)
                if routeRoundCount > 0 {
                    StepCourseRails(layout: layout,
                                    character: character,
                                    farDepth: railEndDepth)
                }
                if let checkpointBoundary {
                    checkpointFlag(layout: layout,
                                   absoluteDepth: checkpointBoundary,
                                   worldTravel: worldTravel)
                }
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
                // Before `begin()` has planned the route, a zero-length route
                // would place the destination at depth one in the middle of
                // the screen. It does not exist visually until that plan does.
                if routeRoundCount > 0 {
                    goalIsland(layout: layout, depth: goalDepth)
                        .opacity(rewindPosition == nil ? 1 : 0)
                }

                // This is a contact shadow on the world surface, rather than
                // a drop shadow attached to the artwork. It follows the feet
                // between the start pad and answer stones while the character
                // itself rises through the jump arc.
                StepCharacterGroundShadow(character: character)
                    .frame(width: characterFootprint.width,
                           height: characterFootprint.depth)
                    .scaleEffect(dogScale)
                    .position(x: layout.size.width / 2 + dogX,
                              y: layout.baseY + dogY
                                + characterFootprint.verticalOffset)
                    .modifier(StepGroundShadowMotionModifier(
                        progress: jumpProgress,
                        destinationX: jumpDestinationX,
                        destinationY: jumpDestinationY,
                        lateralArc: jumpLateralArc,
                        fallsThrough: jumpFallsThrough,
                        reduceMotion: reduceMotion
                    ))
                    .opacity(dogOpacity * (victoryChestAttached ? 0 : 1))
                    .animation(.easeOut(duration: 0.18),
                               value: victoryChestAttached)
                    // The shadow belongs to the lift surface, not to the
                    // character's foreground layer. Keep it below the deck
                    // until the platform itself is flush.
                    .zIndex(liftPlatformAboveDeck ? 7.2 : 2.5)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

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
                    .scaleEffect(dogScale)
                    .rotationEffect(.degrees(dogRotation))
                    .opacity(dogOpacity)
                    .position(x: layout.size.width / 2 + dogX,
                              y: layout.baseY - characterSize * 0.43 + dogY)
                    .modifier(StepJumpArcModifier(progress: jumpProgress,
                                                  destinationX: jumpDestinationX,
                                                  destinationY: jumpDestinationY,
                                                  lateralArc: jumpLateralArc,
                                                  height: jumpHeight,
                                                  fallsThrough: jumpFallsThrough,
                                                  fallDestinationY: jumpFallDestinationY,
                                                  fallRotation: jumpFallRotation,
                                                  preservesScale: victoryInProgress
                                                    && !victoryChestAttached,
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
                    let impactDepth = -visualCameraPhase
                    StepCorrectBurst(character: character,
                                     isPad: isPad,
                                     progress: landingBurstProgress,
                                     reduceMotion: reduceMotion)
                        .frame(width: layout.tileWidth * layout.scale(at: impactDepth) * 1.28,
                               height: layout.tileHeight(at: impactDepth) * 1.45)
                        .position(x: layout.size.width / 2
                                    + layout.laneOffset(lane: landedLane,
                                                        at: impactDepth),
                                  y: layout.y(at: impactDepth))
                        .zIndex(9.2)
                        .allowsHitTesting(false)
                }

                // Once raised, the square lift top stays behind as a flush
                // piece of the starting deck. It disappears only when that
                // deck itself is replaced by the first completed step.
                if liftPlatformVisible, landedRound == nil {
                    StepLiftPlatform(character: character, isPad: isPad)
                        .frame(width: layout.liftSize,
                               height: layout.liftHeight)
                        .scaleEffect(1 + renderedCameraPhase * 0.08)
                        .position(x: layout.size.width / 2,
                                  y: layout.liftCenterY(cameraPhase: renderedCameraPhase)
                                    + liftPlatformY)
                        // The lift stays underneath the rear deck and is seen
                        // through its opening. At the top it becomes the flush
                        // floor between that rear deck and the near edge.
                        .zIndex(liftPlatformAboveDeck ? 7 : 2.8)
                        .allowsHitTesting(false)
                }

                // Only the narrow strip below the opening is foreground. The
                // remainder of the start deck was drawn earlier and stays
                // behind the character. Together these two permanent layers
                // let the character rise through the hole without a timed
                // whole-sprite z-index swap.
                if landedRound == nil,
                   rewindPosition.map({ $0 <= 0.001 }) ?? true {
                    startDeckForeground(layout: layout)
                }

                if rewardVisible {
                    StepFlyingScoreNut(character: character,
                                       isPad: isPad,
                                       progress: rewardFlightProgress,
                                       source: rewardSource,
                                       target: scoreTarget,
                                       reduceMotion: reduceMotion)
                        .zIndex(30)
                        .allowsHitTesting(false)
                }

                if restartMessageVisible { restartBadge(layout: layout) }
            }
            // A failed first sum deliberately presents the exact same planned
            // round again, including the same UUID. Input unlocking is the
            // reliable round boundary for both that case and normal progress.
            .onChange(of: selectedOptionID) { previous, current in
                if previous != nil, current == nil {
                    requestNextQuestionReset(layout: layout)
                }
            }
            .onChange(of: answerJumpInProgress) { wasInProgress, isInProgress in
                if wasInProgress, !isInProgress, nextQuestionResetPending {
                    resetForNextQuestion(layout: layout)
                }
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
            .onChange(of: highestStep) { _, newValue in
                // A replay resets the model without necessarily recreating
                // this view, so discard the marker from the previous run.
                if newValue == 0 { checkpointBoundary = nil }
            }
            .onAppear {
#if canImport(UIKit)
                // Frame 1 is already needed for the first render. Decode the
                // seven jump frames away from the main actor so opening the
                // level and animating its start card stay responsive.
                Task.detached(priority: .utility) {
                    StepDogSpriteCache.prewarm()
                }
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
                    let depth = CGFloat(row) - renderedCameraPhase
                    let perspective = layout.tilePerspective(at: depth)
                    let routeIndex = standingIndex + row
                    StepDecorativeRow(character: character,
                                      isPad: isPad,
                                      round: routeRounds[routeIndex],
                                      brokenOptionIDs: brokenRouteOptionIDs,
                                      perspective: perspective,
                                      mutesNumbers: true,
                                      usesDetailedEffects: false)
                        .frame(width: layout.courseWidth * perspective.bottomScale,
                               height: layout.tileHeight(at: depth))
                        .position(x: layout.courseCenterX(cameraPhase: renderedCameraPhase,
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
                                      mutesNumbers: true,
                                      usesDetailedEffects: false)
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
        let depth = -renderedCameraPhase
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
        .position(x: layout.courseCenterX(cameraPhase: renderedCameraPhase,
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
                let isFreshLanding = selectedOptionID != nil
                    && landedRound.id == round?.id
                let depth = victoryInProgress || isFreshLanding
                    ? -1
                    : -1 - renderedCameraPhase
                let perspective = layout.tilePerspective(at: depth)
                StepDecorativeRow(character: character,
                                  isPad: isPad,
                                  round: landedRound,
                                  brokenOptionIDs: brokenRouteOptionIDs,
                                  perspective: perspective,
                                  mutesNumbers: true,
                                  usesDetailedEffects: true)
                    .frame(width: layout.courseWidth * perspective.bottomScale,
                           height: layout.tileHeight(at: depth))
                    .position(x: layout.size.width / 2,
                              y: layout.y(at: depth))
            } else {
                let deckDepth = -1 - renderedCameraPhase
                StepStartDeck(character: character,
                              isPad: isPad,
                              hatchOpen: hatchOpen)
                    .frame(width: layout.deckWidth, height: layout.deckHeight)
                    .position(x: layout.size.width / 2,
                              y: layout.y(at: deckDepth) + layout.deckHeight * 0.14)
                    .scaleEffect(1 + renderedCameraPhase * 0.08)
            }
        }
        .zIndex(4)
        .allowsHitTesting(false)
    }

    /// The start pad has one fixed depth split. Everything above the hatch's
    /// near edge is scenery behind the character; only the short strip from
    /// that edge to the bottom of the screen is allowed to pass in front.
    private func startDeckForeground(layout: StepCourseLayout) -> some View {
        let deckDepth = -1 - renderedCameraPhase
        return StepStartDeckForeground(character: character, isPad: isPad)
            .frame(width: layout.deckWidth, height: layout.deckHeight)
            .position(x: layout.size.width / 2,
                      y: layout.y(at: deckDepth) + layout.deckHeight * 0.14)
            .scaleEffect(1 + renderedCameraPhase * 0.08)
            .zIndex(8.5)
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
            .frame(width: width, height: layout.goalHeight(for: width))
            .position(x: layout.size.width / 2,
                      y: layout.y(at: depth))
            .allowsHitTesting(false)
    }

    private func checkpointFlag(layout: StepCourseLayout,
                                absoluteDepth: CGFloat,
                                worldTravel: CGFloat) -> some View {
        let depth = absoluteDepth - worldTravel
        let perspectiveScale = layout.scale(at: depth)
        let width = (isPad ? CGFloat(72) : CGFloat(48)) * perspectiveScale
        let height = (isPad ? CGFloat(68) : CGFloat(46)) * perspectiveScale
        let railX = layout.size.width / 2
            + layout.supportOffset(boundary: 3, at: depth)
        let railY = layout.y(at: depth)

        return StepCheckpointFlag(character: character, isPad: isPad)
            .frame(width: width, height: height)
            // The pole occupies the leading edge and ends at the lower-left
            // corner. Positioning the scaled frame from that corner plants it
            // exactly on the sampled right support at every perspective depth.
            .position(x: railX + width / 2,
                      y: railY - height / 2)
            .opacity(layout.opacity(at: depth))
            .zIndex(6.6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
                StepDogSprite(animationID: dogAnimationID,
                              reduceMotion: reduceMotion)
            } else {
                HooklessCharacterArtwork(character: character)
            }
        }
    }

    private func choose(_ option: AnswerOption, lane: Int, layout: StepCourseLayout) {
        guard isLive, selectedOptionID == nil else { return }

        // The parent can publish the next round one render pass before this
        // view has committed the previous landing. Accept that early tap, but
        // defer resolving it until the local camera and jump state are stable.
        if answerJumpInProgress {
            guard queuedAnswer == nil, let roundID = round?.id else { return }
            queuedAnswer = QueuedStepAnswer(roundID: roundID,
                                            optionID: option.id,
                                            lane: lane)
            return
        }

        // A correct answer only changes the visible high-water score when the
        // next step lies beyond the best step already reached this run.
        let earnsNewHighestStep = option.isCorrect && currentStep >= highestStep

        onTutorialMove()
        guard onSelect(option.id) else { return }
        answerJumpInProgress = true

        animationToken &+= 1
        let token = animationToken
        animateDogJump(token: token)

        if option.isCorrect {
            playCorrectJump(toLane: lane,
                            token: token,
                            layout: layout,
                            earnsNewHighestStep: earnsNewHighestStep)
        } else {
            playWrongJump(optionID: option.id,
                          lane: lane,
                          token: token,
                          layout: layout,
                          failedRouteIndex: currentRouteIndex)
        }
    }

    private func animateDogJump(token: Int) {
        guard character.id == "dog", animationToken == token else { return }
        dogAnimationID &+= 1
    }

    private func playCorrectJump(toLane lane: Int,
                                 token: Int,
                                 layout: StepCourseLayout,
                                 earnsNewHighestStep: Bool) {
        let jump = prepareAnswerJump(toLane: lane,
                                     fallsThrough: false,
                                     layout: layout)
        // The landing callback, rather than a fixed model timer, opens the next
        // round as soon as this visible movement is complete.
        let travelDuration = jump.duration
        animateAnswerJump(duration: travelDuration)

        DispatchQueue.main.asyncAfter(deadline: .now() + travelDuration) {
            guard animationToken == token else { return }
            landedLane = lane
            var landingTransaction = Transaction()
            landingTransaction.disablesAnimations = true
            withTransaction(landingTransaction) {
                dogX = jump.standingX
                dogY = jump.standingY
                jumpProgress = 0
                jumpDestinationX = 0
                jumpDestinationY = 0
                jumpLateralArc = 0
                jumpHeight = 0
                dogScale = 1
                landedRound = round
            }
            var effectTransaction = Transaction()
            effectTransaction.disablesAnimations = true
            withTransaction(effectTransaction) {
                landingImpact = true
                landingBurstProgress = 0
                rewardSource = CGPoint(x: layout.size.width / 2
                                        + layout.laneOffset(lane: lane, at: -1),
                                       y: layout.y(at: -1))
                rewardFlightProgress = 0
                rewardVisible = earnsNewHighestStep
            }
            DispatchQueue.main.async {
                guard animationToken == token else { return }
                withAnimation(.easeOut(duration: reduceMotion ? 0.10 : 0.62)) {
                    landingBurstProgress = 1
                }
                if earnsNewHighestStep {
                    withAnimation(.timingCurve(0.22, 0.72, 0.22, 1,
                                               duration: reduceMotion ? 0.16 : 0.78)) {
                        rewardFlightProgress = 1
                    }
                }
            }
            // Only contact turns this completed row into background context.
            // The next row inherits this muted state for one frame and then
            // reveals in `resetForNextQuestion`, making both fades one motion.
            withAnimation(.easeOut(duration: reduceMotion ? 0.05 : 0.18)) {
                currentRowNumbersMuted = true
            }
            if !earnsNewHighestStep {
                onRewardArrived()
            }
            let scoreArrivalDelay = earnsNewHighestStep
                ? (reduceMotion ? 0.16 : 0.78)
                : (reduceMotion ? 0.01 : 0.04)
            DispatchQueue.main.asyncAfter(deadline: .now() + scoreArrivalDelay) {
                guard animationToken == token else { return }
                if earnsNewHighestStep {
                    onRewardArrived()
                    withAnimation(.easeOut(duration: 0.10)) {
                        rewardVisible = false
                    }
                }
                onCorrectLanding()
            }
            let settleDuration = earnsNewHighestStep
                ? scoreArrivalDelay + 0.02
                : (reduceMotion ? 0.02 : 0.16)
            DispatchQueue.main.asyncAfter(deadline: .now() + settleDuration) {
                guard animationToken == token else { return }
                withAnimation(.easeOut(duration: reduceMotion ? 0.04 : 0.12)) {
                    landingImpact = false
                }
                answerJumpInProgress = false
            }
        }
    }

    /// Sets up the part of an answer jump that is shared by successful and
    /// failed answers. A wrong answer must be indistinguishable from a correct
    /// one until the character actually touches the selected glass plate.
    private func prepareAnswerJump(toLane lane: Int,
                                   fallsThrough: Bool,
                                   layout: StepCourseLayout) -> (standingX: CGFloat,
                                                                  standingY: CGFloat,
                                                                  duration: Double) {
        let forwardX = layout.laneOffset(lane: lane, at: 0)
        let standingX = layout.laneOffset(lane: lane, at: -1)
        let standingY = layout.y(at: -1) - layout.baseY
        cameraLaneOffset = 0
        hatchOpen = false
        currentRowNumbersMuted = false
        jumpProgress = 0
        // The character and the chosen stone now arrive at the standing plane
        // together. Driving both values in one transaction prevents the small
        // stop that used to occur between the end of the jump and the start of
        // the camera catch-up.
        jumpDestinationX = standingX - dogX
        jumpDestinationY = standingY - dogY
        jumpLateralArc = (forwardX - dogX) * 0.08
        jumpHeight = layout.jumpHeight
        jumpFallsThrough = fallsThrough
        jumpFallDestinationY = 0
        jumpFallRotation = 0

        return (standingX, standingY, reduceMotion ? 0.18 : 0.76)
    }

    /// Both outcomes use this exact animation through contact. Failure only
    /// diverges after progress one, when the selected plate breaks.
    private func animateAnswerJump(duration: Double) {
        withAnimation(.timingCurve(0.28, 0.04, 0.18, 1,
                                   duration: duration)) {
            jumpProgress = 1
            cameraPhase = 1
            routeProgress = CGFloat(currentRouteIndex + 1)
            // The arc modifier supplies the small airborne contraction. The
            // standing scale remains one, avoiding a second scale correction
            // on the landing frame.
            dogScale = 1
        }
    }

    private func playWrongJump(optionID: UUID,
                               lane: Int,
                               token: Int,
                               layout: StepCourseLayout,
                               failedRouteIndex: Int) {
        // The engine already knows the answer is wrong, but the view withholds
        // that information until the same jump as a correct answer reaches the
        // glass.
        pendingWrongID = optionID
        crackedID = nil
        brokenID = nil
        shatterProgress = 0
        let jump = prepareAnswerJump(toLane: lane,
                                     fallsThrough: true,
                                     layout: layout)
        let outsideBoard = layout.size.height - layout.baseY
            + layout.dogSize * 1.35
        jumpFallDestinationY = outsideBoard - dogY
        // Keep the artwork upright as well as positionally fixed. The sprite's
        // visible body is not centred inside its transparent canvas, so rotating
        // that canvas made a mathematically vertical fall look pulled inward.
        jumpFallRotation = 0
        let approachDuration = jump.duration
        let fallDuration = reduceMotion ? 0.16 : 0.62
        animateAnswerJump(duration: approachDuration)

        // Contact is the failure event: glass disappears into loose pieces and
        // the character starts accelerating vertically on this same frame.
        // The approach animation ends at rest, so the fall can start at zero
        // velocity without a pause or a kink.
        DispatchQueue.main.asyncAfter(deadline: .now() + approachDuration) {
            guard animationToken == token else { return }
            landedLane = lane
            var impactTransaction = Transaction()
            impactTransaction.disablesAnimations = true
            withTransaction(impactTransaction) {
                crackedID = optionID
                brokenID = optionID
                shatterProgress = 0
                // From the break onward the character falls through the
                // bridge, behind the intact stones from earlier questions.
                characterAboveDeck = false
            }
            withAnimation(.linear(duration: fallDuration)) {
                jumpProgress = 2
            }
            // Give the newly inserted fragments one render pass at contact,
            // then let them fall with the character's downward acceleration.
            DispatchQueue.main.async {
                guard animationToken == token else { return }
                withAnimation(.easeIn(duration: fallDuration)) {
                    shatterProgress = 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.45 : 1.46)) {
            guard animationToken == token else { return }
            dogOpacity = 0
            landedRound = nil
            restartMessageVisible = true
            // The failed row has an integer world depth. The halfway point
            // immediately before it is the boundary after the last good row.
            checkpointBoundary = failedRouteIndex > 0
                ? CGFloat(failedRouteIndex) - 0.5
                : nil

            let failedIndex = max(0, (round?.number ?? (currentStep + 1)) - 1)
            // The failed jump used the same camera movement as a successful
            // one. Start the rewind from that exact visual position so the
            // bridge cannot jump when it changes renderers.
            rewindPosition = CGFloat(failedIndex + 1)
            cameraPhase = 0
            liftPlatformVisible = false
            liftPlatformAboveDeck = false
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
            let settledDogY = startPadDogY(layout: layout)
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
            dogY = settledDogY
            dogRotation = 0
            dogScale = 1
            dogOpacity = 1
            crackedID = nil
            hatchOpen = true
            // The sprite stays between the fixed rear deck and near edge for
            // the entire ascent; there is no mid-animation layer switch.
            characterAboveDeck = true
            liftPlatformVisible = true
            liftPlatformAboveDeck = false
            // Begin fully below the fixed foreground strip. This keeps even
            // the top of the ears hidden until the character reaches the
            // opening, without changing layers halfway through the ascent.
            liftPlatformY = layout.deckHeight * 1.72
            dogY = liftPlatformY + settledDogY
        }

        // The opening gets its own readable beat. The lift then rises as a
        // single object instead of appearing and moving in the same frame.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.69 : 2.28)) {
            guard animationToken == token else { return }
            withAnimation(.spring(response: reduceMotion ? 0.18 : 0.46,
                                  dampingFraction: 0.76)) {
                dogY = startPadDogY(layout: layout)
                liftPlatformY = 0
            }
        }

        // Only the platform changes layer at the top. The character has
        // remained in front of the deck throughout the complete ascent.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.83 : 2.68)) {
            guard animationToken == token else { return }
            liftPlatformAboveDeck = true
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
            answerJumpInProgress = false
        }
    }

    /// A round transition is allowed to update the question immediately, but
    /// its camera/character reset must wait for the old movement to finish.
    /// This is the boundary that makes a fast tap a buffered input instead of
    /// a second animation competing with the first one.
    private func requestNextQuestionReset(layout: StepCourseLayout) {
        guard answerJumpInProgress else {
            resetForNextQuestion(layout: layout)
            return
        }
        nextQuestionResetPending = true
    }

    private func resetForNextQuestion(layout: StepCourseLayout) {
        // The selected answer also clears when the final round ends. At that
        // boundary the finale owns the camera and character state; treating it
        // as an ordinary next question is what made the island visibly wiggle.
        guard !playsLevelCompletion, !victoryInProgress else { return }
        let pendingAnswer = queuedAnswer
        queuedAnswer = nil
        nextQuestionResetPending = false
        animationToken &+= 1
        pendingWrongID = nil
        crackedID = nil
        brokenID = nil
        shatterProgress = 0
        rewardVisible = false
        rewardFlightProgress = 0
        landingImpact = false
        landingBurstProgress = 0
        cameraPhase = 0
        routeProgress = CGFloat(currentStep)
        cameraLaneOffset = 0
        jumpProgress = 0
        jumpDestinationX = 0
        jumpDestinationY = 0
        jumpLateralArc = 0
        jumpHeight = 0
        jumpFallsThrough = false
        jumpFallDestinationY = 0
        jumpFallRotation = 0
        rewindPosition = nil
        characterAboveDeck = true
        // A failed jump returns to step zero. In that case the raised square
        // is now the character's floor and must remain part of the start pad.
        liftPlatformVisible = currentStep == 0 && entranceCompleted
        liftPlatformAboveDeck = liftPlatformVisible
        liftPlatformY = 0
        victoryChestAttached = false
        victoryGoalDepth = nil
        answerJumpInProgress = false
        if currentStep == 0 {
            landedRound = nil
            landedLane = 1
            dogX = 0
        }
        withAnimation(.easeOut(duration: reduceMotion ? 0.05 : 0.16)) {
            currentRowNumbersMuted = false
            dogY = currentStep == 0 ? startPadDogY(layout: layout) : 0
            dogScale = 1
            dogRotation = 0
            dogOpacity = 1
            restartMessageVisible = false
            hatchOpen = false
        }

        // Let SwiftUI commit the normalized landing state before beginning the
        // buffered jump. The user does not pay an extra animation delay: this
        // resumes on the next main-loop pass, after one coherent render state.
        if let pendingAnswer {
            DispatchQueue.main.async {
                guard !answerJumpInProgress,
                      isLive,
                      selectedOptionID == nil,
                      round?.id == pendingAnswer.roundID,
                      let option = round?.options.first(where: {
                          $0.id == pendingAnswer.optionID
                      })
                else { return }
                choose(option,
                       lane: pendingAnswer.lane,
                       layout: layout)
            }
        }
    }

    private func restoreLandingIfNeeded(layout: StepCourseLayout) {
        routeProgress = CGFloat(currentStep)
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
        hatchOpen = true
        characterAboveDeck = true
        liftPlatformVisible = true
        liftPlatformAboveDeck = false
        // The complete sprite starts below the near edge; it only becomes
        // visible as it physically rises past that foreground boundary.
        liftPlatformY = layout.deckHeight * 1.72
        dogY = liftPlatformY + startPadDogY(layout: layout)
        dogScale = 1
        dogOpacity = 1

        // Let the sliding hatch finish opening before the platform rises.
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.04 : 0.18)) {
            guard animationToken == token else { return }
            withAnimation(.spring(response: reduceMotion ? 0.18 : 0.58,
                                  dampingFraction: 0.76)) {
                dogY = startPadDogY(layout: layout)
                liftPlatformY = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.25 : 0.82)) {
            guard animationToken == token else { return }
            liftPlatformAboveDeck = true
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
        rewardFlightProgress = 0
        landingImpact = false
        landingBurstProgress = 0
        // Freeze the exact renderer-owned position used in the preceding
        // frame. Deriving this from the newly published round would let the
        // island shift just before the final jump starts.
        let lockedGoalDepth = max(0, CGFloat(routeRoundCount) - routeProgress)
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
            // Perspective is already expressed by the world geometry. Keep
            // the character at its established play size all the way onto the
            // finish instead of shrinking it a second time during this jump.
            dogScale = 1
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
                dogScale = 1
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

/// Normalised ground contact for each silhouette. Gameplay artwork lives on
/// square canvases with very different amounts of transparent space, so using
/// the canvas width directly would give a penguin and an octopus the same
/// shadow. These ratios keep the contact patch tied to the rendered character
/// size while respecting the broad/compact shape of each animal.
private struct StepCharacterFootprint {
    let width: CGFloat
    let depth: CGFloat
    let verticalOffset: CGFloat

    init(character: AnimalCharacter, renderedSide: CGFloat) {
        let widthRatio: CGFloat
        let depthRatio: CGFloat

        switch character.id {
        case "octopus":
            widthRatio = 0.64
            depthRatio = 0.24
        case "crab":
            widthRatio = 0.68
            depthRatio = 0.22
        case "frog":
            widthRatio = 0.58
            depthRatio = 0.22
        case "elephant", "lion":
            widthRatio = 0.54
            depthRatio = 0.23
        case "bear":
            widthRatio = 0.49
            depthRatio = 0.22
        case "fox":
            widthRatio = 0.46
            depthRatio = 0.21
        case "bunny":
            widthRatio = 0.44
            depthRatio = 0.20
        case "penguin":
            widthRatio = 0.42
            depthRatio = 0.20
        default: // Dog and any future character start from a neutral footprint.
            widthRatio = 0.44
            depthRatio = 0.22
        }

        width = renderedSide * widthRatio
        depth = max(7, width * depthRatio)
        // A tiny forward bias puts the ellipse beneath the feet rather than
        // centred inside them on the strongly foreshortened glass plane.
        verticalOffset = depth * 0.08
    }
}

private struct StepCharacterGroundShadow: View {
    let character: AnimalCharacter

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.16))
                .blur(radius: 4)
            Ellipse()
                .fill(character.deepColor.opacity(0.20))
                .scaleEffect(x: 0.78, y: 0.62)
                .blur(radius: 1.2)
        }
        .compositingGroup()
    }
}

/// Projects the jump onto the supporting surface. Horizontal movement follows
/// the character, but the vertical jump arc becomes distance from the ground:
/// the shadow contracts, softens and fades at the apex, then regains contact
/// at the destination. After a wrong tile breaks it quickly disappears into
/// the opening instead of falling through the air with the character.
private struct StepGroundShadowMotionModifier: AnimatableModifier {
    var progress: CGFloat
    let destinationX: CGFloat
    let destinationY: CGFloat
    let lateralArc: CGFloat
    let fallsThrough: Bool
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let p = max(0, progress)
        let contactProgress = min(1, p)
        let airborne = reduceMotion ? 0 : sin(.pi * contactProgress)
        let surfaceX = destinationX * contactProgress + lateralArc * airborne
        let surfaceY = destinationY * contactProgress
        let fallProgress = max(0, min(1, p - 1))
        let fallVisibility = fallsThrough
            ? max(0, 1 - fallProgress * 3.5)
            : 1
        let elevationVisibility = 1 - airborne * 0.48

        content
            .offset(x: surfaceX, y: surfaceY)
            .scaleEffect(x: 1 - airborne * 0.34,
                         y: 1 - airborne * 0.50)
            .blur(radius: airborne * 3.5)
            .opacity(Double(elevationVisibility * fallVisibility))
    }
}

/// One continuous, animatable flight path. Both outcomes use the established
/// sine arc through contact. A wrong answer then accelerates straight down,
/// without inheriting any horizontal motion from the jump.
private struct StepJumpArcModifier: AnimatableModifier {
    var progress: CGFloat
    let destinationX: CGFloat
    let destinationY: CGFloat
    let lateralArc: CGFloat
    let height: CGFloat
    let fallsThrough: Bool
    let fallDestinationY: CGFloat
    let fallRotation: Double
    let preservesScale: Bool
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let p = max(0, progress)
        let contactProgress = min(1, p)
        let arc = reduceMotion ? 0 : sin(.pi * contactProgress)
        let regularX = destinationX * contactProgress + lateralArc * arc
        let regularY = destinationY * contactProgress - height * arc
        let fallAmount = max(0, min(1, p - 1))
        let fallDistance = max(0, fallDestinationY - destinationY)
        let fallY = destinationY + fallDistance * fallAmount * fallAmount
        let x = fallsThrough
            ? (p <= 1 ? regularX : destinationX)
            : regularX
        let y = fallsThrough
            ? (p <= 1 ? regularY : fallY)
            : regularY
        let flightScale = preservesScale
            ? 1
            : 1 - arc * (reduceMotion ? 0 : 0.08)
        let tilt = Double(arc * min(1, abs(lateralArc) / 90))
            * (lateralArc < 0 ? -3 : 3)

        content
            .offset(x: x, y: y)
            .scaleEffect(flightScale, anchor: .bottom)
            .rotationEffect(.degrees(tilt + fallRotation * Double(fallAmount)))
    }
}

private struct StepCorrectBurst: View, Animatable {
    let character: AnimalCharacter
    let isPad: Bool
    var progress: CGFloat
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { proxy in
            let p = min(1, max(0, progress))
            let travel = reduceMotion ? CGFloat(0.18) : p
            // Hold brightness through the first half of the burst, then fade
            // quickly. The earlier linear fade made the dust disappear before
            // its particles had separated enough to read as stars.
            let fade = p < 0.48 ? CGFloat(1) : max(0, (1 - p) / 0.52)
            let centre = CGPoint(x: proxy.size.width / 2,
                                 y: proxy.size.height / 2)

            ZStack {
                ForEach(0..<20, id: \.self) { index in
                    let angle = Double(index) * (.pi * 2 / 20)
                        + Double(index % 3) * 0.16
                    let distance = min(proxy.size.width, proxy.size.height)
                        * (0.38 + CGFloat(index % 4) * 0.085)
                    let x = cos(angle) * distance * travel
                    let y = sin(angle) * distance * travel * 0.72
                    let size = (isPad ? CGFloat(16) : CGFloat(10))
                        * (0.72 + CGFloat(index % 3) * 0.18)

                    Group {
                        if index.isMultiple(of: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: size, weight: .black))
                                .foregroundStyle(index.isMultiple(of: 2)
                                    ? Color.white
                                    : Color(red: 1.0, green: 0.76, blue: 0.08))
                        } else {
                            Circle()
                                .fill(index.isMultiple(of: 2)
                                    ? Color.white
                                    : Color.yellow)
                                .frame(width: size * 0.52, height: size * 0.52)
                        }
                    }
                    .position(x: centre.x + x, y: centre.y + y)
                    .scaleEffect(0.35 + sin(.pi * p) * 0.9)
                    .rotationEffect(.degrees(Double(index * 31) + Double(p) * 95))
                    .opacity(Double(fade))
                    .shadow(color: character.deepColor.opacity(0.82), radius: 4)
                }

                Image(systemName: "sparkles")
                    .font(.system(size: isPad ? 42 : 29, weight: .black))
                    .foregroundStyle(Color.white, Color.yellow)
                    .scaleEffect(0.55 + p * 0.8)
                    .opacity(Double(max(0, 1 - p * 1.4)))
                    .shadow(color: character.deepColor.opacity(0.82), radius: isPad ? 12 : 8)
            }
        }
    }
}

/// The single nut awarded by a genuinely new high step. A quadratic path
/// gives it a small celebratory lift before it accelerates into the HUD; no
/// badge or extra label competes with the tile burst.
private struct StepFlyingScoreNut: View, Animatable {
    let character: AnimalCharacter
    let isPad: Bool
    var progress: CGFloat
    let source: CGPoint
    let target: CGPoint
    let reduceMotion: Bool

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        GeometryReader { _ in
            let p = min(1, max(0, progress))
            let control = CGPoint(
                x: source.x + (target.x - source.x) * 0.28,
                y: min(source.y, target.y) - (reduceMotion ? 8 : (isPad ? 92 : 58))
            )
            let inverse = 1 - p
            let point = CGPoint(
                x: inverse * inverse * source.x
                    + 2 * inverse * p * control.x
                    + p * p * target.x,
                y: inverse * inverse * source.y
                    + 2 * inverse * p * control.y
                    + p * p * target.y
            )
            let size: CGFloat = isPad ? 34 : 24

            CurrencyIcon(size: size)
                .foregroundStyle(
                    LinearGradient(colors: [.white, Color.yellow, character.skyColor],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .rotationEffect(.degrees(Double(p) * 210))
                .scaleEffect(1 + sin(.pi * p) * 0.24)
                .position(point)
                .shadow(color: character.deepColor.opacity(0.52), radius: 4, y: 3)
                .opacity(Double(p < 0.98 ? 1 : max(0, (1 - p) / 0.02)))
        }
    }
}

private struct StepCheckpointFlag: View {
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        GeometryReader { proxy in
            let poleWidth: CGFloat = isPad ? 6 : 4
            ZStack(alignment: .topLeading) {
                Capsule()
                    .fill(LinearGradient(colors: [.white, character.skyColor],
                                         startPoint: .leading,
                                         endPoint: .trailing))
                    .frame(width: poleWidth, height: proxy.size.height)
                    .shadow(color: .black.opacity(0.24), radius: 2, y: 2)

                CheckpointPennantShape()
                    .fill(LinearGradient(colors: [Color.yellow, Color.orange],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .overlay {
                        CheckpointPennantShape()
                            .stroke(.white.opacity(0.92), lineWidth: isPad ? 2.5 : 1.5)
                    }
                    .frame(width: proxy.size.width * 0.88,
                           height: proxy.size.height * 0.48)
                    .offset(x: poleWidth * 0.55)
                    .shadow(color: character.deepColor.opacity(0.28), radius: 3, y: 2)
            }
        }
    }
}

private struct CheckpointPennantShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.14))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.86))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Perspective layout

/// SwiftUI can only interpolate `Shape.animatableData`. Keeping all fixed
/// perspective samples in one vector lets the glass outline and its label use
/// the exact same per-frame geometry instead of each receiving a separate
/// implicit layout animation.
private struct StepPerspectiveVector: VectorArithmetic {
    var values: [CGFloat]

    static var zero: StepPerspectiveVector { StepPerspectiveVector(values: []) }

    static func + (lhs: StepPerspectiveVector,
                   rhs: StepPerspectiveVector) -> StepPerspectiveVector {
        combine(lhs, rhs, operation: +)
    }

    static func - (lhs: StepPerspectiveVector,
                   rhs: StepPerspectiveVector) -> StepPerspectiveVector {
        combine(lhs, rhs, operation: -)
    }

    mutating func scale(by rhs: Double) {
        let scale = CGFloat(rhs)
        for index in values.indices { values[index] *= scale }
    }

    var magnitudeSquared: Double {
        values.reduce(0) { result, value in
            result + Double(value * value)
        }
    }

    private static func combine(
        _ lhs: StepPerspectiveVector,
        _ rhs: StepPerspectiveVector,
        operation: (CGFloat, CGFloat) -> CGFloat
    ) -> StepPerspectiveVector {
        let count = max(lhs.values.count, rhs.values.count)
        let values = (0..<count).map { index in
            let left = lhs.values.indices.contains(index) ? lhs.values[index] : 0
            let right = rhs.values.indices.contains(index) ? rhs.values[index] : 0
            return operation(left, right)
        }
        return StepPerspectiveVector(values: values)
    }
}

private struct StepTilePerspective {
    /// Scale of the support grid at the lower edge of the tile. The row frame
    /// uses this width so its lower corners sit exactly on the four beams.
    let bottomScale: CGFloat
    /// Scale along the full tile height, expressed relative to its lower edge.
    /// Using the full sample set avoids the visible overshoot that a single
    /// quadratic approximation produced on the large nearest row.
    let scaleRatios: [CGFloat]

    /// Exact centroid of the same sampled polygon drawn by
    /// `BridgeLaneTileShape`. Both the outline and the label therefore use one
    /// geometry source, including on every interpolated animation frame.
    func contentCenter(lane: Int, size: CGSize) -> CGPoint {
        let safeLane = min(max(lane, 0), 2)
        let leftBoundary = CGFloat(safeLane) - 1.5
        let rightBoundary = leftBoundary + 1
        let ratios = scaleRatios.count > 1 ? scaleRatios : [1, 1]
        let denominator = CGFloat(max(1, ratios.count - 1))

        func point(boundary: CGFloat, sample: Int) -> CGPoint {
            CGPoint(
                x: (boundary * ratios[sample] - leftBoundary) * size.width,
                y: CGFloat(sample) / denominator * size.height
            )
        }

        var polygon = [point(boundary: leftBoundary, sample: 0)]
        polygon.append(contentsOf: ratios.indices.map {
            point(boundary: rightBoundary, sample: $0)
        })
        polygon.append(contentsOf: ratios.indices.reversed().map {
            point(boundary: leftBoundary, sample: $0)
        })

        var twiceArea: CGFloat = 0
        var weightedX: CGFloat = 0
        var weightedY: CGFloat = 0
        for index in polygon.indices {
            let current = polygon[index]
            let next = polygon[(index + 1) % polygon.count]
            let cross = current.x * next.y - next.x * current.y
            twiceArea += cross
            weightedX += (current.x + next.x) * cross
            weightedY += (current.y + next.y) * cross
        }

        guard abs(twiceArea) > 0.001 else {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        return CGPoint(x: weightedX / (3 * twiceArea),
                       y: weightedY / (3 * twiceArea))
    }
}

private struct StepCourseLayout {
    let size: CGSize
    let isPad: Bool
    let bottomReserve: CGFloat
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
    /// This floor is only reached after the route is already above the screen.
    /// Keeping it below the visible scale prevents the old mid-curve kink.
    private var minimumCourseScale: CGFloat { 0.12 }
    /// Ten rows put the last rendered glass completely above the viewport;
    /// the supports themselves terminate beneath the destination island.
    var offscreenRowDepth: Int { 10 }
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
    /// A square floor plate seen in perspective: its projected depth is
    /// shorter than its width, while the corners stay straight rather than
    /// reading as the old oval iris.
    var liftSize: CGFloat { deckHeight * 0.82 }
    var liftHeight: CGFloat { deckHeight * 0.54 }
    func liftCenterY(cameraPhase: CGFloat) -> CGFloat {
        y(at: -1 - cameraPhase) + deckHeight * 0.18
    }
    var jumpHeight: CGFloat { min(isPad ? 210 : 145, (baseY - answerY) * 0.72) }
    private func naturalScale(at depth: CGFloat) -> CGFloat {
        if depth <= -1 { return 1 }
        if depth < 0 { return 0.92 - depth * 0.08 }
        return 0.92 * pow(widthDecay, depth)
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
        // The finish is the last part of the same construction, so its outer
        // edge is exactly as wide as the three answer stones combined at this
        // depth. This also lets all four support beams dock inside the island.
        rowWidth(at: depth)
    }

    func goalHeight(for width: CGFloat) -> CGFloat {
        min(width * (isPad ? 0.39 : 0.43), isPad ? 350 : 190)
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
        // Twelve segments are visually indistinguishable at the rendered tile
        // sizes, while halving the path work for every lane on every camera
        // frame compared with the former 24-segment curve.
        let sampleCount = 12
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

private struct StepCourseRails: View, Animatable {
    let layout: StepCourseLayout
    let character: AnimalCharacter
    var farDepth: CGFloat

    /// Canvas does not interpolate captured values by itself. Making the
    /// endpoint explicitly animatable keeps these paths on the exact same
    /// perspective depth as the SwiftUI-positioned finish island throughout
    /// every answer jump.
    var animatableData: CGFloat {
        get { farDepth }
        set { farDepth = newValue }
    }

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

                // The supports move through a shallow, monotonic curve. The
                // outside pair stops sampling just before the destination and
                // uses its own final segment to bend underneath the oval.
                let sampleCount = 72
                let isOuter = boundary == 0 || boundary == 3
                let curveStartDepth = isOuter
                    ? max(nearDepth, farDepth - 0.18)
                    : farDepth
                for sample in 0...sampleCount {
                    let progress = CGFloat(sample) / CGFloat(sampleCount)
                    let depth = nearDepth
                        + (curveStartDepth - nearDepth) * progress
                    support.addLine(to: CGPoint(
                        x: center + layout.supportOffset(boundary: boundary,
                                                         at: depth),
                        y: layout.y(at: depth)
                    ))
                }

                if isOuter {
                    let side: CGFloat = boundary == 0 ? -1 : 1
                    let islandWidth = layout.goalWidth(at: farDepth)
                    let islandHeight = layout.goalHeight(for: islandWidth)
                    let rim = CGPoint(
                        x: center + layout.supportOffset(boundary: boundary,
                                                         at: farDepth),
                        y: farY
                    )
                    let concealedEnd = CGPoint(
                        x: center + side * islandWidth * 0.46,
                        y: farY - islandHeight * 0.07
                    )
                    support.addQuadCurve(to: concealedEnd, control: rim)
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
    /// Only the active answer row is fully legible. Future, completed and
    /// rewind rows keep their labels dimmed until they become the active row.
    let mutesNumbers: Bool
    let usesDetailedEffects: Bool

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
                                          isNumberMuted: mutesNumbers,
                                          usesDetailedEffects: usesDetailedEffects)
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
            // This is a square opening in the deck's world plane. Perspective
            // compresses its depth, so its on-screen width is intentionally
            // larger than its height.
            let hatchHeight = proxy.size.height * 0.54
            let hatchWidth = hatchHeight * 1.52
            let hatchOffset = proxy.size.height * 0.04
            let deckGradient = LinearGradient(colors: [Color.white.opacity(0.95),
                                                        Color(red: 0.35, green: 0.83, blue: 1.0),
                                                        character.color.opacity(0.62)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
            ZStack {
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
                        path.move(to: CGPoint(x: proxy.size.width * 0.16,
                                              y: proxy.size.height * 0.22))
                        path.addLine(to: CGPoint(x: proxy.size.width * 0.48,
                                                y: proxy.size.height * 0.09))
                    }
                    .stroke(.white.opacity(0.74),
                            style: StrokeStyle(lineWidth: isPad ? 4 : 2.5,
                                               lineCap: .round))
                }
                // The open hatch is a real alpha cut-out for the lift. The
                // character is rendered between the deck's fixed rear and
                // front sections, so it emerges without a layer jump.
                .mask {
                    StepDeckOpeningMask(isOpen: hatchOpen,
                                        width: hatchWidth,
                                        height: hatchHeight,
                                        offsetY: hatchOffset)
                }

                // One flush hatch slides sideways underneath the surrounding
                // deck. Keeping it as the exact same shape as the opening
                // prevents white flashes, split panels and stray side faces.
                ZStack {
                    GlassPerspectiveShape(inset: 0.11)
                        .fill(LinearGradient(colors: [Color(red: 0.46, green: 0.87, blue: 1.0),
                                                      Color(red: 0.27, green: 0.76, blue: 0.95),
                                                      character.color.opacity(0.52)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .offset(x: hatchOpen ? hatchWidth * 1.08 : 0)
                }
                .frame(width: hatchWidth, height: hatchHeight)
                .clipShape(GlassPerspectiveShape(inset: 0.11))
                .overlay {
                    GlassPerspectiveShape(inset: 0.11)
                        .stroke(Color(red: 0.04, green: 0.22, blue: 0.39)
                                    .opacity(hatchOpen ? 0.70 : 0.34),
                                lineWidth: isPad ? 3 : 2)
                }
                .offset(y: hatchOffset)
                .animation(.timingCurve(0.30, 0.02, 0.20, 1,
                                        duration: 0.30),
                           value: hatchOpen)
            }
        }
    }
}

/// The permanently foregrounded near edge of the starting pad. Its upper
/// boundary is exactly the lower edge of the hatch (0.54 centre + 0.27 half
/// height = 0.81 of the deck), so it can hide the shaft without ever drawing
/// a horizontal plate across the character's body.
private struct StepStartDeckForeground: View {
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        GeometryReader { proxy in
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
                            .stroke(character.skyColor,
                                    lineWidth: isPad ? 7 : 5)
                    }
            }
            .mask(alignment: .bottom) {
                Rectangle()
                    .frame(height: proxy.size.height * 0.19)
            }
        }
    }
}

private struct StepDeckOpeningMask: View {
    let isOpen: Bool
    let width: CGFloat
    let height: CGFloat
    let offsetY: CGFloat

    var body: some View {
        ZStack {
            Rectangle().fill(.white)
            if isOpen {
                GlassPerspectiveShape(inset: 0.11)
                    .fill(.black)
                    .frame(width: width, height: height)
                    .offset(y: offsetY)
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
    }
}

private struct StepLiftPlatform: View {
    let character: AnimalCharacter
    let isPad: Bool

    var body: some View {
        GlassPerspectiveShape(inset: 0.11)
            .fill(LinearGradient(colors: [Color(red: 0.52, green: 0.89, blue: 1.0),
                                          Color(red: 0.30, green: 0.80, blue: 0.98),
                                          character.color.opacity(0.56)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay {
                GlassPerspectiveShape(inset: 0.11)
                    .stroke(Color(red: 0.04, green: 0.22, blue: 0.39).opacity(0.55),
                            lineWidth: isPad ? 2.5 : 1.5)
            }
    }
}

private struct StepGoalIsland: View {
    let character: AnimalCharacter
    let isPad: Bool
    let hidesChest: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let edge = isPad ? CGFloat(6) : CGFloat(4)

            ZStack {
                // One continuous oval, with a slightly lowered second oval
                // supplying depth. There is deliberately no grass cap or
                // rectangular dock: the bridge material owns the whole island.
                Ellipse()
                    .fill(LinearGradient(colors: [character.deepColor,
                                                  Color(red: 0.05, green: 0.28, blue: 0.50)],
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .frame(width: width * 0.95, height: height * 0.67)
                    .position(x: width * 0.5, y: height * 0.57)
                    .shadow(color: .black.opacity(0.32),
                            radius: isPad ? 14 : 9,
                            y: isPad ? 11 : 7)

                // The glossy finish below deliberately uses translucent
                // colours. Put a fully opaque themed core behind it so the
                // concealed rail ends can never show through the island.
                Ellipse()
                    .fill(character.skyColor)
                    .frame(width: width, height: height * 0.66)
                    .position(x: width * 0.5, y: height * 0.43)

                Ellipse()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.96),
                                                  character.skyColor.opacity(0.92),
                                                  character.color.opacity(0.82),
                                                  character.deepColor.opacity(0.90)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: width, height: height * 0.66)
                    .overlay {
                        Ellipse()
                            .stroke(character.deepColor.opacity(0.72),
                                    lineWidth: edge)
                            .overlay {
                                Ellipse()
                                    .stroke(.white.opacity(0.72),
                                            lineWidth: max(1.5, edge * 0.42))
                                    .padding(.horizontal, width * 0.025)
                                    .padding(.vertical, height * 0.025)
                            }
                    }
                    .position(x: width * 0.5, y: height * 0.43)

                if !hidesChest {
                    StepGoalChest()
                        .frame(width: width * 0.23, height: height * 0.33)
                        .position(x: width * 0.5, y: height * 0.35)
                        .transition(.scale(scale: 0.35).combined(with: .opacity))
                }

                // The pennants face away from the centre, share one flagpole
                // baseline and are visibly planted in the rear island rim.
                ForEach([-1.0, 1.0], id: \.self) { side in
                    let poleX = width * (0.5 + CGFloat(side) * 0.31)
                    Capsule()
                        .fill(LinearGradient(colors: [.white,
                                                      character.skyColor.opacity(0.82)],
                                             startPoint: .leading,
                                             endPoint: .trailing))
                        .frame(width: isPad ? 7 : 4.5,
                               height: height * 0.39)
                        .position(x: poleX, y: height * 0.16)
                        .shadow(color: .black.opacity(0.20), radius: 2, y: 2)

                    FinishPennantShape(pointsRight: side > 0)
                        .fill(LinearGradient(colors: side < 0
                                                ? [character.skyColor, character.deepColor]
                                                : [Color.yellow, Color.orange],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .overlay {
                            FinishPennantShape(pointsRight: side > 0)
                                .stroke(.white.opacity(0.78),
                                        lineWidth: isPad ? 2.5 : 1.5)
                        }
                        .frame(width: width * 0.15, height: height * 0.15)
                        .position(x: poleX + CGFloat(side) * width * 0.075,
                                  y: -height * 0.005)
                        .shadow(color: .black.opacity(0.16), radius: 2, y: 2)

                    Circle()
                        .fill(.white)
                        .overlay {
                            Circle().stroke(character.skyColor.opacity(0.72),
                                            lineWidth: isPad ? 2 : 1)
                        }
                        .frame(width: isPad ? 14 : 9,
                               height: isPad ? 14 : 9)
                        .position(x: poleX, y: height * 0.34)
                }
            }
        }
    }
}

private struct StepGoalChest: View {
    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                RoundedRectangle(cornerRadius: height * 0.15,
                                 style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 0.97, green: 0.48, blue: 0.07),
                                                  Color(red: 0.58, green: 0.20, blue: 0.03)],
                                         startPoint: .top,
                                         endPoint: .bottom))
                    .frame(height: height * 0.68)
                    .position(x: width * 0.5, y: height * 0.64)

                RoundedRectangle(cornerRadius: height * 0.22,
                                 style: .continuous)
                    .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.79, blue: 0.19),
                                                  Color(red: 0.86, green: 0.35, blue: 0.03)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(height: height * 0.50)
                    .position(x: width * 0.5, y: height * 0.30)

                Rectangle()
                    .fill(Color(red: 1.0, green: 0.80, blue: 0.22))
                    .frame(width: width * 0.16, height: height * 0.84)
                    .position(x: width * 0.5, y: height * 0.52)

                Image(systemName: "star.fill")
                    .font(.system(size: height * 0.36, weight: .black))
                    .foregroundStyle(Color.white, Color.yellow)
                    .shadow(color: Color.orange.opacity(0.72), radius: 2, y: 1)
                    .position(x: width * 0.5, y: height * 0.59)
            }
            .overlay {
                RoundedRectangle(cornerRadius: height * 0.18,
                                 style: .continuous)
                    .stroke(Color.white.opacity(0.40),
                            lineWidth: max(1, height * 0.035))
            }
            .shadow(color: .black.opacity(0.30), radius: 4, y: 3)
        }
    }
}

private struct FinishPennantShape: Shape {
    let pointsRight: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if pointsRight {
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.14))
            path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.86))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.14))
            path.addLine(to: CGPoint(x: rect.width * 0.28, y: rect.midY))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.86))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
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

private struct GlassStepTile: View, Animatable {
    let text: String
    let lane: Int
    var perspective: StepTilePerspective
    let character: AnimalCharacter
    let isCracked: Bool
    let isBroken: Bool
    let shatterProgress: CGFloat
    let shatterDistance: CGFloat
    let isHighlighted: Bool
    let isNumberMuted: Bool
    var usesDetailedEffects = true

    var animatableData: StepPerspectiveVector {
        get { StepPerspectiveVector(values: perspective.scaleRatios) }
        set {
            perspective = StepTilePerspective(
                bottomScale: perspective.bottomScale,
                scaleRatios: newValue.values
            )
        }
    }

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
                            if usesDetailedEffects {
                                BridgeLaneTileShape(lane: lane, perspective: perspective)
                                    .stroke(.white.opacity(0.40), lineWidth: 1)
                                    .padding(5)
                            }
                        }
                        .background {
                            // The blue lower edge is part of the stone itself,
                            // not a close-range embellishment. Keep it on the
                            // lightweight future rows too, so every visible
                            // stone already has the same physical thickness.
                            BridgeLaneTileShape(lane: lane, perspective: perspective)
                                .fill(Color(red: 0.10, green: 0.45, blue: 0.68))
                                .offset(y: proxy.size.height * 0.14)
                        }
                        .shadow(color: usesDetailedEffects
                                    ? Color(red: 0.03, green: 0.20, blue: 0.44).opacity(0.32)
                                    : .clear,
                                radius: usesDetailedEffects ? 7 : 0,
                                y: usesDetailedEffects ? 7 : 0)

                    Path { path in
                        path.move(to: CGPoint(x: proxy.size.width * 0.18,
                                              y: proxy.size.height * 0.22))
                        path.addLine(to: CGPoint(x: proxy.size.width * 0.50,
                                                y: proxy.size.height * 0.10))
                    }
                    .stroke(.white.opacity(0.70),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))

                    if !text.isEmpty {
                        Canvas { context, size in
                            let center = perspective.contentCenter(
                                lane: lane,
                                size: size
                            )
                            context.addFilter(.shadow(
                                color: .white.opacity(0.88),
                                radius: 1
                            ))
                            let label = Text(verbatim: text)
                                .font(.system(
                                    size: min(size.width * 0.30, 42),
                                    weight: .black,
                                    design: .rounded
                                ))
                                .foregroundColor(
                                    Color(red: 0.03, green: 0.18, blue: 0.43)
                                        .opacity(isNumberMuted ? 0.34 : 1)
                                )
                            context.draw(
                                context.resolve(label),
                                at: center,
                                anchor: .center
                            )
                        }
                        .allowsHitTesting(false)
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
    let animationID: Int
    let reduceMotion: Bool

    @State private var frame = 1
    @State private var playbackGeneration = 0

    var body: some View {
        sprite
            .onChange(of: animationID) { _, _ in
                playJumpFrames()
            }
    }

    @ViewBuilder
    private var sprite: some View {
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

    private func playJumpFrames() {
        playbackGeneration &+= 1
        let generation = playbackGeneration
        let timeline: [(frame: Int, time: Double)] = reduceMotion
            ? [(2, 0), (4, 0.04), (6, 0.08), (8, 0.12), (1, 0.17)]
            : [(2, 0), (3, 0.08), (4, 0.17), (5, 0.28),
               (6, 0.40), (7, 0.51), (8, 0.60), (1, 0.70)]
        for cue in timeline {
            DispatchQueue.main.asyncAfter(deadline: .now() + cue.time) {
                guard playbackGeneration == generation else { return }
                frame = cue.frame
            }
        }
    }
}

#if canImport(UIKit)
nonisolated private enum StepDogSpriteCache {
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
