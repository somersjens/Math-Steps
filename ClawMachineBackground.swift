//
//  ClawMachineBackground.swift
//  Math Steps
//
//  A quiet, character-coloured sky shared by the main, welcome and Premium
//  menus. Soft clouds keep the large surfaces airy; barely visible arithmetic
//  cards connect it to play without competing with the controls in front.
//

import SwiftUI

struct ClawMachineBackground: View, Equatable {
    let character: AnimalCharacter

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let palette = MenuSkyPalette(character: character)

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: palette.top, location: 0),
                        .init(color: palette.middle, location: 0.52),
                        .init(color: palette.bottom, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [.white.opacity(0.66), .white.opacity(0)],
                    center: UnitPoint(x: 0.28, y: 0.08),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.72
                )

                MenuCloudLayer(accent: character.color)

                MenuMathMotifs(color: character.deepColor)

                // A light veil keeps long translated copy and translucent
                // cards readable across every character palette.
                LinearGradient(
                    colors: [.white.opacity(0.04), .white.opacity(0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: size.width, height: size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MenuSkyPalette {
    let character: AnimalCharacter

    var top: Color { mix(character.skyRGB, (1.00, 1.00, 1.00), 0.42) }
    var middle: Color { mix(character.tintRGB, (1.00, 0.99, 0.96), 0.48) }
    var bottom: Color { mix(character.primaryRGB, (1.00, 0.98, 0.92), 0.72) }

    private func mix(_ base: (Double, Double, Double),
                     _ target: (Double, Double, Double),
                     _ amount: Double) -> Color {
        let t = min(max(amount, 0), 1)
        return Color(red: base.0 + (target.0 - base.0) * t,
                     green: base.1 + (target.1 - base.1) * t,
                     blue: base.2 + (target.2 - base.2) * t)
    }
}

/// Large, edge-weighted puffs leave the centre calm for menu content. They are
/// intentionally static: the menus already contain lively character motion.
private struct MenuCloudLayer: View {
    let accent: Color

    private struct Cloud {
        let centre: CGPoint
        let scale: CGFloat
        let opacity: Double
    }

    private let clouds: [Cloud] = [
        .init(centre: .init(x: 0.01, y: 0.15), scale: 0.84, opacity: 0.34),
        .init(centre: .init(x: 0.94, y: 0.10), scale: 0.62, opacity: 0.27),
        .init(centre: .init(x: 0.91, y: 0.48), scale: 0.78, opacity: 0.18),
        .init(centre: .init(x: 0.05, y: 0.72), scale: 0.70, opacity: 0.17),
        .init(centre: .init(x: 0.62, y: 0.96), scale: 1.02, opacity: 0.15)
    ]

    var body: some View {
        Canvas { context, size in
            let baseWidth = min(max(size.width * 0.42, 150), 390)

            for cloud in clouds {
                let width = baseWidth * cloud.scale
                let height = width * 0.30
                let centre = CGPoint(x: size.width * cloud.centre.x,
                                     y: size.height * cloud.centre.y)
                let rect = CGRect(x: centre.x - width / 2,
                                  y: centre.y - height / 2,
                                  width: width,
                                  height: height)
                var path = Path()
                path.addEllipse(in: CGRect(x: rect.minX,
                                           y: rect.minY + height * 0.42,
                                           width: width,
                                           height: height * 0.58))
                path.addEllipse(in: CGRect(x: rect.minX + width * 0.16,
                                           y: rect.minY + height * 0.18,
                                           width: width * 0.36,
                                           height: height * 0.72))
                path.addEllipse(in: CGRect(x: rect.minX + width * 0.39,
                                           y: rect.minY,
                                           width: width * 0.38,
                                           height: height * 0.88))
                path.addEllipse(in: CGRect(x: rect.minX + width * 0.67,
                                           y: rect.minY + height * 0.30,
                                           width: width * 0.24,
                                           height: height * 0.60))

                var cloudContext = context
                cloudContext.addFilter(.shadow(color: accent.opacity(0.055),
                                                radius: max(4, width * 0.025),
                                                x: 0,
                                                y: max(2, height * 0.06)))
                cloudContext.fill(path, with: .color(.white.opacity(cloud.opacity)))
            }
        }
    }
}

/// Faint tilted cards and arithmetic marks echo the level grid and sums. Their
/// low contrast makes them register as texture, never as tappable controls.
private struct MenuMathMotifs: View {
    let color: Color

    private struct Motif {
        enum Kind { case plus, minus, multiply, equal, card }
        let centre: CGPoint
        let scale: CGFloat
        let rotation: Double
        let kind: Kind
    }

    private let motifs: [Motif] = [
        .init(centre: .init(x: 0.12, y: 0.36), scale: 0.78, rotation: -8, kind: .plus),
        .init(centre: .init(x: 0.88, y: 0.28), scale: 0.64, rotation: 7, kind: .multiply),
        .init(centre: .init(x: 0.08, y: 0.57), scale: 0.66, rotation: -5, kind: .card),
        .init(centre: .init(x: 0.91, y: 0.67), scale: 0.72, rotation: 6, kind: .equal),
        .init(centre: .init(x: 0.25, y: 0.88), scale: 0.54, rotation: -9, kind: .minus),
        .init(centre: .init(x: 0.78, y: 0.89), scale: 0.58, rotation: 8, kind: .plus)
    ]

    var body: some View {
        Canvas { context, size in
            let unit = min(max(min(size.width, size.height) * 0.052, 22), 48)

            for motif in motifs {
                let centre = CGPoint(x: size.width * motif.centre.x,
                                     y: size.height * motif.centre.y)
                let side = unit * motif.scale
                var motifContext = context
                motifContext.translateBy(x: centre.x, y: centre.y)
                motifContext.rotate(by: .degrees(motif.rotation))
                motifContext.translateBy(x: -centre.x, y: -centre.y)

                let style = StrokeStyle(lineWidth: max(1.2, side * 0.085),
                                        lineCap: .round,
                                        lineJoin: .round)
                let shading = GraphicsContext.Shading.color(color.opacity(0.055))
                motifContext.stroke(path(for: motif.kind, centre: centre, side: side),
                                    with: shading,
                                    style: style)
            }
        }
    }

    private func path(for kind: Motif.Kind, centre: CGPoint, side: CGFloat) -> Path {
        let half = side / 2
        let short = side * 0.34
        var path = Path()

        switch kind {
        case .plus:
            path.move(to: CGPoint(x: centre.x - half, y: centre.y))
            path.addLine(to: CGPoint(x: centre.x + half, y: centre.y))
            path.move(to: CGPoint(x: centre.x, y: centre.y - half))
            path.addLine(to: CGPoint(x: centre.x, y: centre.y + half))
        case .minus:
            path.move(to: CGPoint(x: centre.x - half, y: centre.y))
            path.addLine(to: CGPoint(x: centre.x + half, y: centre.y))
        case .multiply:
            path.move(to: CGPoint(x: centre.x - short, y: centre.y - short))
            path.addLine(to: CGPoint(x: centre.x + short, y: centre.y + short))
            path.move(to: CGPoint(x: centre.x + short, y: centre.y - short))
            path.addLine(to: CGPoint(x: centre.x - short, y: centre.y + short))
        case .equal:
            path.move(to: CGPoint(x: centre.x - half, y: centre.y - side * 0.18))
            path.addLine(to: CGPoint(x: centre.x + half, y: centre.y - side * 0.18))
            path.move(to: CGPoint(x: centre.x - half, y: centre.y + side * 0.18))
            path.addLine(to: CGPoint(x: centre.x + half, y: centre.y + side * 0.18))
        case .card:
            let rect = CGRect(x: centre.x - side * 0.62,
                              y: centre.y - side * 0.78,
                              width: side * 1.24,
                              height: side * 1.56)
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: side * 0.22,
                                                             height: side * 0.22))
            path.move(to: CGPoint(x: centre.x - short, y: centre.y))
            path.addLine(to: CGPoint(x: centre.x + short, y: centre.y))
            path.move(to: CGPoint(x: centre.x, y: centre.y - short))
            path.addLine(to: CGPoint(x: centre.x, y: centre.y + short))
        }
        return path
    }
}

/// The character portraits already contain the elephant's grab housing. This
/// line completes that artwork back to the physical top of the display. For
/// the other portraits it disappears behind the top of their transparent
/// canvas, so character switching keeps one stable hanging composition.
struct MenuHangingRope: View {
    let endPoint: CGPoint
    var lineWidth: CGFloat = 4.5

    var body: some View {
        MenuHangingRopeShape(endPoint: endPoint)
            .stroke(
                LinearGradient(
                    colors: [Color(red: 0.70, green: 0.56, blue: 0.32),
                             Color(red: 0.22, green: 0.14, blue: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .shadow(color: .black.opacity(0.20), radius: 1, x: 1, y: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct MenuHangingRopeShape: Shape {
    var endPoint: CGPoint

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(endPoint.x, endPoint.y) }
        set { endPoint = CGPoint(x: newValue.first, y: newValue.second) }
    }

    func path(in rect: CGRect) -> Path {
        let end = CGPoint(x: endPoint.x, y: max(0, endPoint.y))
        let start = CGPoint(x: end.x, y: rect.minY)
        let bend = min(5, max(2, end.y * 0.025))
        var path = Path()
        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x - bend, y: start.y + end.y * 0.34),
            control2: CGPoint(x: end.x + bend, y: start.y + end.y * 0.73)
        )
        return path
    }
}
