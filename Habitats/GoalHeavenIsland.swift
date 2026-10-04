//
//  GoalHeavenIsland.swift
//  Math Steps
//
//  The finish of every stepping course: a small floating paradise built for
//  the playing character. Like the habitats it is drawn entirely from paths,
//  curves and gradients. The heavy artwork is painted once at its final,
//  closest size and only scaled down while the island approaches, so the
//  camera animation never re-renders it; a light particle layer on either
//  side of the artwork supplies the motion.
//
//  Coordinates: every painter works in a space whose origin is the centre of
//  the walkable top surface, with `u` the island's full width. The surface is
//  an ellipse of radii `rx` × `ry`; negative y points into the sky.
//

import SwiftUI

struct GoalHeavenIsland: View {
    let character: AnimalCharacter
    let isPad: Bool
    /// The island's size at the moment the character lands on it. The art is
    /// authored at this size and never scaled above it.
    let referenceSize: CGSize
    let isAnimating: Bool
    let celebrating: Bool
    /// 0 while the island is still far away, 1 once it is the next stop.
    var approach: CGFloat = 1
    /// Matches the duration of the final jump in the playfield.
    var landingDelay: Double = 0.76

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var celebrationStart: Date?

    var body: some View {
        GeometryReader { proxy in
            let metrics = GoalHeavenMetrics(width: max(1, referenceSize.width),
                                            height: max(1, referenceSize.height),
                                            isPad: isPad)
            let scale = proxy.size.width / metrics.u
            let canvas = metrics.canvasSize
            let anchor = metrics.surfaceCenter
            let theme = GoalHeavenTheme(characterID: character.id)
            let paused = !isAnimating || reduceMotion

            let atmosphere = metrics.atmosphereSize
            let atmosphereAnchor = metrics.atmosphereCenter
            let surfaceFraction = atmosphereAnchor.y / atmosphere.height

            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { timeline in
                    Canvas { context, _ in
                        context.translateBy(x: atmosphereAnchor.x, y: atmosphereAnchor.y)
                        // The sky effects build up over the last steps.
                        context.opacity = 0.30 + 0.70 * Double(approach)
                        let painter = GoalHeavenPainter(metrics: metrics, character: character)
                        painter.paintAtmosphere(in: &context,
                                                theme: theme,
                                                time: timeline.date.timeIntervalSinceReferenceDate,
                                                celebration: celebrationAge(at: timeline.date))
                    }
                }
                .frame(width: atmosphere.width, height: atmosphere.height)
                // Below the surface the light only seeps past the island's
                // flanks; it must dissolve before it reaches the frame's
                // bottom instead of ending in a hard line over the bridge.
                .mask {
                    LinearGradient(stops: [.init(color: .white, location: 0),
                                           .init(color: .white, location: surfaceFraction),
                                           .init(color: .clear, location: min(1, surfaceFraction + (1 - surfaceFraction) * 0.85))],
                                   startPoint: .top, endPoint: .bottom)
                }
                .offset(y: -metrics.atmosphereExtraTop * 0.5)

                GoalHeavenArtwork(character: character, metrics: metrics)
                    .equatable()
                    .frame(width: canvas.width, height: canvas.height)

                TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: paused)) { timeline in
                    Canvas { context, _ in
                        context.translateBy(x: anchor.x, y: anchor.y)
                        let painter = GoalHeavenPainter(metrics: metrics, character: character)
                        painter.paintParticles(in: &context,
                                               theme: theme,
                                               time: timeline.date.timeIntervalSinceReferenceDate,
                                               celebration: celebrationAge(at: timeline.date))
                    }
                }
                .frame(width: canvas.width, height: canvas.height)
            }
            .frame(width: canvas.width, height: canvas.height)
            .scaleEffect(scale)
            .position(x: proxy.size.width * 0.5 - (anchor.x - canvas.width * 0.5) * scale,
                      y: proxy.size.height * 0.43 - (anchor.y - canvas.height * 0.5) * scale)
        }
        .onChange(of: celebrating, initial: true) { _, active in
            // The finale starts with the jump onto the island; the burst
            // belongs to the moment the feet touch the dais.
            celebrationStart = active && !reduceMotion ? Date().addingTimeInterval(landingDelay) : nil
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func celebrationAge(at date: Date) -> Double? {
        guard let celebrationStart else { return nil }
        let age = date.timeIntervalSince(celebrationStart)
        return age >= 0 ? age : nil
    }
}

