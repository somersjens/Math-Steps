//
//  GameView.swift
//  Math Memory
//
//  The playing surface. A round runs on the claw machine: the sum sits on the
//  cabinet, walnuts carry the answers, and the player steers the hanging
//  character to grab the right nut.
//
//  All rules live in `MemoryGame`; this file puts the HUD and the playfield
//  together and hands every grabbed nut straight to the engine.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The window's own safe area. Sample in `onAppear`, never from `body` —
/// a nested GeometryReader reports zero once its container is already inset.
struct ScreenSafeArea: Equatable {
    var top: CGFloat = 0
    var bottom: CGFloat = 0
    var leading: CGFloat = 0
    var trailing: CGFloat = 0

    @MainActor
    static var current: ScreenSafeArea {
#if canImport(UIKit)
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
        guard let insets = window?.safeAreaInsets else { return ScreenSafeArea() }
        return ScreenSafeArea(top: insets.top,
                              bottom: insets.bottom,
                              leading: insets.left,
                              trailing: insets.right)
#else
        return ScreenSafeArea()
#endif
    }
}

/// Everything a session needs to start: which level to draw questions from and
/// how many answer cards each round lays out.
struct GameSessionRequest: Identifiable {
    let level: MathLevel
    /// Only meaningful for Supermix levels; every other topic has one operation.
    var mixedVariant: MixedVariant = .all
    /// Which of the three order buttons was chosen. Supermix ignores it.
    var mode: PracticeMode = .mixed
    /// True when the level was opened to be taught: the start card offers the
    /// walkthrough straight away. Deliberately outside `id`, which identifies
    /// the *board* being played.
    var startsTutorialArmed = false
    var id: String { "\(level.id).\(mixedVariant.rawValue).\(mode.rawValue)" }

    /// The scoreboard this session plays on.
    var board: LevelBoard {
        LevelBoard(level: level, mixedVariant: mixedVariant, mode: mode)
    }

    /// Choice one, two and three on the final welcome screen start the player
    /// at a suitable point in their chosen topic.
    static func onboardingStartLevel(topic: MathTopic, mode: PracticeMode) -> MathLevel? {
        let index: Int
        switch mode {
        case .order:  index = 2
        case .random: index = 5
        case .mixed:  index = 10
        }
        return LevelCatalog.levels(for: topic).first { $0.index == index }
    }

    /// The first session the welcome flow opens: the walkthrough, on the
    /// exercise the player just chose.
    static func tutorialHandoff(topic: MathTopic,
                                mode: PracticeMode,
                                mixedVariant: MixedVariant) -> GameSessionRequest? {
        guard let level = onboardingStartLevel(topic: topic, mode: mode) else { return nil }
        return GameSessionRequest(level: level,
                                  mixedVariant: mixedVariant,
                                  mode: mode,
                                  startsTutorialArmed: true)
    }
}

struct GameView: View {
    let request: GameSessionRequest
    /// Used when this view is shown in-hierarchy (the welcome-flow handoff)
    /// rather than inside a `fullScreenCover`, which supplies `dismiss`.
    private let onExit: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject private var premium = PremiumStore.shared
    @ObservedObject private var language = LanguageManager.shared
    @StateObject private var model: GameViewModel
    /// The walkthrough. Inert until a run is actually started with it armed.
    @StateObject private var tutorial = TutorialController()

    /// The window's safe area, sampled once the view is on screen — never from
    /// inside `body`; see `ScreenSafeArea`.
    @State private var screenInsets = ScreenSafeArea()

    /// The level's start card, shown before the first round and dismissed by
    /// the player. The session only begins once it is gone.
    @State private var showsIntro = true
    /// The same card doubles as the in-level pause screen. Keeping this state
    /// separate from `showsIntro` lets a brand-new run still say Start while a
    /// pause made before the first answer already says Continue.
    @State private var showsPauseCard = false
    /// After the card, the fish gets the stage to itself for one short looping
    /// entrance. The first round only opens when that animation is finished.
    @State private var playsFishEntrance = false
    /// A completed board gets one last moment in the machine before its result
    /// card appears. Time expiry has its own short finale.
    @State private var playsLevelCompletion = false
    @State private var playsTimeOutFinale = false
    @State private var showsResult = false
    /// Whether pressing Start or Continue will run the walkthrough. Armed from
    /// onboarding or toggled from the level card before the first point.
    @State private var isTutorialArmed: Bool
    /// Explains why a walkthrough can no longer start after points were earned.
    @State private var showsTutorialNotice = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(request: GameSessionRequest, onExit: (() -> Void)? = nil) {
        self.request = request
        self.onExit = onExit
        _model = StateObject(wrappedValue: GameViewModel(request: request))
        // A level with a run waiting on it is continued, never taught: the
        // walkthrough needs a session it can shape from its very first round.
        _isTutorialArmed = State(
            initialValue: request.startsTutorialArmed
                && PausedSessionStore.shared.session(request.board) == nil
        )
    }

