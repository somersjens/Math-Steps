//
//  PromoTrailerHostView.swift
//  Math Steps
//
//  Captures the production stepping scene at a real device aspect ratio. Each
//  output has its own SwiftUI layout and is rendered directly at App Store
//  pixels by PromoTrailerRecorder.
//

import SwiftUI
import QuartzCore
#if canImport(UIKit)
import UIKit
#endif

struct PromoTrailerHostView: View {
    let layoutSize: CGSize
    let exportSize: CGSize
    let usesPadMetrics: Bool
    let captureProvider: () -> UIView?
    let onFinished: (URL?) -> Void

    @StateObject private var director = PromoTrailerDirector()
    @State private var encode = PromoEncodeState()
    @State private var displayLink: CADisplayLink?
    @State private var linkTarget: PromoDisplayLinkProxy?

    private var character: AnimalCharacter { director.character }
    private var palette: GameplayHUDPalette { GameplayHUDPalette(character: character) }
    // External phone capture uses a full-screen simulator whose physical
    // Dynamic Island is removed in the final spatial crop. Place the HUD just
    // below that crop; it lands at the intended small optical margin in the
    // exported frame. Pixel-exact in-app rendering needs no such allowance.
    private var topInset: CGFloat {
        if usesPadMetrics { return 24 }
        return PromoTrailerRuntime.usesExternalCapture ? 60 : 8
    }
    private var hudHeight: CGFloat { usesPadMetrics ? 86 : 62 }
    private var metricSpacing: CGFloat { usesPadMetrics ? 6 : 4 }
    private var metricWidth: CGFloat { usesPadMetrics ? 148 : 98 }
    private var metricHeight: CGFloat { (hudHeight - metricSpacing) / 2 }

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = usesPadMetrics ? 18 : 7
            let hudTop = topInset + (usesPadMetrics ? 8 : 6)
            let availableHUDWidth = max(0, proxy.size.width - horizontalPadding * 2)
            let scoreTarget = CGPoint(
                x: proxy.size.width - horizontalPadding - metricWidth
                    + (usesPadMetrics ? 14 : 10) + (usesPadMetrics ? 11.5 : 8),
                y: hudTop + metricHeight + metricSpacing + metricHeight / 2
            )