// MARK: - Geometry

struct GoalHeavenMetrics: Equatable {
    let u: CGFloat
    let hh: CGFloat
    let isPad: Bool

    init(width: CGFloat, height: CGFloat, isPad: Bool) {
        u = width
        hh = height
        self.isPad = isPad
    }

    /// Room around the island frame for scenery that rises above it or leans
    /// beyond its sides. The underside is deliberately shallow: anything
    /// deeper would cover the answer row while the island approaches.
    var marginX: CGFloat { u * 0.40 }
    var headroom: CGFloat { u * 1.20 }
    var footroom: CGFloat { hh * 0.80 }
    var canvasSize: CGSize { CGSize(width: u + marginX * 2, height: headroom + footroom) }
    var surfaceCenter: CGPoint { CGPoint(x: canvasSize.width * 0.5, y: headroom) }

    /// The glow and rays reach well past the scenery. Their layer extends
    /// this much further left, right and up so it fades out on its own
    /// instead of ending in a visible edge while the island approaches.
    var atmosphereExtraX: CGFloat { u * 0.45 }
    var atmosphereExtraTop: CGFloat { u * 0.90 }
    var atmosphereSize: CGSize {
        CGSize(width: canvasSize.width + atmosphereExtraX * 2, height: canvasSize.height + atmosphereExtraTop)
    }
    var atmosphereCenter: CGPoint {
        CGPoint(x: surfaceCenter.x + atmosphereExtraX, y: surfaceCenter.y + atmosphereExtraTop)
    }

    var rx: CGFloat { u * 0.5 }
    var ry: CGFloat { hh * 0.33 }
    var lip: CGFloat { hh * 0.12 }
    /// Deepest point of the underside, measured from the surface centre.
    var floor: CGFloat { hh * 0.66 }
    /// Where the character's feet meet the island (see the playfield's
    /// destination maths: frame centre + 8% of the width).
    var feetY: CGFloat { hh * 0.07 + u * 0.08 }
}

enum GoalHeavenTheme {
    case dog, lion, octopus, crab, elephant, bear, fox, frog, penguin, bunny

    init(characterID: String) {
        switch characterID {
        case "lion": self = .lion
        case "octopus": self = .octopus
        case "crab": self = .crab
        case "elephant": self = .elephant
        case "bear": self = .bear
        case "fox": self = .fox
        case "frog": self = .frog
        case "penguin": self = .penguin
        case "bunny": self = .bunny
        default: self = .dog
        }
    }
}

private struct GoalHeavenArtwork: View, Equatable {
    let character: AnimalCharacter
    let metrics: GoalHeavenMetrics

    var body: some View {
        Canvas { context, _ in
            context.translateBy(x: metrics.surfaceCenter.x, y: metrics.surfaceCenter.y)
            let painter = GoalHeavenPainter(metrics: metrics, character: character)
            painter.paintArtwork(in: &context, theme: GoalHeavenTheme(characterID: character.id))
        }
    }
}

// MARK: - Painter

struct GoalHeavenPainter {
    let metrics: GoalHeavenMetrics
    let character: AnimalCharacter

    var u: CGFloat { metrics.u }
    var rx: CGFloat { metrics.rx }
    var ry: CGFloat { metrics.ry }
    var lip: CGFloat { metrics.lip }
    var floorDepth: CGFloat { metrics.floor }
    var feetY: CGFloat { metrics.feetY }
    var brush: HabitatBrush { HabitatBrush(size: CGSize(width: u, height: u), isPad: false) }