    private var character: AnimalCharacter { CharacterCatalog.current(isPremium: premium.isPremium) }
    private var clawPalette: ClawPalette { ClawPalette(character: character) }
    /// A narrow iPad window should use the compact gameplay metrics instead of
    /// squeezing the full-width iPad HUD and 285pt character into the scene.
    private var isPad: Bool {
        AppLayout.isPad && horizontalSizeClass != .compact
    }

    var body: some View {
        ZStack {
            character.tintColor
                .ignoresSafeArea()

            // Keep the level visible underneath every card. The result is an
            // overlay over the reef that was just played, exactly like the
            // start and pause cards, rather than a replacement for the game.
            playfield
                .transition(.opacity)

            if showsResult {
                ResultView(result: model.result,
                           board: request.board,
                           character: character,
                           onPlayAgain: {
                               showsResult = false
                               playsLevelCompletion = false
                               playsTimeOutFinale = false
                               Task { await model.restart() }
                           },
                           onExit: leave)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(1)
            }

            if showsIntro {
                LevelIntroCard(board: request.board,
                               theme: character,
                               isPauseCard: showsPauseCard,
                               isTutorialArmed: isTutorialArmed,
                               onToggleTutorial: toggleTutorial,
                               onStart: startSession,
                               onExit: leave)
                    .transition(.opacity)
                    .zIndex(2)
            }

            if showsTutorialNotice {
                TutorialNoticeCard(theme: character) {
                    withAnimation(.easeOut(duration: 0.2)) { showsTutorialNotice = false }
                }
                .transition(.opacity)
                .zIndex(3)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showsIntro)
        .onAppear {
            screenInsets = ScreenSafeArea.current
            model.prepare()
        }
#if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(
            for: UIDevice.orientationDidChangeNotification
        )) { _ in
            // Safe-area sides change when an iPad rotates. Re-sample after
            // UIKit has committed the new window geometry so the HUD remains
            // clear of rounded corners in either landscape direction.
            DispatchQueue.main.async {
                screenInsets = ScreenSafeArea.current
            }
        }
#endif
        .onChange(of: model.isGameOver) { _, isOver in
            // There is nothing left to teach on a finished board.
            if isOver { tutorial.finish() }
            guard isOver else {
                showsResult = false
                playsLevelCompletion = false
                playsTimeOutFinale = false
                return
            }
            if model.result.reason == .roundsCompleted {
                playsLevelCompletion = true
            } else if model.result.reason == .outOfTime {
                playsTimeOutFinale = true
            } else {
                withAnimation(.easeInOut(duration: 0.28)) {
                    showsResult = true
                }
            }
        }
        .onDisappear {
            tutorial.cancel()
            model.end()
        }
    }

    private func leave() {
        if let onExit {
            onExit()
        } else {
            dismiss()
        }
    }

    private func startSession() {
        showsIntro = false
        // Arm the clock hold before either begin() or resume() gets a chance to
        // install its timer. The tutorial itself releases it after its final
        // five-second explanation.
        if isTutorialArmed { model.setTutorialClockPaused(true) }
        if isTutorialArmed, model.state != .intro {
            // A zero-point pause is not progress: rewind it so the lesson can
            // shape the machine from the first round, then walk in as usual.
            model.rewindUnscoredRun()
            showsPauseCard = false
            playsFishEntrance = true
        } else if showsPauseCard, model.state != .intro {
            showsPauseCard = false
            model.resume()
            beginArmedTutorialIfPossible()
        } else {
            showsPauseCard = false
            playsFishEntrance = true
        }
    }

    private func finishFishEntrance() {
        guard playsFishEntrance else { return }
        playsFishEntrance = false
        Task {
            await model.begin()
            // The walkthrough opens on the first round, once the fish has swum
            // in and there is a reef to talk about. Disarming it here is what
            // makes the pause card offer Continue rather than Start tutorial.
            beginArmedTutorialIfPossible()
        }
    }

    private func beginArmedTutorialIfPossible() {
        guard isTutorialArmed, model.cards == 0, model.state != .intro else { return }
        isTutorialArmed = false
        tutorial.begin(model: model)
    }

    /// The cap on the start card. The lesson may still be added to an active
    /// run until its first point has been earned.
    private func toggleTutorial() {
        AppAudio.shared.playMenuTap()
        let savedPoints = PausedSessionStore.shared.session(request.board)?.cards ?? 0
        guard !tutorial.isActive,
              !model.isGameOver,
              model.cards == 0,
              savedPoints == 0 else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                showsTutorialNotice = true
            }
            return
        }
        withAnimation(.snappy(duration: 0.2)) { isTutorialArmed.toggle() }
    }

    // MARK: - Playfield

    private var playfield: some View {
        // The reef is the whole screen — water from the very top edge down to
        // the sea floor at the very bottom — with the HUD laid over it. Reading
        // the insets here is what keeps the fish clear of the HUD and the sum
        // clear of the home indicator.
        // The HUD keeps a floor under it, so it still clears the status bar on
        // the very first frame, before the insets have been sampled.
        let topInset = max(screenInsets.top, isPad ? 24 : 54)

        return ZStack(alignment: .top) {
            MathStepsPlayfield(round: model.round,
                               selectedOptionID: model.selectedOptionID,
                               brokenOptionIDs: model.brokenOptionIDs,
                               routeRounds: model.routeRounds,
                               brokenRouteOptionIDs: model.brokenRouteOptionIDs,
                               currentStep: model.currentStep,
                               maximumSteps: model.maximumRounds,
                               character: character,
                               isPad: isPad,
                               isLive: model.acceptsInput,
                               isRunning: isReefRunning,
                               playsEntrance: playsFishEntrance,
                               playsLevelCompletion: playsLevelCompletion,
                               playsTimeOutFinale: playsTimeOutFinale,
                               reduceMotion: reduceMotion,
                               tutorialPlan: tutorial.clawPlan,
                               bottomReserve: screenInsets.bottom,
                               onSelect: model.select,
                               onRewardArrived: model.scoreBubbleArrived,
                               onCorrectLanding: model.stepLandingCompleted,
                               onEntranceComplete: finishFishEntrance,
                               onLevelCompletionFinished: finishLevelCompletion,
                               onTimeOutFinished: finishTimeOutFinale,
                               onTutorialMove: {
                                   tutorial.handleClaw(.movedClaw)
                               })

            hud
                .padding(.horizontal, max(isPad ? 18 : 7, screenInsets.leading + 5))
                .padding(.top, topInset + (isPad ? 8 : 6))
                .opacity(playsLevelCompletion || playsTimeOutFinale ? 0 : 1)
                .animation(.easeOut(duration: 0.22), value: playsLevelCompletion || playsTimeOutFinale)
                .allowsHitTesting(!playsLevelCompletion && !playsTimeOutFinale)

            // The walkthrough speaks from just under the HUD, clear of both the
            // sum on the coral and the water the first steps ask the player to
            // cross. It never takes a touch: the reef stays fully steerable
            // while a step is being read.
            if let message = tutorial.message, !playsLevelCompletion, !playsTimeOutFinale {
                TutorialMessageCard(text: message, theme: character, isPad: isPad)
                    .padding(.horizontal, max(isPad ? 28 : 14, screenInsets.leading + 12))
                    .padding(.top, topInset + hudHeight + (isPad ? 22 : 16))
                    // Scales up in place rather than sliding down: a card that
                    // travelled would cross the HUD on its way in.
                    .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .top)))
                    .allowsHitTesting(false)
                    .id(tutorial.step)
            }
        }
        .ignoresSafeArea()
    }

    private func finishLevelCompletion() {
        guard playsLevelCompletion else { return }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
            showsResult = true
        }
        // Keep the final bubble bloom under the card during its entrance so
        // there is never a flash of the bare playfield between both scenes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            playsLevelCompletion = false
        }
    }

    private func finishTimeOutFinale() {
        guard playsTimeOutFinale else { return }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
            showsResult = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            playsTimeOutFinale = false
        }
    }

    // MARK: - HUD

    private var hud: some View {
        HStack(spacing: hudSpacing) {
            pauseButton

            GameplayPromptBadge(prompt: model.round?.question.prompt ?? "",
                                isPad: isPad)
                .frame(maxWidth: .infinity)

            VStack(spacing: hudMetricSpacing) {
                GameplayTimerBadge(clock: model.clock,
                                   isPad: isPad,
                                   width: hudMetricWidth,
                                   height: hudMetricHeight,
                                   palette: clawPalette,
                                   highlightsTutorial: tutorial.clawPlan.highlightsTimer)

                ClawScoreBadge(score: model.highestStep,
                               maximum: model.maximumRounds,
                               isPad: isPad,
                               width: hudMetricWidth,
                               height: hudMetricHeight)
            }
        }
        .frame(maxWidth: isPad ? 900 : .infinity)
        .frame(height: hudHeight)
        .frame(maxWidth: .infinity)
    }

    private var pauseButton: some View {
        Button {
            AppAudio.shared.playMenuTap()
            model.pause()
            showsPauseCard = true
            showsIntro = true
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(red: 1.00, green: 0.84, blue: 0.25),
                                                Color(red: 1.00, green: 0.57, blue: 0.04)],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .overlay {
                        Circle()
                            .stroke(Color(red: 1.00, green: 0.73, blue: 0.12),
                                    lineWidth: isPad ? 6 : 4)
                    }
                    .overlay(alignment: .topLeading) {
                        Capsule()
                            .fill(.white.opacity(0.48))
                            .frame(width: hudHeight * 0.38,
                                   height: isPad ? 7 : 5)
                            .rotationEffect(.degrees(-24))
                            .offset(x: hudHeight * 0.17, y: hudHeight * 0.13)
                    }

                Image(systemName: "pause.fill")
                    .font(.system(size: pauseGlyphSize, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: Color.orange.opacity(0.45), radius: 2, y: 2)
            }
            .frame(width: hudHeight, height: hudHeight)
            .shadow(color: Color(red: 0.02, green: 0.25, blue: 0.58).opacity(0.24),
                    radius: isPad ? 9 : 6,
                    y: isPad ? 6 : 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pause")
        .accessibilityLabel(Text("game.pause"))
    }

    private var hudHeight: CGFloat { isPad ? 86 : 62 }
    private var hudSpacing: CGFloat { isPad ? 12 : 7 }
    private var hudMetricSpacing: CGFloat { isPad ? 6 : 4 }
    private var hudMetricWidth: CGFloat { isPad ? 148 : 98 }
    private var hudMetricHeight: CGFloat { (hudHeight - hudMetricSpacing) / 2 }
    private var pauseGlyphSize: CGFloat { isPad ? 31 : 23 }

    /// The reef only ticks while the level is actually being played: never
    /// behind the start card or the result card, and never while the app is in
    /// the background.
    private var isReefRunning: Bool {
        !showsIntro && (!model.isGameOver || playsLevelCompletion || playsTimeOutFinale)
            && scenePhase == .active
    }
}

