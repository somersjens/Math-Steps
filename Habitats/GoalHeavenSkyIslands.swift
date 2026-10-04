//
//  GoalHeavenSkyIslands.swift
//  Math Steps
//
//  The small floating islands that line the whole course. They borrow the
//  palette and flora of the character's heaven island, so the level already
//  hints at the destination: savanna and acacias for the lion, palms on sand
//  for the crab, snowy pines on ice for the penguin, and so on.
//

import SwiftUI

extension GoalHeavenTheme {
    /// Heaven scenes that paint a sun or moon of their own. The regular sky
    /// must then leave its sun out, or the finish would show two.
    var hasOwnCelestialBody: Bool {
        switch self {
        case .lion, .crab, .fox: return true
        default: return false
        }
    }
}

enum SkyIslandFlora {
    case roundTree, acacia, coral, palm, jungle, pine, maple, willow, snowPine, blossom
}

struct SkyIslandStyle {
    /// Light and dark of the walkable top.
    let surface: [Color]
    /// Light, mid and deep tone of the rock underneath.
    let rock: [Color]
    let flora: SkyIslandFlora
    let foliage: [Color]
    let bark: Color
    /// Small ground accents: flowers, shells, pumpkins, crystals.
    let accents: [Color]
    /// Colours of a falling stream, or nil where none fits.
    let fall: [Color]?