    /// Absolute point from fractions of the island width.
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * u, y: y * u) }
    /// Point on the walkable surface: `fx` and `fy` are fractions of its radii.
    func surf(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: fx * rx, y: fy * ry) }
    func s(_ fraction: CGFloat) -> CGFloat { fraction * u }

    func backY(_ x: CGFloat) -> CGFloat {
        let t = min(1, abs(x) / rx)
        return -ry * sqrt(max(0, 1 - t * t))
    }

    func frontY(_ x: CGFloat) -> CGFloat { -backY(x) }

    var surfaceRect: CGRect { CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2) }
    var surfacePath: Path { Path(ellipseIn: surfaceRect) }

    func circle(_ center: CGPoint, _ radius: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                               width: radius * 2, height: radius * 2))
    }

    func oval(_ center: CGPoint, _ radiusX: CGFloat, _ radiusY: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - radiusX, y: center.y - radiusY,
                               width: radiusX * 2, height: radiusY * 2))
    }

    func vertical(_ colors: [Color], _ top: CGFloat, _ bottom: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: colors),
                        startPoint: CGPoint(x: 0, y: top),
                        endPoint: CGPoint(x: 0, y: bottom))
    }

    func linear(_ colors: [Color], _ from: CGPoint, _ to: CGPoint) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: colors), startPoint: from, endPoint: to)
    }

    func radial(_ colors: [Color], _ center: CGPoint, _ radius: CGFloat) -> GraphicsContext.Shading {
        .radialGradient(Gradient(colors: colors), center: center, startRadius: 0, endRadius: radius)
    }

    func round(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    func noise(_ index: Int, _ channel: Int, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
        habitatNoise(index, channel, lower, upper)
    }

    // MARK: Dispatch

    func paintArtwork(in context: inout GraphicsContext, theme: GoalHeavenTheme) {
        switch theme {
        case .dog: paintDogHeaven(in: &context)
        case .lion: paintLionHeaven(in: &context)
        case .octopus: paintOctopusHeaven(in: &context)
        case .crab: paintCrabHeaven(in: &context)
        case .elephant: paintElephantHeaven(in: &context)
        case .bear: paintBearHeaven(in: &context)
        case .fox: paintFoxHeaven(in: &context)
        case .frog: paintFrogHeaven(in: &context)
        case .penguin: paintPenguinHeaven(in: &context)
        case .bunny: paintBunnyHeaven(in: &context)
        }
    }

    /// Behind the artwork: rotating light, breathing aura and any sky effect
    /// that belongs to the theme (e.g. the aurora over the ice palace).
    func paintAtmosphere(in context: inout GraphicsContext,
                         theme: GoalHeavenTheme,
                         time: Double,
                         celebration: Double?) {
        let style = atmosphereStyle(for: theme)
        let boost = celebrationBoost(celebration)
        let breathe = 1 + 0.04 * CGFloat(sin(time * 1.3))
        context.fill(circle(style.rayCenter, s(0.95) * breathe),
                     with: radial([style.glow.opacity(0.55 + 0.25 * boost), style.glow.opacity(0)],
                                  style.rayCenter, s(0.95) * breathe))
        paintRays(in: &context,
                  center: style.rayCenter,
                  color: style.rays,
                  count: 16,
                  length: s(1.05),
                  rotation: time * 0.045,
                  opacity: 0.26 + 0.30 * Double(boost))
        if theme == .penguin {
            paintAurora(in: &context, time: time)
        }
    }

    func paintParticles(in context: inout GraphicsContext,
                        theme: GoalHeavenTheme,
                        time: Double,
                        celebration: Double?) {
        switch theme {
        case .dog: paintDogBalloons(in: &context, time: time); paintFloatingHearts(in: &context, time: time)
        case .lion: paintGoldDust(in: &context, time: time); paintBirds(in: &context, time: time)
        case .octopus: paintBubbles(in: &context, time: time); paintSkyFish(in: &context, time: time)
        case .crab: paintGulls(in: &context, time: time); paintBubbles(in: &context, time: time, count: 7)
        case .elephant:
            paintButterflies(in: &context, time: time, palette: [Color(red: 1.0, green: 0.45, blue: 0.62),
                                                                 Color(red: 0.36, green: 0.62, blue: 1.0)])
        case .bear: paintBees(in: &context, time: time); paintHoneyDrips(in: &context, time: time)
        case .fox: paintFallingLeaves(in: &context, time: time); paintLanternGlow(in: &context, time: time)
        case .frog: paintPondRipples(in: &context, time: time); paintFireflies(in: &context, time: time)
            paintDragonflies(in: &context, time: time)
        case .penguin: paintSnowfall(in: &context, time: time)
        case .bunny: paintPetals(in: &context, time: time)
            paintButterflies(in: &context, time: time, palette: [Color(red: 1.0, green: 0.78, blue: 0.20),
                                                                 Color(red: 0.70, green: 0.50, blue: 1.0)])
        }
        paintWaterfallShimmer(in: &context, theme: theme, time: time)
        paintTwinkles(in: &context, theme: theme, time: time, celebration: celebration)
        if let celebration {
            paintConfetti(in: &context, age: celebration)
        }
    }

    private func celebrationBoost(_ age: Double?) -> CGFloat {
        guard let age else { return 0 }
        let rise = min(1, age / 0.45)
        return CGFloat(rise * (0.75 + 0.25 * sin(age * 4)))
    }

    struct AtmosphereStyle {
        let rayCenter: CGPoint
        let glow: Color
        let rays: Color
    }

    func atmosphereStyle(for theme: GoalHeavenTheme) -> AtmosphereStyle {
        switch theme {
        case .dog:
            return .init(rayCenter: pt(0, -0.46), glow: Color(red: 1.0, green: 0.96, blue: 0.78),
                         rays: Color(red: 1.0, green: 0.97, blue: 0.80))
        case .lion:
            return .init(rayCenter: pt(0, -0.40), glow: Color(red: 1.0, green: 0.80, blue: 0.40),
                         rays: Color(red: 1.0, green: 0.86, blue: 0.48))
        case .octopus:
            return .init(rayCenter: pt(0, -0.34), glow: Color(red: 0.86, green: 0.78, blue: 1.0),
                         rays: Color(red: 0.92, green: 0.88, blue: 1.0))
        case .crab:
            return .init(rayCenter: pt(0.02, -0.34), glow: Color(red: 1.0, green: 0.74, blue: 0.56),
                         rays: Color(red: 1.0, green: 0.86, blue: 0.62))
        case .elephant:
            return .init(rayCenter: pt(0, -0.62), glow: Color(red: 1.0, green: 0.90, blue: 0.84),
                         rays: Color(red: 1.0, green: 0.96, blue: 0.86))
        case .bear:
            return .init(rayCenter: pt(0.04, -0.46), glow: Color(red: 1.0, green: 0.86, blue: 0.50),
                         rays: Color(red: 1.0, green: 0.90, blue: 0.56))
        case .fox:
            return .init(rayCenter: pt(0, -0.42), glow: Color(red: 1.0, green: 0.78, blue: 0.50),
                         rays: Color(red: 1.0, green: 0.86, blue: 0.62))
        case .frog:
            return .init(rayCenter: pt(0, -0.36), glow: Color(red: 0.90, green: 1.0, blue: 0.80),
                         rays: Color(red: 0.96, green: 1.0, blue: 0.84))
        case .penguin:
            return .init(rayCenter: pt(0, -0.60), glow: Color(red: 0.80, green: 0.92, blue: 1.0),
                         rays: Color(red: 0.92, green: 0.97, blue: 1.0))
        case .bunny:
            return .init(rayCenter: pt(0, -0.42), glow: Color(red: 1.0, green: 0.88, blue: 0.94),
                         rays: Color(red: 1.0, green: 0.95, blue: 0.86))
        }
    }

    func paintRays(in context: inout GraphicsContext,
                   center: CGPoint,
                   color: Color,
                   count: Int,
                   length: CGFloat,
                   rotation: Double,
                   opacity: Double) {
        var rays = Path()
        for index in 0..<count {
            let angle = Double(index) / Double(count) * 2 * .pi + rotation
            let spread = 0.055 + 0.03 * Double(index % 3)
            rays.move(to: center)
            rays.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle - spread)) * length,
                                     y: center.y + CGFloat(sin(angle - spread)) * length))
            rays.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle + spread)) * length,
                                     y: center.y + CGFloat(sin(angle + spread)) * length))
            rays.closeSubpath()
        }
        context.fill(rays, with: radial([color.opacity(opacity), color.opacity(opacity * 0.4), color.opacity(0)],
                                        center, length))
    }
}