/// The question plaque shares the HUD's layout row, keeping its top and bottom
/// edges locked to the pause button and the combined time/score column.
private struct GameplayPromptBadge: View {
    let prompt: String
    let isPad: Bool

    var body: some View {
        Text(verbatim: prompt)
            .font(.system(size: isPad ? 43 : 28, weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.06, green: 0.20, blue: 0.43))
            .minimumScaleFactor(0.42)
            .lineLimit(1)
            .padding(.horizontal, isPad ? 28 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    radius: 9,
                    y: 6)
            .id(prompt)
            .transition(.scale(scale: 0.94).combined(with: .opacity))
            .accessibilityIdentifier("claw-prompt")
    }
}

private struct GameplayTimerBadge: View {
    @ObservedObject var clock: GameClock
    let isPad: Bool
    let width: CGFloat
    let height: CGFloat
    let palette: ClawPalette
    let highlightsTutorial: Bool

    private var remaining: Double { clock.remaining }
    private var seconds: Int { max(0, Int(remaining.rounded(.up))) }
    private var timeText: String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var iconWidth: CGFloat { isPad ? 23 : 16 }
    private var horizontalPadding: CGFloat { isPad ? 14 : 10 }

    var body: some View {
        HStack(spacing: isPad ? 9 : 6) {
            Image(systemName: "clock.fill")
                .font(.system(size: iconWidth, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.06, green: 0.20, blue: 0.43).opacity(0.38),
                        radius: 1,
                        y: 1)
                .frame(width: iconWidth)

            Text(verbatim: timeText)
                .font(.system(size: isPad ? 22 : 15, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.72)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .shadow(color: Color(red: 0.06, green: 0.20, blue: 0.43).opacity(0.42),
                        radius: 1,
                        y: 1)
        }
        .padding(.horizontal, horizontalPadding)
        .foregroundStyle(.white)
        .frame(width: width, height: height)
        .background(GameplayMetricBackground(height: height, isPad: isPad))
        .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        .overlay {
            if highlightsTutorial {
                GameplayTimerFocus(color: palette.character.color,
                                   isPad: isPad)
            }
        }
        .accessibilityIdentifier("timer")
        .accessibilityLabel(Text(L("game.claw.timeRemaining \(seconds)")))
    }
}

private struct ClawScoreBadge: View {
    let score: Int
    let maximum: Int
    let isPad: Bool
    let width: CGFloat
    let height: CGFloat