    init(theme: GoalHeavenTheme) {
        let water = [Color(red: 0.92, green: 0.98, blue: 1.0), Color(red: 0.40, green: 0.80, blue: 0.98)]
        switch theme {
        case .dog:
            surface = [Color(red: 0.66, green: 0.94, blue: 0.42), Color(red: 0.36, green: 0.76, blue: 0.30)]
            rock = [Color(red: 0.64, green: 0.47, blue: 0.33), Color(red: 0.47, green: 0.33, blue: 0.23), Color(red: 0.29, green: 0.20, blue: 0.17)]
            flora = .roundTree
            foliage = [Color(red: 0.62, green: 0.90, blue: 0.36), Color(red: 0.24, green: 0.60, blue: 0.24)]
            bark = Color(red: 0.48, green: 0.32, blue: 0.20)
            accents = [Color(red: 0.86, green: 0.95, blue: 0.30), Color(red: 1.0, green: 0.56, blue: 0.66)]
            fall = water
        case .lion:
            surface = [Color(red: 0.99, green: 0.88, blue: 0.52), Color(red: 0.88, green: 0.66, blue: 0.28)]
            rock = [Color(red: 0.88, green: 0.54, blue: 0.30), Color(red: 0.72, green: 0.36, blue: 0.20), Color(red: 0.42, green: 0.18, blue: 0.13)]
            flora = .acacia
            foliage = [Color(red: 0.64, green: 0.74, blue: 0.28), Color(red: 0.34, green: 0.46, blue: 0.16)]
            bark = Color(red: 0.42, green: 0.26, blue: 0.16)
            accents = [Color(red: 0.96, green: 0.78, blue: 0.30), Color(red: 0.84, green: 0.58, blue: 0.18)]
            fall = water
        case .octopus:
            surface = [Color(red: 0.99, green: 0.95, blue: 1.0), Color(red: 0.84, green: 0.76, blue: 0.96)]
            rock = [Color(red: 0.86, green: 0.56, blue: 0.82), Color(red: 0.62, green: 0.36, blue: 0.70), Color(red: 0.34, green: 0.18, blue: 0.48)]
            flora = .coral
            foliage = [Color(red: 1.0, green: 0.46, blue: 0.62), Color(red: 0.30, green: 0.82, blue: 0.82)]
            bark = Color(red: 0.30, green: 0.62, blue: 0.40)
            accents = [Color(red: 1.0, green: 0.62, blue: 0.40), Color(red: 0.98, green: 0.90, blue: 0.70)]
            fall = [Color(red: 0.96, green: 0.92, blue: 1.0), Color(red: 0.62, green: 0.70, blue: 1.0)]
        case .crab:
            surface = [Color(red: 1.0, green: 0.95, blue: 0.80), Color(red: 0.96, green: 0.82, blue: 0.58)]
            rock = [Color(red: 0.98, green: 0.80, blue: 0.56), Color(red: 0.86, green: 0.60, blue: 0.38), Color(red: 0.56, green: 0.34, blue: 0.24)]
            flora = .palm
            foliage = [Color(red: 0.46, green: 0.84, blue: 0.40), Color(red: 0.18, green: 0.60, blue: 0.30)]
            bark = Color(red: 0.66, green: 0.48, blue: 0.28)
            accents = [Color(red: 1.0, green: 0.62, blue: 0.62), Color(red: 1.0, green: 0.88, blue: 0.80)]
            fall = [Color(red: 0.86, green: 1.0, blue: 0.98), Color(red: 0.28, green: 0.82, blue: 0.86)]
        case .elephant:
            surface = [Color(red: 0.62, green: 0.92, blue: 0.44), Color(red: 0.32, green: 0.72, blue: 0.32)]
            rock = [Color(red: 0.70, green: 0.56, blue: 0.48), Color(red: 0.52, green: 0.40, blue: 0.36), Color(red: 0.32, green: 0.24, blue: 0.26)]
            flora = .jungle
            foliage = [Color(red: 0.38, green: 0.78, blue: 0.36), Color(red: 0.14, green: 0.52, blue: 0.28)]
            bark = Color(red: 0.52, green: 0.38, blue: 0.26)
            accents = [Color(red: 1.0, green: 0.38, blue: 0.54), Color(red: 1.0, green: 0.70, blue: 0.20)]
            fall = water
        case .bear:
            surface = [Color(red: 0.62, green: 0.86, blue: 0.40), Color(red: 0.38, green: 0.66, blue: 0.28)]
            rock = [Color(red: 0.62, green: 0.44, blue: 0.30), Color(red: 0.46, green: 0.31, blue: 0.21), Color(red: 0.27, green: 0.18, blue: 0.14)]
            flora = .pine
            foliage = [Color(red: 0.26, green: 0.60, blue: 0.32), Color(red: 0.12, green: 0.40, blue: 0.24)]
            bark = Color(red: 0.36, green: 0.22, blue: 0.14)
            accents = [Color(red: 1.0, green: 0.80, blue: 0.20), Color(red: 0.90, green: 0.30, blue: 0.24)]
            fall = [Color(red: 1.0, green: 0.88, blue: 0.44), Color(red: 0.94, green: 0.60, blue: 0.12)]
        case .fox:
            surface = [Color(red: 0.80, green: 0.88, blue: 0.44), Color(red: 0.54, green: 0.70, blue: 0.30)]
            rock = [Color(red: 0.56, green: 0.42, blue: 0.34), Color(red: 0.40, green: 0.28, blue: 0.24), Color(red: 0.24, green: 0.16, blue: 0.16)]
            flora = .maple
            foliage = [Color(red: 1.0, green: 0.74, blue: 0.24), Color(red: 0.90, green: 0.30, blue: 0.14)]
            bark = Color(red: 0.40, green: 0.26, blue: 0.18)
            accents = [Color(red: 1.0, green: 0.56, blue: 0.16), Color(red: 0.92, green: 0.24, blue: 0.16)]
            fall = water
        case .frog:
            surface = [Color(red: 0.66, green: 0.92, blue: 0.44), Color(red: 0.38, green: 0.72, blue: 0.30)]
            rock = [Color(red: 0.52, green: 0.58, blue: 0.48), Color(red: 0.36, green: 0.42, blue: 0.36), Color(red: 0.20, green: 0.26, blue: 0.24)]
            flora = .willow
            foliage = [Color(red: 0.60, green: 0.86, blue: 0.38), Color(red: 0.28, green: 0.58, blue: 0.24)]
            bark = Color(red: 0.40, green: 0.30, blue: 0.20)
            accents = [Color(red: 1.0, green: 0.62, blue: 0.80), Color(red: 0.54, green: 0.40, blue: 0.24)]
            fall = [Color(red: 0.80, green: 1.0, blue: 0.94), Color(red: 0.24, green: 0.68, blue: 0.70)]
        case .penguin:
            surface = [Color.white, Color(red: 0.84, green: 0.91, blue: 1.0)]
            rock = [Color(red: 0.78, green: 0.90, blue: 1.0), Color(red: 0.48, green: 0.64, blue: 0.86), Color(red: 0.22, green: 0.32, blue: 0.58)]
            flora = .snowPine
            foliage = [Color(red: 0.38, green: 0.62, blue: 0.64), Color(red: 0.18, green: 0.40, blue: 0.46)]
            bark = Color(red: 0.36, green: 0.26, blue: 0.22)
            accents = [Color(red: 0.74, green: 0.92, blue: 1.0), Color(red: 0.52, green: 0.78, blue: 1.0)]
            fall = nil
        case .bunny:
            surface = [Color(red: 0.74, green: 0.96, blue: 0.56), Color(red: 0.48, green: 0.82, blue: 0.40)]
            rock = [Color(red: 0.70, green: 0.50, blue: 0.40), Color(red: 0.54, green: 0.36, blue: 0.30), Color(red: 0.36, green: 0.22, blue: 0.20)]
            flora = .blossom
            foliage = [Color(red: 1.0, green: 0.88, blue: 0.93), Color(red: 0.97, green: 0.60, blue: 0.76)]
            bark = Color(red: 0.50, green: 0.34, blue: 0.26)
            accents = [Color(red: 1.0, green: 0.56, blue: 0.20), Color(red: 0.98, green: 0.46, blue: 0.62)]
            fall = water
        }
    }
}