// MARK: - Shared island construction

extension GoalHeavenPainter {
    struct RockMaterial {
        var light: Color
        var mid: Color
        var deep: Color
        var strata: Color
        var glow: Color
    }

    struct LipMaterial {
        var top: Color
        var bottom: Color
        var drips: Bool
        var dripColor: Color
    }

    /// Soft aura that sits directly behind the island and its centrepiece.
    func paintAura(in context: inout GraphicsContext, color: Color, center: CGPoint, radius: CGFloat) {
        context.fill(circle(center, radius), with: radial([color.opacity(0.70), color.opacity(0.28), color.opacity(0)],
                                                          center, radius))
    }

    /// Puffy heaven cloud: a union of rounded lobes with a lit crown and a
    /// tinted belly. The lobes are filled together so no inner seams show.
    func paintPuffCloud(in context: inout GraphicsContext,
                        center: CGPoint,
                        width: CGFloat,
                        height: CGFloat,
                        seed: Int,
                        top: Color = .white,
                        shade: Color = Color(red: 0.80, green: 0.86, blue: 0.98)) {
        var lobes = Path()
        let count = 6
        for index in 0..<count {
            let t = CGFloat(index) / CGFloat(count - 1)
            let lift = CGFloat(sin(Double(t) * .pi))
            let radius = height * (0.34 + 0.30 * lift) * noise(seed + index, 1, 0.82, 1.12)
            let x = center.x + (t - 0.5) * (width - radius * 1.4)
            let y = center.y - lift * height * 0.22 + height * 0.12
            lobes.addPath(circle(CGPoint(x: x, y: y), radius))
        }
        lobes.addPath(Path(roundedRect: CGRect(x: center.x - width * 0.42,
                                               y: center.y,
                                               width: width * 0.84,
                                               height: height * 0.40),
                           cornerRadius: height * 0.2))
        context.fill(lobes, with: vertical([top, top, shade], center.y - height * 0.6, center.y + height * 0.45))
        var crown = context
        crown.clip(to: lobes)
        crown.fill(oval(CGPoint(x: center.x - width * 0.12, y: center.y - height * 0.30), width * 0.30, height * 0.22),
                   with: radial([Color.white.opacity(0.9), Color.white.opacity(0)],
                                CGPoint(x: center.x - width * 0.12, y: center.y - height * 0.30), width * 0.30))
    }