    private var iconWidth: CGFloat { isPad ? 23 : 16 }
    private var horizontalPadding: CGFloat { isPad ? 14 : 10 }

    var body: some View {
        HStack(spacing: isPad ? 9 : 6) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: iconWidth, weight: .black))
                .foregroundStyle(.white)
                .shadow(color: Color(red: 0.06, green: 0.20, blue: 0.43).opacity(0.38),
                        radius: 1,
                        y: 1)
                .frame(width: iconWidth)

            Text(verbatim: "\(LN(score)) / \(LN(maximum))")
                .font(.system(size: isPad ? 21 : 14, weight: .black, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.68)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .shadow(color: Color(red: 0.06, green: 0.20, blue: 0.43).opacity(0.42),
                        radius: 1,
                        y: 1)
        }
        .padding(.horizontal, horizontalPadding)
        .foregroundStyle(.white)
        .frame(width: width, height: height)
        .background(GameplayMetricBackground(height: height, isPad: isPad))
        .shadow(color: .black.opacity(0.25), radius: 5, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(score) / \(maximum)"))
    }
}

/// The compact counters use the same warm surface as the pause button. White
/// values and navy icons keep both pieces readable without a second dark fill.
private struct GameplayMetricBackground: View {
    let height: CGFloat
    let isPad: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(
                LinearGradient(colors: [Color(red: 1.00, green: 0.84, blue: 0.25),
                                        Color(red: 1.00, green: 0.57, blue: 0.05)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .overlay {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .stroke(Color(red: 1.00, green: 0.72, blue: 0.10),
                            lineWidth: isPad ? 2.5 : 2)
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.white.opacity(0.34))
                    .frame(height: isPad ? 2.5 : 2)
                    .padding(.horizontal, isPad ? 18 : 12)
                    .padding(.top, isPad ? 4 : 3)
            }
    }
}

/// Five-second focus beat around the countdown before it starts. This uses a
/// self-contained pulse because the HUD is deliberately isolated from the claw
/// engine's high-frequency frame clock.
private struct GameplayTimerFocus: View {
    let color: Color
    let isPad: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulses = false