// MARK: - Midground island

struct ThemedSkyIsland: View {
    let theme: GoalHeavenTheme
    let seed: Int
    let showsWaterfall: Bool

    var body: some View {
        GeometryReader { proxy in
            // Trees rise well above the island's frame and palms lean past
            // its sides; a Canvas clips to its bounds, so give it room.
            let headroom = proxy.size.height * 0.8
            let margin = proxy.size.width * 0.2
            Canvas { context, _ in
                context.translateBy(x: margin, y: headroom)
                SkyIslandPainter(style: SkyIslandStyle(theme: theme), seed: seed, size: proxy.size)
                    .paint(in: &context, showsWaterfall: showsWaterfall)
            }
            .frame(width: proxy.size.width + margin * 2, height: proxy.size.height + headroom)
            .offset(x: -margin, y: -headroom)
        }
    }
}

/// The pale, far-away silhouettes. Tinted with the same palette so even the
/// haze belongs to the character's world.
struct ThemedDistantSkyIsland: View {
    let theme: GoalHeavenTheme
    let seed: Int

    var body: some View {
        Canvas { context, size in
            let style = SkyIslandStyle(theme: theme)
            let painter = SkyIslandPainter(style: style, seed: seed, size: size)
            context.fill(painter.rockPath(), with: .color(style.rock[2].opacity(0.40)))
            let top = CGRect(x: size.width * 0.05, y: size.height * 0.08, width: size.width * 0.90, height: size.height * 0.31)
            context.fill(Path(ellipseIn: top), with: .color(style.surface[0].opacity(0.62)))
            context.fill(Path(ellipseIn: CGRect(x: size.width * (seed.isMultiple(of: 2) ? 0.15 : 0.51), y: size.height * 0.10,
                                                width: size.width * 0.34, height: size.height * 0.08)),
                         with: .color(.white.opacity(0.24)))
        }
        .blur(radius: 1.2)
    }
}

private struct SkyIslandPainter {
    let style: SkyIslandStyle
    let seed: Int
    let size: CGSize

    var w: CGFloat { size.width }
    var h: CGFloat { size.height }