    /// The hanging rock body. Its top edge is hidden by the slab; only the
    /// bottom silhouette, strata and lighting remain visible.
    func undersidePath(seed: Int, depthScale: CGFloat = 1) -> Path {
        var path = Path()
        let steps = 18
        path.move(to: CGPoint(x: -rx, y: 0))
        path.addLine(to: CGPoint(x: -rx * 0.995, y: lip * 0.9))
        for index in 0...steps {
            let t = CGFloat(index) / CGFloat(steps)
            let x = -rx * 0.98 + t * rx * 1.96
            let normalized = abs(x) / rx
            let body = pow(max(0, 1 - normalized * normalized), 0.62)
            let jag: CGFloat = index.isMultiple(of: 2) ? 1 : noise(seed + index, 3, 0.70, 0.86)
            let depth = max(frontY(x) + lip * 1.15, floorDepth * depthScale * body * jag)
            let point = CGPoint(x: x, y: depth)
            if index.isMultiple(of: 2) {
                path.addLine(to: point)
            } else {
                let prevX = -rx * 0.98 + (t - 1 / CGFloat(steps)) * rx * 1.96
                path.addQuadCurve(to: point, control: CGPoint(x: (prevX + x) * 0.5, y: depth * 1.02))
            }
        }
        path.addLine(to: CGPoint(x: rx * 0.995, y: lip * 0.9))
        path.addLine(to: CGPoint(x: rx, y: 0))
        path.closeSubpath()
        return path
    }