    var body: some View {
        ZStack {
            Capsule()
                .stroke(.white.opacity(0.96), lineWidth: isPad ? 5 : 3.5)
                .scaleEffect(x: pulses ? 1.09 : 1.03,
                             y: pulses ? 1.20 : 1.08)
                .opacity(pulses ? 0.56 : 0.94)
                .shadow(color: color.opacity(0.96), radius: isPad ? 16 : 11)

            Capsule()
                .stroke(color,
                        style: StrokeStyle(lineWidth: isPad ? 4 : 3,
                                           lineCap: .round,
                                           dash: [isPad ? 13 : 10, isPad ? 9 : 7]))
                .scaleEffect(x: pulses ? 1.15 : 1.08,
                             y: pulses ? 1.30 : 1.16)
                .shadow(color: .white.opacity(0.76), radius: 4)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                pulses = true
            }
        }
    }
}

/// The original mounted timer remains available to the promo trailer. The
/// production stepping game uses the compact horizontal timer above instead.
struct ClawTimerBadge: View {
    @ObservedObject var clock: GameClock
    let isPad: Bool
    let size: CGFloat
    let palette: ClawPalette
    let highlightsTutorial: Bool

    private var remaining: Double { clock.remaining }
    private var total: Double { clock.total }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, remaining / total))
    }

    private var seconds: Int { max(0, Int(remaining.rounded(.up))) }

    var body: some View {
        let mountSize = size + (isPad ? 16 : 12)
        return ZStack {
            RoundedRectangle(cornerRadius: isPad ? 7 : 5, style: .continuous)
                .fill(palette.woodDeep)
                .frame(width: mountSize * 0.28, height: mountSize * 0.34)
                .offset(y: mountSize * 0.43)

            Circle()
                .fill(
                    LinearGradient(colors: [palette.woodLight,
                                            palette.wood,
                                            palette.woodDeep],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: mountSize, height: mountSize)
                .overlay {
                    Circle()
                        .strokeBorder(palette.woodDeep,
                                      lineWidth: isPad ? 3 : 2)
                }
                .overlay {
                    CabinetMountFasteners(size: isPad ? 5 : 4,
                                          inset: isPad ? 7 : 6,
                                          palette: palette)
                        .clipShape(Circle())
                }
                .overlay {
                    CabinetHUDWoodGrain(color: palette.woodDeep)
                        .clipShape(Circle())
                }

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [palette.character.deepColor,
                                                Color.black.opacity(0.88)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                Circle()
                    .stroke(
                        LinearGradient(colors: [palette.woodLight,
                                                palette.woodDeep],
                                       startPoint: .top, endPoint: .bottom),
                        lineWidth: isPad ? 5 : 4
                    )
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(palette.character.color,
                            style: StrokeStyle(lineWidth: isPad ? 6 : 5, lineCap: .round))
                    .shadow(color: palette.character.skyColor.opacity(0.75), radius: 3)
                    .rotationEffect(.degrees(-90))
                    .padding(isPad ? 6 : 5)
                Text(verbatim: LN(seconds))
                    .font(.system(size: isPad ? 26 : 18, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(palette.character.skyColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
            }
            .frame(width: size, height: size)
        }
        .frame(width: mountSize, height: mountSize)
        .shadow(color: .black.opacity(0.42), radius: 4, y: 3)
        .overlay {
            if highlightsTutorial {
                TutorialTimerFocus(color: palette.character.color,
                                   deepColor: palette.character.deepColor,
                                   isPad: isPad)
            }
        }
        .accessibilityIdentifier("timer")
        .accessibilityLabel(Text(L("game.claw.timeRemaining \(seconds)")))
    }
}

private struct TutorialTimerFocus: View {
    let color: Color
    let deepColor: Color
    let isPad: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulses = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.96), lineWidth: isPad ? 5 : 3.5)
                .scaleEffect(pulses ? 1.14 : 1.03)
                .opacity(pulses ? 0.56 : 0.94)
                .shadow(color: color.opacity(0.96), radius: isPad ? 16 : 11)

            Circle()
                .stroke(color,
                        style: StrokeStyle(lineWidth: isPad ? 4 : 3,
                                           lineCap: .round,
                                           dash: [isPad ? 13 : 10, isPad ? 9 : 7]))
                .scaleEffect(pulses ? 1.22 : 1.10)
                .rotationEffect(.degrees(pulses ? 24 : 0))
                .shadow(color: .white.opacity(0.76), radius: 4)

            Image(systemName: "clock.fill")
                .font(.system(size: isPad ? 20 : 15, weight: .black))
                .foregroundStyle(.white)
                .padding(isPad ? 7 : 5)
                .background(deepColor, in: Circle())
                .overlay(Circle().stroke(.white, lineWidth: 2))
                .shadow(color: color.opacity(0.9), radius: 8)
                .offset(x: -(isPad ? 37 : 29), y: isPad ? 34 : 27)
                .scaleEffect(pulses ? 1.08 : 0.94)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                pulses = true
            }
        }
    }
}