    func rockPath() -> Path {
        let tipShift = CGFloat((seed * 11) % 17 - 8) / 100
        var path = Path()
        path.move(to: CGPoint(x: w * 0.08, y: h * 0.23))
        path.addCurve(to: CGPoint(x: w * 0.92, y: h * 0.23),
                      control1: CGPoint(x: w * 0.30, y: h * 0.08),
                      control2: CGPoint(x: w * 0.70, y: h * 0.08))
        path.addLine(to: CGPoint(x: w * (0.69 + tipShift), y: h * 0.72))
        path.addLine(to: CGPoint(x: w * (0.51 + tipShift), y: h * 0.96))
        path.addLine(to: CGPoint(x: w * (0.34 + tipShift * 0.4), y: h * 0.68))
        path.addCurve(to: CGPoint(x: w * 0.08, y: h * 0.23),
                      control1: CGPoint(x: w * 0.20, y: h * 0.57),
                      control2: CGPoint(x: w * 0.13, y: h * 0.38))
        path.closeSubpath()
        return path
    }

    private func linear(_ colors: [Color], _ start: CGPoint, _ end: CGPoint) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: colors), startPoint: start, endPoint: end)
    }

    private func oval(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
    }

    private func round(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: max(0.5, width), lineCap: .round, lineJoin: .round)
    }

    func paint(in context: inout GraphicsContext, showsWaterfall: Bool) {
        let rock = rockPath()
        context.fill(rock, with: linear(style.rock, CGPoint(x: w * 0.4, y: h * 0.2), CGPoint(x: w * 0.55, y: h * 0.95)))
        var strata = context
        strata.clip(to: rock)
        for (index, y) in [CGFloat(0.42), 0.58].enumerated() {
            var line = Path()
            line.move(to: CGPoint(x: 0, y: h * y))
            line.addQuadCurve(to: CGPoint(x: w, y: h * (y - 0.03)),
                              control: CGPoint(x: w * 0.5, y: h * (y + (index == 0 ? 0.05 : -0.04))))
            strata.stroke(line, with: .color(style.rock[2].opacity(0.30)), lineWidth: max(0.6, w * 0.012))
        }
        strata.fill(Path(CGRect(x: 0, y: 0, width: w * 0.30, height: h)),
                    with: linear([Color.white.opacity(0.16), Color.white.opacity(0)], .zero, CGPoint(x: w * 0.30, y: 0)))
        strata.fill(Path(CGRect(x: w * 0.6, y: 0, width: w * 0.4, height: h)),
                    with: linear([Color.black.opacity(0), Color.black.opacity(0.14)], CGPoint(x: w * 0.6, y: 0), CGPoint(x: w, y: 0)))

        if showsWaterfall, let fall = style.fall {
            let direction: CGFloat = seed.isMultiple(of: 2) ? -1 : 1
            let x = w * 0.5 + direction * w * 0.16
            let stream = Path(roundedRect: CGRect(x: x - w * 0.05, y: h * 0.26, width: w * 0.10, height: h * 0.56),
                              cornerRadius: w * 0.05)
            context.fill(stream, with: linear([fall[0].opacity(0.95), fall[1].opacity(0.55), fall[1].opacity(0)],
                                              CGPoint(x: x, y: h * 0.26), CGPoint(x: x, y: h * 0.82)))
        }

        // Lip band, then the walkable top with a soft gloss.
        let topCenter = CGPoint(x: w * 0.5, y: h * 0.215)
        context.fill(oval(CGPoint(x: topCenter.x, y: topCenter.y + h * 0.035), w * 0.46, h * 0.14),
                     with: .color(style.rock[0]))
        let top = oval(topCenter, w * 0.46, h * 0.135)
        context.fill(top, with: linear(style.surface, CGPoint(x: w * 0.4, y: topCenter.y - h * 0.13), CGPoint(x: w * 0.6, y: topCenter.y + h * 0.13)))
        context.fill(oval(CGPoint(x: w * 0.38, y: topCenter.y - h * 0.05), w * 0.20, h * 0.035),
                     with: .color(Color.white.opacity(0.22)))

        // Ground accents behind the flora.
        if seed % 3 != 1 {
            let cx = w * (seed.isMultiple(of: 2) ? 0.72 : 0.27)
            for index in 0..<4 {
                let p = CGPoint(x: cx + w * (CGFloat(index) - 1.5) * 0.035, y: h * (0.25 + CGFloat(index % 2) * 0.02))
                context.fill(oval(p, w * 0.016, w * 0.012), with: .color(style.accents[index % style.accents.count]))
            }
        }

        for (index, plant) in plantings().enumerated() {
            let base = CGPoint(x: w * plant.x, y: h * plant.y)
            paintFlora(&context, base: base, height: h * 0.46 * plant.scale, width: w * 0.33 * plant.scale, variant: seed + index)
        }
    }

    private struct Planting { let x: CGFloat; let y: CGFloat; let scale: CGFloat }

    /// Six hand-composed planting patterns; bases sit on the top surface.
    private func plantings() -> [Planting] {
        switch seed % 6 {
        case 0: return [.init(x: 0.28, y: 0.25, scale: 1.0), .init(x: 0.63, y: 0.27, scale: 0.72)]
        case 1: return [.init(x: 0.22, y: 0.26, scale: 0.66), .init(x: 0.48, y: 0.24, scale: 1.04), .init(x: 0.75, y: 0.26, scale: 0.62)]
        case 2: return [.init(x: 0.60, y: 0.25, scale: 1.10)]
        case 3: return [.init(x: 0.34, y: 0.26, scale: 0.82), .init(x: 0.70, y: 0.24, scale: 1.02)]
        case 4: return [.init(x: 0.25, y: 0.27, scale: 0.64), .init(x: 0.46, y: 0.24, scale: 0.96), .init(x: 0.69, y: 0.27, scale: 0.74)]
        default: return [.init(x: 0.30, y: 0.24, scale: 1.06), .init(x: 0.59, y: 0.27, scale: 0.68)]
        }
    }

    // MARK: Flora

    private func paintFlora(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, variant: Int) {
        context.fill(oval(CGPoint(x: base.x, y: base.y + height * 0.02), width * 0.38, height * 0.06),
                     with: .color(Color.black.opacity(0.14)))
        switch style.flora {
        case .roundTree: paintRoundTree(&context, base: base, height: height, width: width, dots: nil)
        case .maple: paintRoundTree(&context, base: base, height: height, width: width, dots: Color(red: 1.0, green: 0.86, blue: 0.40))
        case .blossom: paintRoundTree(&context, base: base, height: height, width: width, dots: .white)
        case .acacia: paintAcacia(&context, base: base, height: height, width: width * 1.25)
        case .coral: paintCoral(&context, base: base, height: height, width: width, variant: variant)
        case .palm: paintPalm(&context, base: base, height: height * 1.1, width: width, lean: variant.isMultiple(of: 2) ? 1 : -1)
        case .jungle: paintJungle(&context, base: base, height: height, width: width, variant: variant)
        case .pine: paintPine(&context, base: base, height: height * 1.15, width: width, snow: false)
        case .snowPine: paintPine(&context, base: base, height: height * 1.1, width: width, snow: true)
        case .willow: paintWillow(&context, base: base, height: height, width: width * 1.1)
        }
    }

    private func paintTrunk(_ context: inout GraphicsContext, base: CGPoint, top: CGPoint, width: CGFloat) {
        var trunk = Path()
        trunk.move(to: CGPoint(x: base.x - width * 0.5, y: base.y))
        trunk.addLine(to: CGPoint(x: top.x - width * 0.3, y: top.y))
        trunk.addLine(to: CGPoint(x: top.x + width * 0.3, y: top.y))
        trunk.addLine(to: CGPoint(x: base.x + width * 0.5, y: base.y))
        trunk.closeSubpath()
        context.fill(trunk, with: linear([style.bark.opacity(0.85), style.bark], CGPoint(x: base.x - width, y: base.y), CGPoint(x: base.x + width, y: base.y)))
    }

    private func paintRoundTree(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, dots: Color?) {
        let crownCenter = CGPoint(x: base.x, y: base.y - height * 0.64)
        paintTrunk(&context, base: base, top: crownCenter, width: width * 0.14)
        var crown = Path()
        crown.addEllipse(in: CGRect(x: crownCenter.x - width * 0.42, y: crownCenter.y - height * 0.22, width: width * 0.84, height: height * 0.46))
        crown.addEllipse(in: CGRect(x: crownCenter.x - width * 0.30, y: crownCenter.y - height * 0.36, width: width * 0.56, height: height * 0.40))
        crown.addEllipse(in: CGRect(x: crownCenter.x - width * 0.04, y: crownCenter.y - height * 0.30, width: width * 0.44, height: height * 0.36))
        context.fill(crown, with: linear(style.foliage, CGPoint(x: crownCenter.x - width * 0.3, y: crownCenter.y - height * 0.35),
                                         CGPoint(x: crownCenter.x + width * 0.3, y: crownCenter.y + height * 0.24)))
        var inner = context
        inner.clip(to: crown)
        inner.fill(oval(CGPoint(x: crownCenter.x - width * 0.14, y: crownCenter.y - height * 0.18), width * 0.18, height * 0.08),
                   with: .color(Color.white.opacity(0.22)))
        if let dots {
            for index in 0..<6 {
                let angle = Double(index) * 1.1 + Double(seed)
                let p = CGPoint(x: crownCenter.x + CGFloat(cos(angle)) * width * 0.26,
                                y: crownCenter.y - height * 0.06 + CGFloat(sin(angle)) * height * 0.14)
                inner.fill(oval(p, width * 0.035, width * 0.035), with: .color(dots.opacity(0.9)))
            }
        }
    }

    private func paintAcacia(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat) {
        let top = CGPoint(x: base.x + width * 0.04, y: base.y - height * 0.70)
        let fork = CGPoint(x: base.x + width * 0.01, y: base.y - height * 0.38)
        var limbs = Path()
        limbs.move(to: base)
        limbs.addQuadCurve(to: top, control: CGPoint(x: base.x - width * 0.02, y: base.y - height * 0.5))
        limbs.move(to: fork)
        limbs.addQuadCurve(to: CGPoint(x: base.x - width * 0.26, y: top.y + height * 0.04),
                           control: CGPoint(x: base.x - width * 0.18, y: fork.y - height * 0.06))
        limbs.move(to: fork)
        limbs.addQuadCurve(to: CGPoint(x: base.x + width * 0.28, y: top.y + height * 0.05),
                           control: CGPoint(x: base.x + width * 0.20, y: fork.y - height * 0.04))
        context.stroke(limbs, with: .color(style.bark), style: round(width * 0.055))
        let canopy = CGPoint(x: base.x + width * 0.01, y: top.y - height * 0.02)
        context.fill(oval(canopy, width * 0.50, height * 0.10), with: .color(style.foliage[1]))
        context.fill(oval(CGPoint(x: canopy.x - width * 0.04, y: canopy.y - height * 0.05), width * 0.40, height * 0.08),
                     with: linear(style.foliage, CGPoint(x: canopy.x, y: canopy.y - height * 0.13), CGPoint(x: canopy.x, y: canopy.y)))
    }

    private func paintCoral(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, variant: Int) {
        let color = style.foliage[variant % 2]
        var coral = Path()
        let fans: [Double] = [-0.55, -0.22, 0.05, 0.30, 0.58]
        for (index, angle) in fans.enumerated() {
            let length = height * (0.62 + 0.18 * CGFloat(index % 2))
            let tip = CGPoint(x: base.x + CGFloat(sin(angle)) * length, y: base.y - CGFloat(cos(angle)) * length)
            let mid = CGPoint(x: (base.x + tip.x) * 0.5, y: (base.y + tip.y) * 0.5)
            coral.move(to: base)
            coral.addQuadCurve(to: tip, control: CGPoint(x: mid.x - CGFloat(sin(angle)) * width * 0.08, y: mid.y))
            let side: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            coral.move(to: mid)
            coral.addLine(to: CGPoint(x: mid.x + side * width * 0.14, y: mid.y - height * 0.16))
        }
        context.stroke(coral, with: .color(color), style: round(width * 0.075))
        context.stroke(coral.offsetBy(dx: -width * 0.015, dy: -width * 0.01), with: .color(Color.white.opacity(0.25)), style: round(width * 0.025))
        // Swaying seaweed beside it.
        var weed = Path()
        weed.move(to: CGPoint(x: base.x + width * 0.36, y: base.y))
        weed.addCurve(to: CGPoint(x: base.x + width * 0.40, y: base.y - height * 0.55),
                      control1: CGPoint(x: base.x + width * 0.24, y: base.y - height * 0.2),
                      control2: CGPoint(x: base.x + width * 0.52, y: base.y - height * 0.35))
        context.stroke(weed, with: .color(style.bark), style: round(width * 0.05))
    }

    private func paintPalm(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, lean: CGFloat) {
        let top = CGPoint(x: base.x + lean * width * 0.22, y: base.y - height * 0.78)
        let control = CGPoint(x: base.x - lean * width * 0.04, y: base.y - height * 0.45)
        var trunk = Path()
        trunk.move(to: base)
        trunk.addQuadCurve(to: top, control: control)
        context.stroke(trunk, with: .color(style.bark), style: round(width * 0.10))
        context.stroke(trunk, with: .color(Color.white.opacity(0.18)), style: round(width * 0.035))
        let angles: [Double] = [-2.9, -2.45, -2.0, -1.55, -1.1, -0.65, -0.2, 0.25]
        for (index, angle) in angles.enumerated() {
            let length = width * (0.52 + 0.08 * CGFloat(index % 2))
            // Fronds arch up from the crown and droop towards their tips.
            let tip = CGPoint(x: top.x + CGFloat(cos(angle)) * length,
                              y: top.y + CGFloat(sin(angle)) * length * 0.45 + length * 0.32)
            let arch = CGPoint(x: (top.x + tip.x) * 0.5, y: min(top.y, tip.y) - length * 0.18)
            var frond = Path()
            frond.move(to: top)
            frond.addQuadCurve(to: tip, control: CGPoint(x: arch.x, y: arch.y - length * 0.10))
            frond.addQuadCurve(to: top, control: CGPoint(x: arch.x, y: arch.y + length * 0.16))
            frond.closeSubpath()
            context.fill(frond, with: .color(style.foliage[index % 2]))
            var rib = Path()
            rib.move(to: top)
            rib.addQuadCurve(to: tip, control: CGPoint(x: arch.x, y: arch.y + length * 0.02))
            context.stroke(rib, with: .color(Color.white.opacity(0.22)), style: round(width * 0.012))
        }
        context.fill(oval(CGPoint(x: top.x, y: top.y + width * 0.03), width * 0.06, width * 0.05), with: .color(style.bark.opacity(0.9)))
    }

    private func paintJungle(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, variant: Int) {
        if variant.isMultiple(of: 2) {
            paintPalm(&context, base: base, height: height * 1.15, width: width * 1.05, lean: -0.4)
        } else {
            paintRoundTree(&context, base: base, height: height, width: width, dots: nil)
        }
        // Broad banana leaves at the foot.
        for side in [-1.0, 1.0] {
            let tip = CGPoint(x: base.x + CGFloat(side) * width * 0.42, y: base.y - height * 0.22)
            var leaf = Path()
            leaf.move(to: base)
            leaf.addQuadCurve(to: tip, control: CGPoint(x: base.x + CGFloat(side) * width * 0.08, y: base.y - height * 0.34))
            leaf.addQuadCurve(to: base, control: CGPoint(x: base.x + CGFloat(side) * width * 0.38, y: base.y - height * 0.02))
            context.fill(leaf, with: .color(style.foliage[side < 0 ? 0 : 1]))
        }
    }

    private func paintPine(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, snow: Bool) {
        context.fill(Path(CGRect(x: base.x - width * 0.06, y: base.y - height * 0.2, width: width * 0.12, height: height * 0.2)),
                     with: .color(style.bark))
        for tier in 0..<3 {
            let t = CGFloat(tier) / 2
            let bottom = base.y - height * (0.14 + t * 0.30)
            let tierWidth = width * (0.92 - t * 0.38)
            let apex = CGPoint(x: base.x, y: bottom - height * (0.40 - t * 0.06))
            var skirt = Path()
            skirt.move(to: apex)
            skirt.addQuadCurve(to: CGPoint(x: base.x + tierWidth * 0.5, y: bottom),
                               control: CGPoint(x: base.x + tierWidth * 0.16, y: bottom - height * 0.12))
            skirt.addQuadCurve(to: CGPoint(x: base.x - tierWidth * 0.5, y: bottom),
                               control: CGPoint(x: base.x, y: bottom + height * 0.06))
            skirt.addQuadCurve(to: apex, control: CGPoint(x: base.x - tierWidth * 0.16, y: bottom - height * 0.12))
            skirt.closeSubpath()
            context.fill(skirt, with: linear(style.foliage, CGPoint(x: base.x - tierWidth * 0.5, y: apex.y), CGPoint(x: base.x + tierWidth * 0.5, y: bottom)))
            if snow {
                var cap = context
                cap.clip(to: skirt)
                var drift = Path()
                drift.move(to: CGPoint(x: base.x - tierWidth, y: apex.y))
                drift.addLine(to: CGPoint(x: base.x + tierWidth, y: apex.y))
                drift.addLine(to: CGPoint(x: base.x + tierWidth, y: apex.y + (bottom - apex.y) * 0.42))
                drift.addQuadCurve(to: CGPoint(x: base.x - tierWidth, y: apex.y + (bottom - apex.y) * 0.50),
                                   control: CGPoint(x: base.x, y: apex.y + (bottom - apex.y) * 0.62))
                drift.closeSubpath()
                cap.fill(drift, with: .color(Color.white.opacity(0.95)))
            }
        }
    }

    private func paintWillow(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat) {
        let crownCenter = CGPoint(x: base.x, y: base.y - height * 0.66)
        paintTrunk(&context, base: base, top: crownCenter, width: width * 0.12)
        context.fill(oval(crownCenter, width * 0.44, height * 0.20),
                     with: linear(style.foliage, CGPoint(x: crownCenter.x, y: crownCenter.y - height * 0.2), CGPoint(x: crownCenter.x, y: crownCenter.y + height * 0.2)))
        var strands = Path()
        for index in 0..<9 {
            let x = crownCenter.x + width * (CGFloat(index) / 8 - 0.5) * 0.82
            let start = CGPoint(x: x, y: crownCenter.y + height * 0.04)
            strands.move(to: start)
            strands.addQuadCurve(to: CGPoint(x: x + width * 0.02, y: start.y + height * (0.30 + 0.06 * CGFloat(index % 3))),
                                 control: CGPoint(x: x - width * 0.03, y: start.y + height * 0.15))
        }
        context.stroke(strands, with: .color(style.foliage[0]), style: round(width * 0.035))
        // Reeds at the foot.
        var reeds = Path()
        for index in 0..<3 {
            let x = base.x + width * (0.34 + CGFloat(index) * 0.06)
            reeds.move(to: CGPoint(x: x, y: base.y))
            reeds.addLine(to: CGPoint(x: x + width * 0.02, y: base.y - height * (0.30 + 0.06 * CGFloat(index))))
        }
        context.stroke(reeds, with: .color(style.foliage[1]), style: round(width * 0.025))
    }
}