    func paintUnderside(in context: inout GraphicsContext,
                        material: RockMaterial,
                        seed: Int = 0,
                        depthScale: CGFloat = 1) {
        let rock = undersidePath(seed: seed, depthScale: depthScale)
        // Underside glow: heaven islands are lit from below by the clouds.
        context.fill(oval(CGPoint(x: 0, y: floorDepth * 0.72), rx * 0.9, floorDepth * 0.5),
                     with: radial([material.glow.opacity(0.55), material.glow.opacity(0)],
                                  CGPoint(x: 0, y: floorDepth * 0.72), rx * 0.9))
        context.fill(rock, with: vertical([material.light, material.mid, material.deep], 0, floorDepth * depthScale))

        var inner = context
        inner.clip(to: rock)
        // Strata follow the curvature of the slab so the body reads as a
        // thick, layered chunk of ground rather than a flat cut-out.
        for band in 1...5 {
            let offset = CGFloat(band) * floorDepth * 0.15
            var stratum = Path()
            let samples = 16
            for index in 0...samples {
                let t = CGFloat(index) / CGFloat(samples)
                let x = -rx + t * rx * 2
                let wave = CGFloat(sin(Double(t) * 9 + Double(band) * 1.7)) * floorDepth * 0.025
                let y = frontY(x) * 0.6 + lip + offset + wave
                if index == 0 { stratum.move(to: CGPoint(x: x, y: y)) } else { stratum.addLine(to: CGPoint(x: x, y: y)) }
            }
            inner.stroke(stratum, with: .color(material.strata.opacity(band.isMultiple(of: 2) ? 0.30 : 0.18)),
                         style: round(floorDepth * (band.isMultiple(of: 2) ? 0.05 : 0.03)))
        }
        // Light from the upper left, shade on the right flank.
        inner.fill(rock, with: linear([Color.white.opacity(0.20), Color.clear, Color.black.opacity(0.26)],
                                      CGPoint(x: -rx, y: 0), CGPoint(x: rx, y: floorDepth)))
        // Small embedded pebbles and cracks.
        for index in 0..<14 {
            let x = noise(seed + index, 5, -0.85, 0.85) * rx
            let maxDepth = floorDepth * pow(max(0, 1 - (x / rx) * (x / rx)), 0.62)
            let y = frontY(x) + lip * 1.3 + noise(seed + index, 6, 0.1, 0.8) * max(0, maxDepth - frontY(x) - lip * 1.3)
            let size = s(noise(seed + index, 7, 0.008, 0.018))
            inner.fill(oval(CGPoint(x: x, y: y), size * 1.3, size * 0.8),
                       with: .color(index.isMultiple(of: 3) ? Color.white.opacity(0.18) : material.deep.opacity(0.55)))
        }
        // Contact shade right under the overhanging lip.
        inner.fill(Path(CGRect(x: -rx, y: 0, width: rx * 2, height: lip * 2.6)),
                   with: vertical([Color.black.opacity(0.32), Color.black.opacity(0)], lip * 0.8, lip * 2.6))
    }

    /// The thick top slab: an edge band (the soil or snow under the lip)
    /// topped by the walkable surface.
    func paintSlab(in context: inout GraphicsContext,
                   surface: [Color],
                   lipMaterial: LipMaterial,
                   rim: Color = Color.white.opacity(0.55)) {
        var band = Path()
        band.addPath(oval(CGPoint(x: 0, y: lip), rx, ry))
        band.addRect(CGRect(x: -rx, y: 0, width: rx * 2, height: lip))
        context.fill(band, with: vertical([lipMaterial.top, lipMaterial.bottom], 0, ry + lip))

        if lipMaterial.drips {
            var drips = Path()
            let count = 26
            for index in 0..<count {
                let t = CGFloat(index) / CGFloat(count - 1)
                let x = -rx * 0.97 + t * rx * 1.94
                let radius = lip * noise(index, 9, 0.30, 0.55)
                let y = frontY(x) + lip * 0.95
                drips.addPath(oval(CGPoint(x: x, y: y), radius * 1.1, radius))
            }
            context.fill(drips, with: .color(lipMaterial.dripColor))
        }

        context.fill(surfacePath, with: linear(surface, CGPoint(x: -rx * 0.6, y: -ry), CGPoint(x: rx * 0.7, y: ry)))
        var gloss = context
        gloss.clip(to: surfacePath)
        gloss.fill(oval(CGPoint(x: -rx * 0.35, y: -ry * 0.35), rx * 0.75, ry * 0.75),
                   with: radial([Color.white.opacity(0.22), Color.white.opacity(0)],
                                CGPoint(x: -rx * 0.35, y: -ry * 0.35), rx * 0.75))
        gloss.stroke(Path(ellipseIn: surfaceRect.insetBy(dx: s(0.004), dy: s(0.003))),
                     with: linear([rim, rim.opacity(0.0), Color.black.opacity(0.10)],
                                  CGPoint(x: 0, y: -ry), CGPoint(x: 0, y: ry)),
                     lineWidth: s(0.006))
    }

    /// A ring of small clouds hugging the island's flanks: the visual cue
    /// that this land floats in the heavens.
    func paintCloudCollar(in context: inout GraphicsContext,
                          tint: Color = Color(red: 0.82, green: 0.88, blue: 1.0),
                          front: Bool) {
        if front {
            paintPuffCloud(in: &context, center: pt(-0.50, 0.12), width: s(0.26), height: s(0.10), seed: 31, shade: tint)
            paintPuffCloud(in: &context, center: pt(0.51, 0.10), width: s(0.24), height: s(0.09), seed: 37, shade: tint)
            paintPuffCloud(in: &context, center: pt(-0.36, floorDepth / u * 0.86), width: s(0.18), height: s(0.065), seed: 41, shade: tint)
            paintPuffCloud(in: &context, center: pt(0.38, floorDepth / u * 0.80), width: s(0.17), height: s(0.06), seed: 43, shade: tint)
        } else {
            paintPuffCloud(in: &context, center: pt(-0.56, -0.06), width: s(0.40), height: s(0.15), seed: 11, shade: tint)
            paintPuffCloud(in: &context, center: pt(0.57, -0.09), width: s(0.38), height: s(0.14), seed: 17, shade: tint)
        }
    }

