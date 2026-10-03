//
//  ClawMachineBackground.swift
//  Math Steps
//
//  A character-coloured sky shared by the main, welcome and Premium menus.
//  Layered clouds and soft wind trails make the theme feel playful without
//  putting busy decoration behind the controls.
//

import SwiftUI

enum MenuBackgroundStyle: Equatable {
    case standard
    case welcome

    var cloudIntensity: Double { self == .welcome ? 1.24 : 1 }
    var cloudScale: CGFloat { self == .welcome ? 1.10 : 1 }
    var colourStrength: Double { self == .welcome ? 1.12 : 1 }
}

struct ClawMachineBackground: View, Equatable {
    let character: AnimalCharacter
    var style: MenuBackgroundStyle = .standard

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let palette = MenuSkyPalette(character: character,
                                         colourStrength: style.colourStrength)

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: palette.top, location: 0),
                        .init(color: palette.middle, location: 0.48),
                        .init(color: palette.bottom, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [.white.opacity(style == .welcome ? 0.52 : 0.44),
                             .white.opacity(0)],
                    center: UnitPoint(x: 0.24, y: 0.04),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.68
                )

                MenuBreezeLayer(color: character.deepColor,
                                intensity: style.cloudIntensity)

                MenuCloudLayer(
                    accent: character.color,
                    tint: character.tintColor,
                    intensity: style.cloudIntensity,
                    scaleBoost: style.cloudScale
                )

                // A light veil keeps long translated copy and translucent
                // cards readable across every character palette.
                LinearGradient(
                    colors: [.white.opacity(0.02), .white.opacity(0.07)],
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
    let colourStrength: Double

    var top: Color { mix(character.skyRGB, (1.00, 1.00, 1.00), whiten(0.28)) }
    var middle: Color { mix(character.tintRGB, (1.00, 0.99, 0.96), whiten(0.32)) }
    var bottom: Color { mix(character.primaryRGB, (1.00, 0.98, 0.92), whiten(0.58)) }

    private func whiten(_ amount: Double) -> Double {
        1 - ((1 - amount) * colourStrength)
    }

    private func mix(_ base: (Double, Double, Double),
                     _ target: (Double, Double, Double),
                     _ amount: Double) -> Color {
        let t = min(max(amount, 0), 1)
        return Color(red: base.0 + (target.0 - base.0) * t,
                     green: base.1 + (target.1 - base.1) * t,
                     blue: base.2 + (target.2 - base.2) * t)
    }
}

/// Large, edge-weighted puffs leave the centre calm for menu content. A soft
/// theme-coloured underside gives each palette its own sky instead of laying
/// generic white stickers over a gradient.
private struct MenuCloudLayer: View {
    let accent: Color
    let tint: Color
    let intensity: Double
    let scaleBoost: CGFloat

    private struct Cloud {
        let centre: CGPoint
        let scale: CGFloat
        let opacity: Double
    }

    private let clouds: [Cloud] = [
        .init(centre: .init(x: 0.00, y: 0.13), scale: 0.96, opacity: 0.64),
        .init(centre: .init(x: 0.96, y: 0.20), scale: 0.70, opacity: 0.51),
        .init(centre: .init(x: 0.02, y: 0.43), scale: 0.58, opacity: 0.39),
        .init(centre: .init(x: 0.98, y: 0.56), scale: 0.92, opacity: 0.43),
        .init(centre: .init(x: 0.04, y: 0.77), scale: 0.82, opacity: 0.38),
        .init(centre: .init(x: 0.61, y: 0.96), scale: 1.22, opacity: 0.50)
    ]