struct CabinetMountFasteners: View {
    let size: CGFloat
    let inset: CGFloat
    let palette: ClawPalette

    var body: some View {
        VStack {
            row
            Spacer(minLength: 0)
            row
        }
        .padding(inset)
        .allowsHitTesting(false)
    }

    private var row: some View {
        HStack {
            fastener
            Spacer(minLength: 0)
            fastener
        }
    }

    private var fastener: some View {
        Circle()
            .fill(palette.woodDeep)
            .frame(width: size, height: size)
            .overlay {
                Capsule()
                    .fill(palette.woodLight.opacity(0.72))
                    .frame(width: size * 0.66, height: 1)
                    .rotationEffect(.degrees(-18))
            }
    }
}

struct CabinetHUDWoodGrain: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                for index in 0..<4 {
                    let y = size.height * (0.22 + CGFloat(index) * 0.18)
                    var path = Path()
                    path.move(to: CGPoint(x: size.width * 0.12, y: y))
                    path.addCurve(to: CGPoint(x: size.width * 0.88, y: y + CGFloat(index % 2) * 2),
                                  control1: CGPoint(x: size.width * 0.34, y: y - 2),
                                  control2: CGPoint(x: size.width * 0.64, y: y + 3))
                    context.stroke(path,
                                   with: .color(color.opacity(0.18)),
                                   style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Level wallpaper

/// The level's own quiet wallpaper: a staggered grid of the level's number and
/// sign ("3×", "−4", "25%") or a stacked fraction, in a faint wash of the
/// theme colour. Carried over from the original game.
struct LevelWallpaper: View {
    let level: MathLevel
    let tint: Color

    /// The glyph that fills the wallpaper, built from the level's own card
    /// number so it reads like the level itself. Fractions draw a stacked
    /// fraction instead and return nil here.
    private var glyph: String? {
        let n = level.cardNumber
        switch level.topic {
        case .addition:    return "\(n)+"
        case .subtraction: return "−\(n)"
        case .tables:      return "\(n)×"
        case .percentages: return "\(n)%"
        case .mixed:       return "\(n)★"
        case .fractions:   return nil
        }
    }

    private var isPad: Bool { AppLayout.isPad }
    private var fontSize: CGFloat { isPad ? 30 : 22 }
    private var spacingX: CGFloat { isPad ? 118 : 86 }
    private var spacingY: CGFloat { isPad ? 104 : 76 }

    var body: some View {
        GeometryReader { proxy in
            let columns = Int(ceil(proxy.size.width / spacingX)) + 1
            let rows = Int(ceil(proxy.size.height / spacingY)) + 1

            // A staggered grid of 150–300 Text views was rebuilt whenever the
            // HUD scored. One Canvas draw keeps the same wallpaper and costs a
            // single pass.
            Canvas { context, _ in
                for row in 0..<rows {
                    for column in 0..<columns {
                        let point = CGPoint(
                            x: CGFloat(column) * spacingX
                                + (row.isMultiple(of: 2) ? 0 : spacingX / 2),
                            y: CGFloat(row) * spacingY
                        )
                        drawTile(in: &context, at: point)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawTile(in context: inout GraphicsContext, at point: CGPoint) {
        let color = tint.opacity(0.10)
        if let glyph {
            context.draw(
                Text(verbatim: glyph)
                    .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                    .foregroundColor(color),
                at: point,
                anchor: .center
            )
            return
        }

        // The fraction levels have one denominator each, so the wallpaper
        // mirrors it: 1/3 on the thirds level, and so on.
        let stackedSize = fontSize * 0.62
        let stackedFont = Font.system(size: stackedSize, weight: .heavy, design: .rounded)
        context.draw(
            Text(verbatim: "1").font(stackedFont).foregroundColor(color),
            at: CGPoint(x: point.x, y: point.y - stackedSize * 0.55),
            anchor: .center
        )
        let ruleWidth = stackedSize * 0.9
        let rule = CGRect(x: point.x - ruleWidth / 2,
                          y: point.y - 1,
                          width: ruleWidth,
                          height: 2)
        context.fill(Path(rule), with: .color(color))
        context.draw(
            Text(verbatim: "\(level.cardNumber)").font(stackedFont).foregroundColor(color),
            at: CGPoint(x: point.x, y: point.y + stackedSize * 0.55),
            anchor: .center
        )
    }
}