    /// Water spilling over the lip. Static body here; the moving highlights
    /// live in the particle layer.
    func paintWaterfall(in context: inout GraphicsContext,
                        x: CGFloat,
                        width: CGFloat,
                        top: CGFloat? = nil,
                        bottom: CGFloat,
                        colors: [Color] = [Color(red: 0.86, green: 0.97, blue: 1.0),
                                           Color(red: 0.45, green: 0.80, blue: 0.98)]) {
        let startY = top ?? (frontY(x) + lip * 0.4)
        var fall = Path()
        fall.move(to: CGPoint(x: x - width * 0.5, y: startY))
        fall.addLine(to: CGPoint(x: x + width * 0.5, y: startY))
        fall.addQuadCurve(to: CGPoint(x: x + width * 0.62, y: bottom),
                          control: CGPoint(x: x + width * 0.62, y: (startY + bottom) * 0.5))
        fall.addLine(to: CGPoint(x: x - width * 0.62, y: bottom))
        fall.addQuadCurve(to: CGPoint(x: x - width * 0.5, y: startY),
                          control: CGPoint(x: x - width * 0.62, y: (startY + bottom) * 0.5))
        fall.closeSubpath()
        let first = colors.first ?? .white
        let last = colors.last ?? .blue
        context.fill(fall, with: vertical([first.opacity(0.96), last.opacity(0.85), last.opacity(0)], startY, bottom))
        for lane in 0..<3 {
            let lx = x + (CGFloat(lane) - 1) * width * 0.28
            var streak = Path()
            streak.move(to: CGPoint(x: lx, y: startY + width * 0.1))
            streak.addLine(to: CGPoint(x: lx + (CGFloat(lane) - 1) * width * 0.08, y: bottom - (bottom - startY) * 0.2))
            context.stroke(streak, with: .color(Color.white.opacity(0.45)), style: round(max(0.6, width * 0.09)))
        }
        // Spill crest at the lip.
        context.fill(oval(CGPoint(x: x, y: startY), width * 0.62, width * 0.18),
                     with: .color(Color.white.opacity(0.85)))
    }

    /// Winner's dais under the character's feet. Every theme dresses it
    /// differently but it always reads as the finishing spot.
    func paintPedestal(in context: inout GraphicsContext,
                       top: [Color],
                       side: [Color],
                       trim: Color,
                       glow: Color,
                       radius: CGFloat? = nil) {
        let radiusX = radius ?? s(0.155)
        let radiusY = radiusX * (ry / rx) * 1.05
        let height = s(0.024)
        let center = CGPoint(x: 0, y: feetY + s(0.002))
        context.fill(oval(CGPoint(x: center.x, y: center.y + height * 1.2), radiusX * 1.45, radiusY * 1.7),
                     with: radial([glow.opacity(0.65), glow.opacity(0)],
                                  CGPoint(x: center.x, y: center.y + height), radiusX * 1.45))
        var body = Path()
        body.addPath(oval(CGPoint(x: center.x, y: center.y + height), radiusX, radiusY))
        body.addRect(CGRect(x: -radiusX, y: center.y, width: radiusX * 2, height: height))
        context.fill(body, with: linear(side, CGPoint(x: -radiusX, y: 0), CGPoint(x: radiusX, y: 0)))
        context.stroke(oval(CGPoint(x: center.x, y: center.y + height * 0.55), radiusX * 0.995, radiusY),
                       with: .color(trim.opacity(0.85)), lineWidth: s(0.0045))
        let topOval = oval(center, radiusX, radiusY)
        context.fill(topOval, with: linear(top, CGPoint(x: -radiusX, y: center.y - radiusY), CGPoint(x: radiusX, y: center.y + radiusY)))
        context.stroke(topOval, with: .color(trim), lineWidth: s(0.006))
        context.stroke(oval(center, radiusX * 0.78, radiusY * 0.78), with: .color(trim.opacity(0.55)), lineWidth: s(0.0035))
        context.fill(oval(CGPoint(x: center.x - radiusX * 0.3, y: center.y - radiusY * 0.35), radiusX * 0.35, radiusY * 0.28),
                     with: .color(Color.white.opacity(0.25)))
    }