    var body: some View {
        Canvas { context, size in
            let baseWidth = min(max(size.width * 0.48, 178), 440)

            for cloud in clouds {
                let width = baseWidth * cloud.scale * scaleBoost
                let height = width * 0.32
                let centre = CGPoint(x: size.width * cloud.centre.x,
                                     y: size.height * cloud.centre.y)
                let rect = CGRect(x: centre.x - width / 2,
                                  y: centre.y - height / 2,
                                  width: width,
                                  height: height)
                let path = cloudPath(in: rect)

                var cloudContext = context
                cloudContext.addFilter(.shadow(color: accent.opacity(0.11 * intensity),
                                                radius: max(5, width * 0.035),
                                                x: 0,
                                                y: max(3, height * 0.10)))
                let opacity = min(0.92, cloud.opacity * intensity)
                cloudContext.fill(
                    path,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .white.opacity(opacity), location: 0),
                            .init(color: .white.opacity(opacity * 0.82), location: 0.56),
                            .init(color: tint.opacity(opacity * 0.42), location: 1)
                        ]),
                        startPoint: CGPoint(x: rect.midX, y: rect.minY),
                        endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                    )
                )
                cloudContext.stroke(path,
                                    with: .color(accent.opacity(0.07 * intensity)),
                                    lineWidth: max(0.8, width * 0.005))
            }
        }
    }

    /// One continuous silhouette keeps the cloud soft and cohesive. Stroking
    /// separate circles would reveal their overlaps and make it look bubbly.
    private func cloudPath(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + rect.width * x,
                    y: rect.minY + rect.height * y)
        }

        var path = Path()
        path.move(to: point(0.03, 0.78))
        path.addCurve(to: point(0.22, 0.55),
                      control1: point(0.06, 0.63),
                      control2: point(0.13, 0.54))
        path.addCurve(to: point(0.38, 0.48),
                      control1: point(0.27, 0.49),
                      control2: point(0.32, 0.46))
        path.addCurve(to: point(0.55, 0.12),
                      control1: point(0.40, 0.25),
                      control2: point(0.47, 0.12))
        path.addCurve(to: point(0.73, 0.43),
                      control1: point(0.66, 0.12),
                      control2: point(0.72, 0.27))
        path.addCurve(to: point(0.91, 0.55),
                      control1: point(0.79, 0.43),
                      control2: point(0.86, 0.46))
        path.addCurve(to: point(0.98, 0.78),
                      control1: point(0.97, 0.59),
                      control2: point(1.00, 0.69))
        path.addCurve(to: point(0.03, 0.78),
                      control1: point(0.79, 1.02),
                      control2: point(0.22, 1.02))
        path.closeSubpath()
        return path
    }
}

/// Long, low-contrast curves continue the cloud language through the open
/// spaces. Unlike icons or cards they never read as controls or game pieces.
private struct MenuBreezeLayer: View {
    let color: Color
    let intensity: Double

    private struct Breeze {
        let start: CGPoint
        let control1: CGPoint
        let control2: CGPoint
        let end: CGPoint
        let width: CGFloat
        let opacity: Double
    }

    private let breezes: [Breeze] = [
        .init(start: .init(x: -0.06, y: 0.27), control1: .init(x: 0.06, y: 0.23), control2: .init(x: 0.18, y: 0.31), end: .init(x: 0.31, y: 0.27), width: 0.0042, opacity: 0.050),
        .init(start: .init(x: 0.70, y: 0.36), control1: .init(x: 0.82, y: 0.31), control2: .init(x: 0.93, y: 0.40), end: .init(x: 1.06, y: 0.35), width: 0.0034, opacity: 0.041),
        .init(start: .init(x: -0.05, y: 0.64), control1: .init(x: 0.06, y: 0.59), control2: .init(x: 0.19, y: 0.68), end: .init(x: 0.33, y: 0.63), width: 0.0032, opacity: 0.038),
        .init(start: .init(x: 0.64, y: 0.82), control1: .init(x: 0.76, y: 0.77), control2: .init(x: 0.90, y: 0.86), end: .init(x: 1.05, y: 0.81), width: 0.0040, opacity: 0.047)
    ]

    var body: some View {
        Canvas { context, size in
            for breeze in breezes {
                var path = Path()
                path.move(to: point(breeze.start, in: size))
                path.addCurve(to: point(breeze.end, in: size),
                              control1: point(breeze.control1, in: size),
                              control2: point(breeze.control2, in: size))
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: color.opacity(0), location: 0),
                            .init(color: color.opacity(breeze.opacity * intensity), location: 0.45),
                            .init(color: color.opacity(0), location: 1)
                        ]),
                        startPoint: point(breeze.start, in: size),
                        endPoint: point(breeze.end, in: size)
                    ),
                    style: StrokeStyle(lineWidth: max(1.2, size.width * breeze.width),
                                       lineCap: .round)
                )
            }
        }
    }

    private func point(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }
}