            ZStack(alignment: .top) {
                ZStack(alignment: .top) {
                    MathStepsPlayfield(
                        round: director.round,
                        selectedOptionID: director.selectedOptionID,
                        brokenOptionIDs: director.brokenOptionIDs,
                        routeRounds: director.routeRounds,
                        brokenRouteOptionIDs: director.brokenRouteOptionIDs,
                        currentStep: director.currentStep,
                        highestStep: director.highestStep,
                        maximumSteps: director.maximumSteps,
                        playthroughID: 0,
                        character: character,
                        isPad: usesPadMetrics,
                        isLive: director.isLive,
                        isRunning: true,
                        playsEntrance: director.playsEntrance,
                        playsLevelCompletion: director.playsLevelCompletion,
                        playsTimeOutFinale: false,
                        reduceMotion: false,
                        tutorialPlan: ClawTutorialPlan(),
                        bottomReserve: 0,
                        scoreTarget: scoreTarget,
                        scriptedSelection: director.scriptedSelection,
                        onSelect: director.acceptSelection,
                        onRewardArrived: director.rewardArrived,
                        onCorrectLanding: director.correctLandingCompleted,
                        onWrongFallCompleted: director.wrongFallCompleted,
                        onEntranceStanding: {},
                        onEntranceComplete: director.entranceCompleted,
                        onLevelCompletionFinished: director.levelCompletionFinished,
                        onTimeOutFinished: {},
                        onTutorialMove: {}
                    )
                    .id("promo-math-steps-playfield")

                    promoHUD(availableWidth: availableHUDWidth)
                        .frame(width: availableHUDWidth, height: hudHeight)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, hudTop)
                        .opacity(director.playsLevelCompletion ? 0 : 1)
                        .animation(.easeOut(duration: 0.22),
                                   value: director.playsLevelCompletion)

                    character.tintColor
                        .opacity(director.themeFlash * 0.68)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
                .blur(radius: director.backgroundBlur)

                PromoTrailerHeadline(text: director.headlineText,
                                     theme: character,
                                     isPad: usesPadMetrics)
                    .opacity(director.headlineOpacity)
                    .padding(.horizontal, usesPadMetrics ? 44 : 18)
                    .padding(.top, hudTop + hudHeight + (usesPadMetrics ? 17 : 12))
                    .allowsHitTesting(false)

                trailerIcon
            }
        }
        .frame(width: layoutSize.width, height: layoutSize.height)
        .clipped()
        .background(character.tintColor)
        .preferredColorScheme(.light)
        .persistentSystemOverlays(.hidden)
        .statusBarHidden(true)
        .ignoresSafeArea()
        .onAppear {
            LanguageManager.shared.override = .english
            startClock()
            startRecording()
        }
        .onDisappear { tearDown() }
    }

    private func promoHUD(availableWidth: CGFloat) -> some View {
        let spacing: CGFloat = usesPadMetrics ? 12 : 7
        let promptWidth = max(
            1,
            availableWidth - hudHeight - metricWidth - spacing * 2
        )

        return HStack(spacing: spacing) {
            GameplayPauseBadge(palette: palette,
                               isPad: usesPadMetrics,
                               side: hudHeight)
                .frame(width: hudHeight, height: hudHeight)

            GameplayPromptBadge(prompt: director.round.question.prompt,
                                isPad: usesPadMetrics,
                                palette: palette)
                .frame(width: promptWidth, height: hudHeight)

            VStack(spacing: metricSpacing) {
                GameplayTimerBadge(clock: director.clock,
                                   isPad: usesPadMetrics,
                                   width: metricWidth,
                                   height: metricHeight,
                                   palette: palette,
                                   highlightsTutorial: false)
                ClawScoreBadge(score: director.visibleScore,
                               maximum: director.maximumSteps,
                               isPad: usesPadMetrics,
                               width: metricWidth,
                               height: metricHeight,
                               palette: palette,
                               highlightsTutorial: false)
            }
        }
        .frame(width: availableWidth, height: hudHeight)
        .animation(.easeInOut(duration: 0.35), value: director.characterID)
        .allowsHitTesting(false)
    }

    private var trailerIcon: some View {
        VStack {
            Spacer()
            Image("trailer_promo")
                .resizable()
                .interpolation(.high)
                .aspectRatio(1, contentMode: .fit)
                .frame(width: usesPadMetrics ? 300 : 220,
                       height: usesPadMetrics ? 300 : 220)
                .clipShape(RoundedRectangle(cornerRadius: usesPadMetrics ? 68 : 50,
                                            style: .continuous))
                .shadow(color: .black.opacity(0.34), radius: 26, y: 12)
                .rotationEffect(.degrees(director.iconRotation))
                .scaleEffect(director.iconScale)
                .opacity(director.iconOpacity)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private func startRecording() {
        guard !encode.recordingStarted else { return }
        if PromoTrailerRuntime.usesExternalCapture {
            encode.recordingStarted = true
            encode.isFinishing = false
            encode.lastCaptureIndex = -1
            encode.warmupFramesRemaining = 0
            let documents = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask)[0]
            try? FileManager.default.removeItem(
                at: documents.appendingPathComponent("promo-external-start.txt")
            )
            try? FileManager.default.removeItem(
                at: documents.appendingPathComponent("promo-external-complete.txt")
            )
            try? Data("ready\n".utf8).write(
                to: documents.appendingPathComponent("promo-external-ready.txt"),
                options: .atomic
            )
            print("PROMO_TRAILER_EXTERNAL_READY \(PromoTrailerRuntime.exportTag)")
            return
        }
        let recorder = PromoTrailerRecorder(size: exportSize,
                                            fps: PromoTrailerRuntime.framesPerSecond)
        encode.recorder = recorder
        do {
            try recorder.start()
            encode.recordingStarted = true
            encode.isFinishing = false
            encode.lastCaptureIndex = -1
            encode.warmupFramesRemaining = 8
            print("PROMO_TRAILER_RECORDING \(PromoTrailerRuntime.exportTag)")
        } catch {
            print("PROMO_TRAILER_ERROR \(error)")
            onFinished(nil)
        }
    }

    private func startClock() {
#if canImport(UIKit)
        guard displayLink == nil else { return }
        let proxy = PromoDisplayLinkProxy { [self] in
            Self.advanceEncode(
                encode: encode,
                director: director,
                layoutSize: layoutSize,
                exportSize: exportSize,
                captureProvider: captureProvider,
                onFinished: onFinished,
                stopClock: {
                    displayLink?.invalidate()
                    displayLink = nil
                }
            )
        }
        linkTarget = proxy
        let link = CADisplayLink(target: proxy,
                                 selector: #selector(PromoDisplayLinkProxy.tick))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30,
                                                        maximum: 30,
                                                        preferred: 30)
        link.add(to: .main, forMode: .common)
        displayLink = link
#endif
    }

    private static func advanceEncode(encode: PromoEncodeState,
                                      director: PromoTrailerDirector,
                                      layoutSize: CGSize,
                                      exportSize: CGSize,
                                      captureProvider: () -> UIView?,
                                      onFinished: @escaping (URL?) -> Void,
                                      stopClock: @escaping () -> Void) {
        guard encode.recordingStarted, !encode.isFinishing else { return }

        if PromoTrailerRuntime.usesExternalCapture,
           encode.externalStartedAt == 0 {
            let documents = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask)[0]
            guard FileManager.default.fileExists(
                atPath: documents.appendingPathComponent("promo-external-start.txt").path
            ) else { return }
            encode.externalStartedAt = CACurrentMediaTime()
            director.start()
            return
        }

        if encode.warmupFramesRemaining > 0 {
            encode.warmupFramesRemaining -= 1
            if encode.warmupFramesRemaining == 0 {
                encode.externalStartedAt = CACurrentMediaTime()
                director.start()
            }
            return
        }

        let next = encode.lastCaptureIndex + 1
        let elapsed = PromoTrailerRuntime.usesExternalCapture
            ? max(0, CACurrentMediaTime() - encode.externalStartedAt)
            : Double(next) / Double(PromoTrailerRuntime.framesPerSecond)
        director.tick(elapsed: elapsed)
        encode.lastCaptureIndex = next
        CATransaction.flush()

        if !PromoTrailerRuntime.usesExternalCapture,
           let image = snapshot(layoutSize: layoutSize,
                                exportSize: exportSize,
                                captureProvider: captureProvider) {
                encode.recorder?.capture(image: image, at: elapsed)
        }

        if next.isMultiple(of: 30) {
            print("PROMO_TRAILER_FRAME \(next)")
        }
        if director.isFinished || elapsed >= PromoTrailerRuntime.maximumDuration {
            encode.isFinishing = true
            if PromoTrailerRuntime.usesExternalCapture {
                encode.recordingStarted = false
                stopClock()
                publishExternalEvents(director.trailerAudioCues,
                                      duration: elapsed)
                print("PROMO_TRAILER_EXTERNAL_DONE")
                return
            }
            encode.recorder?.audioCues = director.trailerAudioCues
            finishEncode(encode: encode,
                         onFinished: onFinished,
                         stopClock: stopClock)
        }
    }

    private static func snapshot(layoutSize: CGSize,
                                 exportSize: CGSize,
                                 captureProvider: () -> UIView?) -> UIImage? {
        guard let view = captureProvider() else { return nil }
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let layoutImage = UIGraphicsImageRenderer(size: layoutSize,
                                                  format: format).image { _ in
            view.drawHierarchy(in: CGRect(origin: .zero, size: layoutSize),
                               afterScreenUpdates: true)
        }
        return UIGraphicsImageRenderer(size: exportSize,
                                       format: format).image { _ in
            layoutImage.draw(in: CGRect(origin: .zero, size: exportSize))
        }
    }

    private static func finishEncode(encode: PromoEncodeState,
                                     onFinished: @escaping (URL?) -> Void,
                                     stopClock: @escaping () -> Void) {
        encode.recordingStarted = false
        stopClock()
        Task {
            let url = await encode.recorder?.finish()
            print("PROMO_TRAILER_DONE \(url?.path ?? "nil")")
            onFinished(url)
        }
    }

    private static func publishExternalEvents(
        _ cues: [(time: TimeInterval, file: String, volume: Float)],
        duration: TimeInterval
    ) {
        let documents = FileManager.default.urls(for: .documentDirectory,
                                                 in: .userDomainMask)[0]
        let text = cues.map {
            String(format: "%.3f\t%@\t%.3f", $0.time, $0.file, $0.volume)
        }.joined(separator: "\n") + "\n"
        try? Data(text.utf8).write(to: documents.appendingPathComponent("promo-events.tsv"),
                                   options: .atomic)
        try? Data(String(format: "%.3f\n", duration).utf8).write(
            to: documents.appendingPathComponent("promo-duration.txt"),
            options: .atomic
        )
        try? Data("complete\n".utf8).write(
            to: documents.appendingPathComponent("promo-external-complete.txt"),
            options: .atomic
        )
    }

    private func tearDown() {
        displayLink?.invalidate()
        displayLink = nil
        encode.recordingStarted = false
    }
}

private struct PromoTrailerHeadline: View {
    let text: String
    let theme: AnimalCharacter
    let isPad: Bool

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: isPad ? 25 : 17,
                          weight: .heavy,
                          design: .rounded))
            .foregroundStyle(theme.deepColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, isPad ? 18 : 13)
            .padding(.vertical, isPad ? 9 : 7)
            .background(.white.opacity(0.94), in: Capsule())
            .overlay(Capsule().stroke(theme.skyColor, lineWidth: 1.5))
            .shadow(color: theme.deepColor.opacity(0.18), radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.30), value: theme.id)
    }
}

final class PromoEncodeState {
    var recordingStarted = false
    var isFinishing = false
    var recorder: PromoTrailerRecorder?
    var lastCaptureIndex: Int64 = -1
    var warmupFramesRemaining = 0
    var externalStartedAt: CFTimeInterval = 0
}

#if canImport(UIKit)
final class PromoDisplayLinkProxy: NSObject {
    private let handler: () -> Void
    init(handler: @escaping () -> Void) { self.handler = handler }
    @objc func tick() { handler() }
}
#endif