    /// Four-point sparkle star.
    func sparkle(in context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        var star = Path()
        star.move(to: CGPoint(x: center.x, y: center.y - radius))
        star.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: center)
        star.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: center)
        star.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: center)
        star.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: center)
        star.closeSubpath()
        context.fill(circle(center, radius * 0.9), with: radial([color.opacity(0.45), color.opacity(0)], center, radius * 0.9))
        context.fill(star, with: .color(color))
    }

    func paintHangingRoots(in context: inout GraphicsContext, color: Color, seed: Int, count: Int = 7) {
        for index in 0..<count {
            let x = noise(seed + index, 13, -0.80, 0.80) * rx
            let start = CGPoint(x: x, y: frontY(x) + lip * 1.4)
            let length = s(noise(seed + index, 14, 0.05, 0.12))
            let sway = s(noise(seed + index, 15, -0.025, 0.025))
            var root = Path()
            root.move(to: start)
            root.addCurve(to: CGPoint(x: start.x + sway, y: start.y + length),
                          control1: CGPoint(x: start.x - sway, y: start.y + length * 0.35),
                          control2: CGPoint(x: start.x + sway * 1.6, y: start.y + length * 0.7))
            context.stroke(root, with: .color(color), style: round(s(0.0045)))
            if index.isMultiple(of: 2) {
                brush.leaf(in: &context, center: CGPoint(x: start.x + sway, y: start.y + length),
                           length: s(0.022), angle: .pi / 2 + 0.4, color: Color(red: 0.30, green: 0.66, blue: 0.26), vein: 0)
            }
        }
    }

    /// Small satellite rock floating beside the main island.
    func paintSatellite(in context: inout GraphicsContext,
                        center: CGPoint,
                        width: CGFloat,
                        top: Color,
                        rock: [Color]) {
        let depth = width * 0.62
        var body = Path()
        body.move(to: CGPoint(x: center.x - width * 0.5, y: center.y))
        body.addQuadCurve(to: CGPoint(x: center.x + width * 0.08, y: center.y + depth),
                          control: CGPoint(x: center.x - width * 0.38, y: center.y + depth * 0.7))
        body.addQuadCurve(to: CGPoint(x: center.x + width * 0.5, y: center.y),
                          control: CGPoint(x: center.x + width * 0.42, y: center.y + depth * 0.5))
        body.closeSubpath()
        context.fill(body, with: vertical(rock, center.y, center.y + depth))
        context.fill(oval(center, width * 0.5, width * 0.13), with: .color(top))
        context.fill(oval(CGPoint(x: center.x - width * 0.12, y: center.y - width * 0.03), width * 0.22, width * 0.05),
                     with: .color(Color.white.opacity(0.28)))
    }

    /// Festive bunting along a sagging string.
    func paintBunting(in context: inout GraphicsContext,
                      from start: CGPoint,
                      to end: CGPoint,
                      sag: CGFloat,
                      colors: [Color],
                      flags: Int) {
        var string = Path()
        let control = CGPoint(x: (start.x + end.x) * 0.5, y: (start.y + end.y) * 0.5 + sag)
        string.move(to: start)
        string.addQuadCurve(to: end, control: control)
        context.stroke(string, with: .color(Color.white.opacity(0.9)), lineWidth: s(0.0025))
        for index in 0..<flags {
            let t = (CGFloat(index) + 0.5) / CGFloat(flags)
            let a = 1 - t
            let point = CGPoint(x: a * a * start.x + 2 * a * t * control.x + t * t * end.x,
                                y: a * a * start.y + 2 * a * t * control.y + t * t * end.y)
            let size = s(0.022)
            var flag = Path()
            flag.move(to: CGPoint(x: point.x - size * 0.5, y: point.y))
            flag.addLine(to: CGPoint(x: point.x + size * 0.5, y: point.y))
            flag.addLine(to: CGPoint(x: point.x, y: point.y + size * 1.15))
            flag.closeSubpath()
            context.fill(flag, with: .color(colors[index % colors.count]))
        }
    }
}
