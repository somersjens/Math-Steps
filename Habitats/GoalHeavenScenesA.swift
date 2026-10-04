//
//  GoalHeavenScenesA.swift
//  Math Steps
//
//  Finish-island paradises for the dog, lion, octopus, crab and elephant.
//  See GoalHeavenIsland.swift for the shared coordinate space.
//

import SwiftUI

struct GoalHeavenWaterfall {
    let x: CGFloat
    let width: CGFloat
    let top: CGFloat?
    let bottom: CGFloat
    let colors: [Color]
}

extension GoalHeavenPainter {
    private var water: [Color] {
        [Color(red: 0.88, green: 0.98, blue: 1.0), Color(red: 0.42, green: 0.80, blue: 0.98)]
    }

    private var honey: [Color] {
        [Color(red: 1.0, green: 0.90, blue: 0.45), Color(red: 0.95, green: 0.62, blue: 0.10)]
    }

    /// Shared between the static artwork and the shimmer in the particle layer.
    func waterfalls(for theme: GoalHeavenTheme) -> [GoalHeavenWaterfall] {
        switch theme {
        case .dog:
            return [.init(x: s(-0.40), width: s(0.045), top: nil, bottom: floorDepth * 1.05, colors: water)]
        case .lion:
            return [.init(x: s(0.30), width: s(0.05), top: nil, bottom: floorDepth * 1.1, colors: water)]
        case .octopus:
            return [.init(x: s(0.36), width: s(0.05), top: nil, bottom: floorDepth * 1.05, colors: water),
                    .init(x: s(-0.42), width: s(0.035), top: nil, bottom: floorDepth * 0.95, colors: water)]
        case .crab:
            return [.init(x: s(-0.43), width: s(0.05), top: nil, bottom: floorDepth * 1.0, colors: water),
                    .init(x: s(0.44), width: s(0.045), top: nil, bottom: floorDepth * 0.95, colors: water)]
        case .elephant:
            return [.init(x: 0, width: s(0.11), top: s(-0.555), bottom: s(-0.075), colors: water),
                    .init(x: s(-0.41), width: s(0.04), top: nil, bottom: floorDepth * 1.0, colors: water),
                    .init(x: s(0.40), width: s(0.04), top: nil, bottom: floorDepth * 1.0, colors: water)]
        case .bear:
            return [.init(x: s(0.36), width: s(0.06), top: nil, bottom: floorDepth * 1.1, colors: honey)]
        case .fox:
            return [.init(x: s(-0.38), width: s(0.04), top: nil, bottom: floorDepth * 1.0, colors: water)]
        case .frog:
            return [.init(x: s(-0.30), width: s(0.06), top: nil, bottom: floorDepth * 1.1, colors: water),
                    .init(x: s(0.41), width: s(0.035), top: nil, bottom: floorDepth * 0.95, colors: water)]
        case .penguin:
            return []
        case .bunny:
            return [.init(x: s(0.40), width: s(0.04), top: nil, bottom: floorDepth * 1.0, colors: water)]
        }
    }

    func paintWaterfalls(in context: inout GraphicsContext, theme: GoalHeavenTheme, onlyLip: Bool = true) {
        for fall in waterfalls(for: theme) where (fall.top == nil) == onlyLip {
            paintWaterfall(in: &context, x: fall.x, width: fall.width, top: fall.top,
                           bottom: fall.bottom, colors: fall.colors)
        }
    }

    func tuft(_ context: inout GraphicsContext, _ base: CGPoint, _ height: CGFloat,
              _ colors: [Color], seed: Int, width: CGFloat? = nil) {
        brush.grassTuft(in: &context, base: base, height: height, width: width ?? height * 1.3,
                        colors: colors, bladeCount: 9, seed: seed, shadow: 0.10)
    }

    func groundShadow(_ context: inout GraphicsContext, _ center: CGPoint, _ width: CGFloat, opacity: Double = 0.22) {
        brush.contactShadow(in: &context, center: center, width: width, height: width * 0.28, opacity: opacity)
    }

    func paintSurfaceStripes(in context: inout GraphicsContext, color: Color, count: Int) {
        var clipped = context
        clipped.clip(to: surfacePath)
        let band = rx * 2 / CGFloat(count)
        let slant = ry * 0.9
        for index in stride(from: 0, to: count, by: 2) {
            let x0 = -rx + CGFloat(index) * band
            var stripe = Path()
            stripe.move(to: CGPoint(x: x0 - slant, y: -ry))
            stripe.addLine(to: CGPoint(x: x0 + band - slant, y: -ry))
            stripe.addLine(to: CGPoint(x: x0 + band + slant, y: ry))
            stripe.addLine(to: CGPoint(x: x0 + slant, y: ry))
            stripe.closeSubpath()
            clipped.fill(stripe, with: .color(color))
        }
    }

    /// Classic dog paw: a three-lobed heel pad under four splayed oval toes.
    func pawPrint(_ context: inout GraphicsContext, _ center: CGPoint, _ size: CGFloat, _ color: Color) {
        func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: center.x + x * size, y: center.y + y * size) }
        var pad = Path()
        pad.move(to: at(0, 0.0))
        pad.addCurve(to: at(-0.36, 0.30), control1: at(-0.20, 0.0), control2: at(-0.36, 0.14))
        pad.addCurve(to: at(-0.14, 0.50), control1: at(-0.36, 0.46), control2: at(-0.25, 0.52))
        pad.addQuadCurve(to: at(0.14, 0.50), control: at(0, 0.45))
        pad.addCurve(to: at(0.36, 0.30), control1: at(0.25, 0.52), control2: at(0.36, 0.46))
        pad.addCurve(to: at(0, 0.0), control1: at(0.36, 0.14), control2: at(0.20, 0.0))
        pad.closeSubpath()
        context.fill(pad, with: .color(color))
        for (x, y, tilt) in [(-0.40, -0.14, -30.0), (-0.14, -0.34, -8.0), (0.14, -0.34, 8.0), (0.40, -0.14, 30.0)] as [(CGFloat, CGFloat, Double)] {
            let toe = at(x, y)
            let shape = Path(ellipseIn: CGRect(x: -size * 0.13, y: -size * 0.17, width: size * 0.26, height: size * 0.34))
                .applying(CGAffineTransform(rotationAngle: CGFloat(tilt) * .pi / 180).concatenating(CGAffineTransform(translationX: toe.x, y: toe.y)))
            context.fill(shape, with: .color(color))
        }
    }

    func heartPath(_ center: CGPoint, _ size: CGFloat) -> Path {
        var heart = Path()
        heart.move(to: CGPoint(x: center.x, y: center.y + size * 0.45))
        heart.addCurve(to: CGPoint(x: center.x - size * 0.5, y: center.y - size * 0.1),
                       control1: CGPoint(x: center.x - size * 0.2, y: center.y + size * 0.25),
                       control2: CGPoint(x: center.x - size * 0.5, y: center.y + size * 0.1))
        heart.addArc(center: CGPoint(x: center.x - size * 0.25, y: center.y - size * 0.15),
                     radius: size * 0.255, startAngle: .degrees(170), endAngle: .degrees(-10), clockwise: false)
        heart.addArc(center: CGPoint(x: center.x + size * 0.25, y: center.y - size * 0.15),
                     radius: size * 0.255, startAngle: .degrees(190), endAngle: .degrees(10), clockwise: false)
        heart.addCurve(to: CGPoint(x: center.x, y: center.y + size * 0.45),
                       control1: CGPoint(x: center.x + size * 0.5, y: center.y + size * 0.1),
                       control2: CGPoint(x: center.x + size * 0.2, y: center.y + size * 0.25))
        heart.closeSubpath()
        return heart
    }

    /// The balloon leans along its string; `bend` bows the string sideways.
    func balloon(_ context: inout GraphicsContext, anchor: CGPoint, center: CGPoint, radius r: CGFloat,
                 color: Color, bend: CGFloat = 0) {
        let tilt = atan2(center.x - anchor.x, anchor.y - center.y)
        let tie = CGPoint(x: center.x - CGFloat(sin(tilt)) * r * 1.26, y: center.y + CGFloat(cos(tilt)) * r * 1.26)
        var string = Path()
        string.move(to: anchor)
        string.addQuadCurve(to: tie, control: CGPoint(x: (anchor.x + tie.x) * 0.5 + bend, y: (anchor.y + tie.y) * 0.5))
        context.stroke(string, with: .color(Color.white.opacity(0.9)), lineWidth: s(0.0024))

        var b = context
        b.translateBy(x: center.x, y: center.y)
        b.rotate(by: .radians(tilt))
        var body = Path()
        body.move(to: CGPoint(x: 0, y: -r * 1.16))
        body.addCurve(to: CGPoint(x: r, y: -r * 0.12), control1: CGPoint(x: r * 0.58, y: -r * 1.16), control2: CGPoint(x: r, y: -r * 0.72))
        body.addCurve(to: CGPoint(x: 0, y: r * 1.14), control1: CGPoint(x: r, y: r * 0.46), control2: CGPoint(x: r * 0.36, y: r * 0.96))
        body.addCurve(to: CGPoint(x: -r, y: -r * 0.12), control1: CGPoint(x: -r * 0.36, y: r * 0.96), control2: CGPoint(x: -r, y: r * 0.46))
        body.addCurve(to: CGPoint(x: 0, y: -r * 1.16), control1: CGPoint(x: -r, y: -r * 0.72), control2: CGPoint(x: -r * 0.58, y: -r * 1.16))
        body.closeSubpath()
        b.fill(body, with: .radialGradient(Gradient(colors: [color.opacity(0.72), color, color]),
                                           center: CGPoint(x: -r * 0.35, y: -r * 0.45), startRadius: 0, endRadius: r * 1.8))
        b.fill(body, with: .radialGradient(Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0.16)]),
                                           center: CGPoint(x: -r * 0.35, y: -r * 0.45), startRadius: r * 0.9, endRadius: r * 2.0))
        var knot = Path()
        knot.move(to: CGPoint(x: -r * 0.15, y: r * 1.30))
        knot.addLine(to: CGPoint(x: r * 0.15, y: r * 1.30))
        knot.addLine(to: CGPoint(x: 0, y: r * 1.10))
        knot.closeSubpath()
        b.fill(knot, with: .color(color))
        b.fill(knot, with: .color(Color.black.opacity(0.12)))
        b.fill(Path(ellipseIn: CGRect(x: -r * 0.60, y: -r * 0.80, width: r * 0.40, height: r * 0.62)),
               with: .color(Color.white.opacity(0.6)))
        b.fill(Path(ellipseIn: CGRect(x: -r * 0.62, y: -r * 0.08, width: r * 0.12, height: r * 0.16)),
               with: .color(Color.white.opacity(0.4)))
    }

    /// A bouquet tied to the kennel roof, swaying gently in the breeze.
    func paintDogBalloons(in context: inout GraphicsContext, time: Double) {
        let kennel = surf(-0.70, -0.30)
        let anchor = CGPoint(x: kennel.x, y: kennel.y - s(0.17))
        let bouquet: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (-0.030, -0.240, 0.038, Color(red: 1.0, green: 0.80, blue: 0.20)),
            (-0.100, -0.175, 0.034, character.color),
            (0.040, -0.170, 0.036, Color(red: 1.0, green: 0.42, blue: 0.40))
        ]
        let swing = 0.06 * sin(time * 0.9)
        for (index, item) in bouquet.enumerated() {
            let angle = swing + 0.035 * sin(time * 1.6 + Double(index) * 2.1)
            let (c, sn) = (CGFloat(cos(angle)), CGFloat(sin(angle)))
            let rest = CGPoint(x: s(item.0), y: s(item.1))
            let bob = s(0.004) * CGFloat(sin(time * 2.2 + Double(index) * 1.3))
            let center = CGPoint(x: anchor.x + rest.x * c - rest.y * sn, y: anchor.y + rest.x * sn + rest.y * c + bob)
            balloon(&context, anchor: anchor, center: center, radius: s(item.2), color: item.3,
                    bend: s(0.010) * CGFloat(sin(time * 1.3 + Double(index))))
        }
    }

    // MARK: - Dog: Paw Paradise

    func paintDogHeaven(in context: inout GraphicsContext) {
        let gold = [Color(red: 1.0, green: 0.93, blue: 0.56), Color(red: 0.98, green: 0.74, blue: 0.20),
                    Color(red: 0.76, green: 0.50, blue: 0.10)]
        let lawn = [Color(red: 0.66, green: 0.94, blue: 0.42), Color(red: 0.38, green: 0.80, blue: 0.30),
                    Color(red: 0.20, green: 0.58, blue: 0.27)]
        let grassColors = [Color(red: 0.30, green: 0.70, blue: 0.24), Color(red: 0.52, green: 0.86, blue: 0.32),
                           Color(red: 0.22, green: 0.56, blue: 0.22)]

        paintAura(in: &context, color: Color(red: 1.0, green: 0.97, blue: 0.82), center: pt(0, -0.44), radius: s(0.72))
        paintCloudCollar(in: &context, front: false)
        paintSatellite(in: &context, center: pt(-0.64, -0.34), width: s(0.12),
                       top: lawn[1], rock: [Color(red: 0.58, green: 0.42, blue: 0.30), Color(red: 0.30, green: 0.20, blue: 0.16)])
        paintTennisBall(&context, pt(-0.64, -0.365), s(0.018))
        paintSatellite(in: &context, center: pt(0.66, -0.42), width: s(0.10),
                       top: lawn[1], rock: [Color(red: 0.58, green: 0.42, blue: 0.30), Color(red: 0.30, green: 0.20, blue: 0.16)])
        paintBone(&context, center: pt(0.66, -0.438), length: s(0.05), thickness: s(0.012), colors: [.white, Color(red: 0.95, green: 0.88, blue: 0.74)])

        paintUnderside(in: &context, material: .init(light: Color(red: 0.64, green: 0.47, blue: 0.33),
                                                     mid: Color(red: 0.47, green: 0.33, blue: 0.23),
                                                     deep: Color(red: 0.29, green: 0.20, blue: 0.17),
                                                     strata: Color(red: 0.20, green: 0.12, blue: 0.08),
                                                     glow: character.tintColor), seed: 4)
        paintHangingRoots(in: &context, color: Color(red: 0.38, green: 0.25, blue: 0.15), seed: 3)
        paintWaterfalls(in: &context, theme: .dog)
        paintSlab(in: &context, surface: lawn,
                  lipMaterial: .init(top: Color(red: 0.52, green: 0.37, blue: 0.25), bottom: Color(red: 0.36, green: 0.24, blue: 0.16),
                                     drips: true, dripColor: Color(red: 0.32, green: 0.68, blue: 0.27)))
        paintSurfaceStripes(in: &context, color: Color.white.opacity(0.07), count: 14)

        // Paw trail leading from the kennel to the winner's spot.
        for index in 0..<5 {
            let t = CGFloat(index) / 4
            let center = CGPoint(x: s(-0.30) + t * s(0.20), y: s(-0.01) + t * s(0.075))
            pawPrint(&context, CGPoint(x: center.x + (index.isMultiple(of: 2) ? s(0.01) : -s(0.01)), y: center.y),
                     s(0.016), Color.white.opacity(0.42))
        }

        paintBoneGate(&context, gold: gold)

        for index in 0..<6 {
            let x = s(-0.44) + CGFloat(index) * s(0.17)
            if abs(x) < s(0.17) { continue }
            tuft(&context, CGPoint(x: x, y: backY(x) + s(0.02)), s(0.035), grassColors, seed: 80 + index)
        }

        paintKennel(&context, base: surf(-0.70, -0.30))
        paintBallTree(&context, base: surf(0.74, -0.22))

        paintBunting(in: &context, from: pt(-0.215, -0.47), to: pt(0.215, -0.47), sag: s(0.07),
                     colors: [character.color, Color(red: 1.0, green: 0.80, blue: 0.22), Color(red: 1.0, green: 0.45, blue: 0.42), .white],
                     flags: 9)
        paintPedestal(in: &context, top: [.white, character.tintColor], side: [gold[2], gold[1], gold[2]],
                      trim: gold[0], glow: Color(red: 1.0, green: 0.95, blue: 0.70))

        paintHydrant(&context, base: surf(-0.56, 0.42))
        paintFoodBowl(&context, center: surf(0.52, 0.46))
        paintTennisBall(&context, surf(0.30, 0.78), s(0.014))
        paintTennisBall(&context, surf(0.36, 0.70), s(0.012))
        for (index, spot) in [surf(-0.86, 0.10), surf(-0.36, 0.72), surf(0.84, 0.18), surf(0.66, 0.62)].enumerated() {
            let petals: [Color] = [.white, Color(red: 1.0, green: 0.82, blue: 0.25), Color(red: 1.0, green: 0.55, blue: 0.70), .white]
            brush.flower(in: &context, base: spot, height: s(0.04), stem: Color(red: 0.24, green: 0.60, blue: 0.24),
                         petal: petals[index], heart: Color(red: 1.0, green: 0.72, blue: 0.14), petals: 6, seed: index)
        }
        paintCloudCollar(in: &context, front: true)
    }

    /// One merged outline, so strokes never cut through where knobs meet the shaft.
    func boneSilhouette(center: CGPoint, length: CGFloat, thickness: CGFloat) -> Path {
        var bone = Path(roundedRect: CGRect(x: center.x - length * 0.42, y: center.y - thickness * 0.5,
                                            width: length * 0.84, height: thickness),
                        cornerRadius: thickness * 0.5)
        for sx in [-1.0, 1.0] as [CGFloat] {
            for sy in [-1.0, 1.0] as [CGFloat] {
                bone = bone.union(circle(CGPoint(x: center.x + sx * length * 0.44, y: center.y + sy * thickness * 0.55), thickness * 0.68))
            }
        }
        return bone
    }

    func paintBone(_ context: inout GraphicsContext, center: CGPoint, length: CGFloat, thickness: CGFloat, colors: [Color]) {
        let bone = boneSilhouette(center: center, length: length, thickness: thickness)
        context.fill(bone, with: linear(colors, CGPoint(x: center.x, y: center.y - thickness * 1.2), CGPoint(x: center.x, y: center.y + thickness * 1.2)))
        context.stroke(bone, with: .color(Color.black.opacity(0.14)), lineWidth: max(0.5, thickness * 0.08))
    }

    /// The crowning bone of the gate: bevelled gold with a paw medallion.
    private func paintGateBone(_ context: inout GraphicsContext, gold: [Color]) {
        let center = pt(0, -0.535)
        let length = s(0.58)
        let thickness = s(0.05)
        let bone = boneSilhouette(center: center, length: length, thickness: thickness)
        let edge = Color(red: 0.66, green: 0.40, blue: 0.06)

        context.fill(bone.offsetBy(dx: 0, dy: s(0.008)), with: .color(Color.black.opacity(0.10)))
        context.fill(bone, with: linear([gold[0], gold[1], gold[2]],
                                        CGPoint(x: 0, y: center.y - thickness * 1.25), CGPoint(x: 0, y: center.y + thickness * 1.25)))
        var bevel = context
        bevel.clip(to: bone)
        bevel.fill(bone.subtracting(bone.offsetBy(dx: 0, dy: -thickness * 0.22)), with: .color(edge.opacity(0.35)))
        bevel.fill(bone.subtracting(bone.offsetBy(dx: 0, dy: thickness * 0.20)), with: .color(Color.white.opacity(0.55)))
        let shaftHalf = length * 0.44 - thickness * 0.68
        bevel.fill(Path(roundedRect: CGRect(x: -shaftHalf * 0.86, y: center.y - thickness * 0.24,
                                            width: shaftHalf * 1.72, height: thickness * 0.14), cornerRadius: thickness * 0.07),
                   with: .color(Color.white.opacity(0.5)))
        for sx in [-1.0, 1.0] as [CGFloat] {
            let knob = CGPoint(x: center.x + sx * length * 0.44 - thickness * 0.22, y: center.y - thickness * 0.80)
            bevel.fill(oval(knob, thickness * 0.20, thickness * 0.13), with: .color(Color.white.opacity(0.7)))
        }
        context.stroke(bone, with: .color(edge), style: round(s(0.004)))

        context.fill(circle(center, s(0.054)), with: radial([gold[0], gold[1], gold[2]],
                                                            CGPoint(x: center.x - s(0.015), y: center.y - s(0.018)), s(0.07)))
        context.stroke(circle(center, s(0.054)), with: .color(edge), lineWidth: s(0.004))
        context.fill(circle(center, s(0.041)), with: linear([character.color, character.deepColor],
                                                            CGPoint(x: 0, y: center.y - s(0.041)), CGPoint(x: 0, y: center.y + s(0.041))))
        context.stroke(circle(center, s(0.041)), with: .color(edge.opacity(0.7)), lineWidth: s(0.003))
        pawPrint(&context, CGPoint(x: center.x, y: center.y + s(0.001)), s(0.050), .white)
        var gleam = Path()
        gleam.addArc(center: center, radius: s(0.047), startAngle: .degrees(200), endAngle: .degrees(250), clockwise: false)
        context.stroke(gleam, with: .color(Color.white.opacity(0.8)), style: round(s(0.004)))
    }

    private func paintBoneGate(_ context: inout GraphicsContext, gold: [Color]) {
        let pillarTop = s(-0.50)
        // Heaven light pooled inside the gate.
        context.fill(oval(pt(0, -0.30), s(0.20), s(0.24)),
                     with: radial([Color.white.opacity(0.85), Color(red: 1.0, green: 0.97, blue: 0.80).opacity(0.4), Color.white.opacity(0)],
                                  pt(0, -0.30), s(0.24)))
        for side in [-1.0, 1.0] as [CGFloat] {
            let x = side * s(0.215)
            let base = backY(x) + s(0.016)
            groundShadow(&context, CGPoint(x: x, y: base), s(0.09))
            let pillar = CGRect(x: x - s(0.024), y: pillarTop, width: s(0.048), height: base - pillarTop)
            context.fill(Path(roundedRect: pillar, cornerRadius: s(0.01)),
                         with: linear([Color(red: 0.98, green: 0.96, blue: 0.92), .white, Color(red: 0.84, green: 0.82, blue: 0.86)],
                                      CGPoint(x: pillar.minX, y: 0), CGPoint(x: pillar.maxX, y: 0)))
            for band in [0.12, 0.5, 0.88] as [CGFloat] {
                let y = pillarTop + (base - pillarTop) * band
                context.fill(Path(roundedRect: CGRect(x: pillar.minX - s(0.005), y: y - s(0.008), width: pillar.width + s(0.01), height: s(0.016)),
                                  cornerRadius: s(0.004)),
                             with: linear(gold, CGPoint(x: 0, y: y - s(0.008)), CGPoint(x: 0, y: y + s(0.008))))
            }
            context.fill(Path(roundedRect: CGRect(x: pillar.minX - s(0.012), y: base - s(0.022), width: pillar.width + s(0.024), height: s(0.026)),
                              cornerRadius: s(0.006)),
                         with: linear(gold, CGPoint(x: 0, y: base - s(0.022)), CGPoint(x: 0, y: base)))
        }
        paintGateBone(&context, gold: gold)
    }

    private func paintKennel(_ context: inout GraphicsContext, base: CGPoint) {
        let width = s(0.16)
        let wall = s(0.095)
        let depth = s(0.035)
        groundShadow(&context, CGPoint(x: base.x + depth * 0.4, y: base.y), width * 1.5)
        let left = base.x - width * 0.5
        let right = base.x + width * 0.5
        let top = base.y - wall
        // Side wall receding towards the island centre.
        var side = Path()
        side.move(to: CGPoint(x: right, y: base.y))
        side.addLine(to: CGPoint(x: right + depth, y: base.y - depth * 0.6))
        side.addLine(to: CGPoint(x: right + depth, y: top - depth * 0.6))
        side.addLine(to: CGPoint(x: right, y: top))
        side.closeSubpath()
        context.fill(side, with: .color(Color(red: 0.78, green: 0.26, blue: 0.22)))
        let frontWall = Path(CGRect(x: left, y: top, width: width, height: wall))
        context.fill(frontWall, with: linear([Color(red: 1.0, green: 0.46, blue: 0.38), Color(red: 0.90, green: 0.32, blue: 0.27)],
                                             CGPoint(x: left, y: top), CGPoint(x: right, y: base.y)))
        for plank in 1..<4 {
            let y = top + wall * CGFloat(plank) / 4
            var seam = Path()
            seam.move(to: CGPoint(x: left, y: y))
            seam.addLine(to: CGPoint(x: right, y: y))
            context.stroke(seam, with: .color(Color.black.opacity(0.10)), lineWidth: s(0.002))
        }
        // Roof.
        let peak = CGPoint(x: base.x, y: top - s(0.075))
        var roofSide = Path()
        roofSide.move(to: peak)
        roofSide.addLine(to: CGPoint(x: peak.x + depth, y: peak.y - depth * 0.6))
        roofSide.addLine(to: CGPoint(x: right + s(0.02) + depth, y: top + s(0.012) - depth * 0.6))
        roofSide.addLine(to: CGPoint(x: right + s(0.02), y: top + s(0.012)))
        roofSide.closeSubpath()
        context.fill(roofSide, with: .color(character.deepColor))
        var roof = Path()
        roof.move(to: peak)
        roof.addLine(to: CGPoint(x: right + s(0.02), y: top + s(0.012)))
        roof.addLine(to: CGPoint(x: left - s(0.02), y: top + s(0.012)))
        roof.closeSubpath()
        context.fill(roof, with: linear([character.tintColor, character.color], peak, CGPoint(x: base.x, y: top)))
        context.stroke(roof, with: .color(.white), style: round(s(0.006)))
        // Arched doorway.
        var door = Path()
        let doorWidth = width * 0.42
        door.move(to: CGPoint(x: base.x - doorWidth * 0.5, y: base.y))
        door.addLine(to: CGPoint(x: base.x - doorWidth * 0.5, y: base.y - wall * 0.45))
        door.addArc(center: CGPoint(x: base.x, y: base.y - wall * 0.45), radius: doorWidth * 0.5,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        door.addLine(to: CGPoint(x: base.x + doorWidth * 0.5, y: base.y))
        door.closeSubpath()
        context.fill(door, with: vertical([Color(red: 0.22, green: 0.10, blue: 0.10), Color(red: 0.36, green: 0.16, blue: 0.14)],
                                          base.y - wall, base.y))
        context.stroke(door, with: .color(Color.white.opacity(0.9)), lineWidth: s(0.004))
        paintBone(&context, center: CGPoint(x: base.x, y: top + s(0.016)), length: s(0.05), thickness: s(0.011),
                  colors: [.white, Color(red: 0.95, green: 0.90, blue: 0.80)])
        // A golden crown on the ridge: this is royalty's kennel.
        let crownBase = CGPoint(x: peak.x, y: peak.y + s(0.003))
        var crown = Path()
        crown.move(to: CGPoint(x: crownBase.x - s(0.028), y: crownBase.y))
        crown.addLine(to: CGPoint(x: crownBase.x - s(0.032), y: crownBase.y - s(0.034)))
        crown.addLine(to: CGPoint(x: crownBase.x - s(0.014), y: crownBase.y - s(0.016)))
        crown.addLine(to: CGPoint(x: crownBase.x, y: crownBase.y - s(0.042)))
        crown.addLine(to: CGPoint(x: crownBase.x + s(0.014), y: crownBase.y - s(0.016)))
        crown.addLine(to: CGPoint(x: crownBase.x + s(0.032), y: crownBase.y - s(0.034)))
        crown.addLine(to: CGPoint(x: crownBase.x + s(0.028), y: crownBase.y))
        crown.closeSubpath()
        context.fill(crown, with: linear([Color(red: 1.0, green: 0.92, blue: 0.5), Color(red: 0.92, green: 0.62, blue: 0.10)],
                                         CGPoint(x: 0, y: crownBase.y - s(0.04)), CGPoint(x: 0, y: crownBase.y)))
        for jewel in [-0.032, 0.0, 0.032] as [CGFloat] {
            let y = crownBase.y - (jewel == 0 ? s(0.042) : s(0.034))
            context.fill(circle(CGPoint(x: crownBase.x + s(jewel), y: y), s(0.006)),
                         with: .color(jewel == 0 ? Color(red: 1.0, green: 0.30, blue: 0.40) : character.color))
        }
    }

    private func paintBallTree(_ context: inout GraphicsContext, base: CGPoint) {
        groundShadow(&context, base, s(0.16))
        brush.trunk(in: &context, base: base, top: CGPoint(x: base.x - s(0.01), y: base.y - s(0.22)),
                    baseWidth: s(0.04), topWidth: s(0.02),
                    bark: Color(red: 0.45, green: 0.29, blue: 0.17), barkLight: Color(red: 0.62, green: 0.43, blue: 0.26))
        let crownCenter = CGPoint(x: base.x - s(0.01), y: base.y - s(0.31))
        brush.crown(in: &context, center: crownCenter, width: s(0.27), height: s(0.22),
                    colors: [Color(red: 0.22, green: 0.62, blue: 0.28), Color(red: 0.34, green: 0.76, blue: 0.32),
                             Color(red: 0.46, green: 0.84, blue: 0.36)], seed: 9, lobes: 6)
        for index in 0..<8 {
            let angle = Double(index) / 8 * 2 * .pi + 0.4
            let reach = noise(index, 61, 0.35, 0.80)
            let ball = CGPoint(x: crownCenter.x + CGFloat(cos(angle)) * s(0.10) * reach,
                               y: crownCenter.y + CGFloat(sin(angle)) * s(0.075) * reach)
            paintTennisBall(&context, ball, s(0.013))
        }
        paintTennisBall(&context, CGPoint(x: base.x + s(0.06), y: base.y + s(0.006)), s(0.013))
        paintTennisBall(&context, CGPoint(x: base.x - s(0.05), y: base.y + s(0.012)), s(0.011))
    }

    func paintTennisBall(_ context: inout GraphicsContext, _ center: CGPoint, _ radius: CGFloat) {
        context.fill(circle(center, radius), with: radial([Color(red: 0.95, green: 1.0, blue: 0.55), Color(red: 0.76, green: 0.90, blue: 0.16)],
                                                          CGPoint(x: center.x - radius * 0.4, y: center.y - radius * 0.4), radius * 1.6))
        var seam = Path()
        seam.move(to: CGPoint(x: center.x - radius * 0.8, y: center.y - radius * 0.5))
        seam.addQuadCurve(to: CGPoint(x: center.x - radius * 0.7, y: center.y + radius * 0.65),
                          control: CGPoint(x: center.x - radius * 0.1, y: center.y))
        seam.move(to: CGPoint(x: center.x + radius * 0.8, y: center.y - radius * 0.6))
        seam.addQuadCurve(to: CGPoint(x: center.x + radius * 0.7, y: center.y + radius * 0.6),
                          control: CGPoint(x: center.x + radius * 0.1, y: center.y))
        context.stroke(seam, with: .color(Color.white.opacity(0.9)), lineWidth: max(0.5, radius * 0.16))
    }

    private func paintHydrant(_ context: inout GraphicsContext, base: CGPoint) {
        groundShadow(&context, base, s(0.06))
        let red = [Color(red: 1.0, green: 0.42, blue: 0.36), Color(red: 0.86, green: 0.16, blue: 0.14), Color(red: 0.58, green: 0.08, blue: 0.08)]
        let body = CGRect(x: base.x - s(0.016), y: base.y - s(0.055), width: s(0.032), height: s(0.055))
        context.fill(Path(roundedRect: body, cornerRadius: s(0.006)), with: linear(red, CGPoint(x: body.minX, y: 0), CGPoint(x: body.maxX, y: 0)))
        context.fill(Path(roundedRect: CGRect(x: base.x - s(0.022), y: base.y - s(0.008), width: s(0.044), height: s(0.009)), cornerRadius: s(0.003)),
                     with: .color(red[2]))
        context.fill(Path(roundedRect: CGRect(x: base.x - s(0.03), y: base.y - s(0.040), width: s(0.06), height: s(0.012)), cornerRadius: s(0.005)),
                     with: linear(red, CGPoint(x: 0, y: base.y - s(0.04)), CGPoint(x: 0, y: base.y - s(0.028))))
        var cap = Path()
        cap.addArc(center: CGPoint(x: base.x, y: base.y - s(0.055)), radius: s(0.019), startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        cap.closeSubpath()
        context.fill(cap, with: linear(red, CGPoint(x: base.x - s(0.02), y: 0), CGPoint(x: base.x + s(0.02), y: 0)))
        context.fill(Path(CGRect(x: base.x - s(0.022), y: base.y - s(0.058), width: s(0.044), height: s(0.005))), with: .color(red[2]))
        context.fill(Path(roundedRect: CGRect(x: body.minX + s(0.006), y: body.minY + s(0.004), width: s(0.005), height: s(0.04)), cornerRadius: s(0.002)),
                     with: .color(Color.white.opacity(0.35)))
    }

    private func paintFoodBowl(_ context: inout GraphicsContext, center: CGPoint) {
        groundShadow(&context, CGPoint(x: center.x, y: center.y + s(0.008)), s(0.10))
        var bowl = Path()
        bowl.move(to: CGPoint(x: center.x - s(0.045), y: center.y - s(0.016)))
        bowl.addLine(to: CGPoint(x: center.x + s(0.045), y: center.y - s(0.016)))
        bowl.addLine(to: CGPoint(x: center.x + s(0.036), y: center.y + s(0.010)))
        bowl.addQuadCurve(to: CGPoint(x: center.x - s(0.036), y: center.y + s(0.010)), control: CGPoint(x: center.x, y: center.y + s(0.018)))
        bowl.closeSubpath()
        paintBone(&context, center: CGPoint(x: center.x - s(0.012), y: center.y - s(0.024)), length: s(0.05), thickness: s(0.011),
                  colors: [.white, Color(red: 0.95, green: 0.88, blue: 0.74)])
        paintBone(&context, center: CGPoint(x: center.x + s(0.014), y: center.y - s(0.030)), length: s(0.046), thickness: s(0.010),
                  colors: [.white, Color(red: 0.95, green: 0.88, blue: 0.74)])
        context.fill(bowl, with: linear([character.tintColor, character.color, character.deepColor],
                                        CGPoint(x: center.x - s(0.045), y: 0), CGPoint(x: center.x + s(0.045), y: 0)))
        context.fill(oval(CGPoint(x: center.x, y: center.y - s(0.016)), s(0.045), s(0.009)), with: .color(Color(red: 1.0, green: 0.84, blue: 0.30)))
        context.fill(oval(CGPoint(x: center.x, y: center.y - s(0.016)), s(0.036), s(0.0055)), with: .color(Color(red: 0.62, green: 0.38, blue: 0.20)))
    }

    // MARK: - Lion: Golden Pride Lands

    func paintLionHeaven(in context: inout GraphicsContext) {
        let gold = [Color(red: 1.0, green: 0.90, blue: 0.48), Color(red: 0.97, green: 0.70, blue: 0.18), Color(red: 0.74, green: 0.46, blue: 0.08)]
        let savanna = [Color(red: 0.99, green: 0.88, blue: 0.52), Color(red: 0.90, green: 0.70, blue: 0.30), Color(red: 0.70, green: 0.48, blue: 0.18)]
        let grass = [Color(red: 0.96, green: 0.78, blue: 0.30), Color(red: 0.84, green: 0.60, blue: 0.18), Color(red: 1.0, green: 0.88, blue: 0.46)]

        paintAura(in: &context, color: Color(red: 1.0, green: 0.78, blue: 0.40), center: pt(0, -0.40), radius: s(0.80))
        paintStripedSun(&context, center: pt(0, -0.40), radius: s(0.25))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.84, blue: 0.70), front: false)
        paintSatellite(in: &context, center: pt(0.64, -0.40), width: s(0.11), top: savanna[1],
                       rock: [Color(red: 0.82, green: 0.46, blue: 0.26), Color(red: 0.46, green: 0.22, blue: 0.14)])
        tuft(&context, pt(0.645, -0.405), s(0.03), grass, seed: 4)

        paintUnderside(in: &context, material: .init(light: Color(red: 0.88, green: 0.54, blue: 0.30),
                                                     mid: Color(red: 0.72, green: 0.36, blue: 0.20),
                                                     deep: Color(red: 0.42, green: 0.18, blue: 0.13),
                                                     strata: Color(red: 0.98, green: 0.80, blue: 0.56),
                                                     glow: Color(red: 1.0, green: 0.80, blue: 0.50)), seed: 9)
        paintHangingRoots(in: &context, color: Color(red: 0.50, green: 0.30, blue: 0.14), seed: 12, count: 5)
        paintWaterfalls(in: &context, theme: .lion)
        paintSlab(in: &context, surface: savanna,
                  lipMaterial: .init(top: Color(red: 0.80, green: 0.46, blue: 0.24), bottom: Color(red: 0.60, green: 0.30, blue: 0.17),
                                     drips: true, dripColor: Color(red: 0.90, green: 0.68, blue: 0.24)))
        brush.surfaceStrokes(in: &context, bounds: CGRect(x: -rx * 0.7, y: -ry * 0.6, width: rx * 1.4, height: ry * 1.3),
                             count: 14, color: Color(red: 0.70, green: 0.46, blue: 0.16).opacity(0.35), highlight: nil,
                             lengthRange: 0.03...0.06, seed: 3)

        // Watering hole feeding the waterfall.
        let pool = surf(0.58, 0.36)
        context.fill(oval(pool, s(0.10), s(0.028)), with: linear([Color(red: 0.56, green: 0.86, blue: 0.98), Color(red: 0.22, green: 0.58, blue: 0.86)],
                                                                CGPoint(x: pool.x, y: pool.y - s(0.028)), CGPoint(x: pool.x, y: pool.y + s(0.028))))
        context.stroke(oval(pool, s(0.10), s(0.028)), with: .color(Color(red: 0.62, green: 0.40, blue: 0.16).opacity(0.6)), lineWidth: s(0.004))
        brush.waterGlints(in: &context, bounds: CGRect(x: pool.x - s(0.07), y: pool.y - s(0.018), width: s(0.13), height: s(0.03)),
                          count: 3, color: .white, seed: 5)

        paintPrideRock(&context)
        paintAcacia(&context, base: surf(0.90, -0.12), crown: pt(0.47, -0.30), width: s(0.20), seed: 2)
        paintAcacia(&context, base: surf(0.60, -0.48), crown: pt(0.30, -0.44), width: s(0.33), seed: 7)

        for index in 0..<9 {
            let x = s(-0.46) + CGFloat(index) * s(0.115)
            if abs(x) < s(0.15) { continue }
            tuft(&context, CGPoint(x: x, y: backY(x) + s(0.024)), s(noise(index, 3, 0.04, 0.065)), grass, seed: 30 + index)
        }
        brush.rock(in: &context, center: surf(-0.66, 0.30), radius: s(0.035), light: Color(red: 0.94, green: 0.70, blue: 0.46),
                   dark: Color(red: 0.62, green: 0.34, blue: 0.20), seed: 3)
        brush.rock(in: &context, center: surf(-0.50, 0.50), radius: s(0.022), light: Color(red: 0.94, green: 0.70, blue: 0.46),
                   dark: Color(red: 0.62, green: 0.34, blue: 0.20), seed: 8)

        paintPedestal(in: &context, top: [Color(red: 1.0, green: 0.92, blue: 0.70), Color(red: 0.94, green: 0.74, blue: 0.42)],
                      side: [Color(red: 0.62, green: 0.30, blue: 0.16), Color(red: 0.86, green: 0.50, blue: 0.28), Color(red: 0.58, green: 0.28, blue: 0.15)],
                      trim: gold[0], glow: Color(red: 1.0, green: 0.86, blue: 0.48))

        for (index, spot) in [surf(-0.80, 0.30), surf(-0.30, 0.80), surf(0.30, 0.82), surf(0.85, 0.25)].enumerated() {
            tuft(&context, spot, s(noise(index, 9, 0.04, 0.055)), grass, seed: 50 + index)
        }
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.84, blue: 0.70), front: true)
    }

    private func paintStripedSun(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        context.fill(circle(center, radius * 1.5), with: radial([Color(red: 1.0, green: 0.86, blue: 0.40).opacity(0.85), Color(red: 1.0, green: 0.62, blue: 0.30).opacity(0)],
                                                                center, radius * 1.5))
        var stripes = Path()
        for index in 0..<4 {
            let y = center.y + radius * (0.18 + CGFloat(index) * 0.21)
            stripes.addRect(CGRect(x: center.x - radius, y: y, width: radius * 2, height: radius * (0.035 + CGFloat(index) * 0.022)))
        }
        var sun = context
        sun.clip(to: stripes, options: .inverse)
        sun.fill(circle(center, radius), with: vertical([Color(red: 1.0, green: 0.97, blue: 0.70), Color(red: 1.0, green: 0.80, blue: 0.28),
                                                         Color(red: 0.98, green: 0.50, blue: 0.22)], center.y - radius, center.y + radius))
    }

    private func paintPrideRock(_ context: inout GraphicsContext) {
        let sandstone = [Color(red: 1.0, green: 0.84, blue: 0.60), Color(red: 0.90, green: 0.58, blue: 0.32), Color(red: 0.62, green: 0.32, blue: 0.18)]
        let shade = Color(red: 0.46, green: 0.20, blue: 0.12)
        groundShadow(&context, pt(-0.33, -0.03), s(0.34))

        // One silhouette: the massif rises on the left and continues straight
        // into the jutting ledge, so the ledge visibly grows out of the rock.
        var rock = Path()
        rock.move(to: pt(-0.54, 0.0))
        rock.addQuadCurve(to: pt(-0.52, -0.20), control: pt(-0.56, -0.10))
        rock.addQuadCurve(to: pt(-0.47, -0.36), control: pt(-0.51, -0.30))
        rock.addQuadCurve(to: pt(-0.40, -0.47), control: pt(-0.46, -0.445))
        rock.addQuadCurve(to: pt(-0.04, -0.465), control: pt(-0.22, -0.515))
        rock.addQuadCurve(to: pt(-0.05, -0.425), control: pt(-0.025, -0.445))
        rock.addQuadCurve(to: pt(-0.22, -0.39), control: pt(-0.14, -0.395))
        rock.addQuadCurve(to: pt(-0.19, -0.24), control: pt(-0.205, -0.33))
        rock.addQuadCurve(to: pt(-0.15, -0.10), control: pt(-0.15, -0.17))
        rock.addQuadCurve(to: pt(-0.17, 0.0), control: pt(-0.14, -0.03))
        rock.addQuadCurve(to: pt(-0.54, 0.0), control: pt(-0.36, 0.035))
        rock.closeSubpath()
        context.fill(rock, with: linear(sandstone, pt(-0.46, -0.50), pt(-0.18, 0.0)))

        var detail = context
        detail.clip(to: rock)
        // Shaded flank facing away from the sun, below the ledge.
        var flank = Path()
        flank.move(to: pt(-0.30, -0.40))
        flank.addQuadCurve(to: pt(-0.27, -0.10), control: pt(-0.25, -0.24))
        flank.addQuadCurve(to: pt(-0.30, 0.05), control: pt(-0.29, -0.02))
        flank.addLine(to: pt(-0.10, 0.05))
        flank.addLine(to: pt(-0.10, -0.40))
        flank.closeSubpath()
        detail.fill(flank, with: linear([shade.opacity(0.08), shade.opacity(0.40)], pt(-0.28, 0), pt(-0.15, 0)))
        // Underside of the ledge in shadow, darkest towards the root.
        var underside = Path()
        underside.move(to: pt(-0.05, -0.425))
        underside.addQuadCurve(to: pt(-0.22, -0.39), control: pt(-0.14, -0.395))
        underside.addQuadCurve(to: pt(-0.36, -0.37), control: pt(-0.29, -0.37))
        detail.stroke(underside.offsetBy(dx: 0, dy: -s(0.008)), with: .color(shade.opacity(0.38)), style: round(s(0.018)))
        // A bedding plane runs from the massif into the ledge: one rock.
        var bedding = Path()
        bedding.move(to: pt(-0.47, -0.40))
        bedding.addQuadCurve(to: pt(-0.12, -0.442), control: pt(-0.30, -0.465))
        detail.stroke(bedding, with: .color(shade.opacity(0.22)), style: round(s(0.004)))
        detail.stroke(bedding.offsetBy(dx: 0, dy: -s(0.006)), with: .color(Color.white.opacity(0.20)), style: round(s(0.003)))
        // Rounded bulges on the massif.
        for (center, radius) in [(pt(-0.44, -0.24), s(0.07)), (pt(-0.38, -0.10), s(0.09)), (pt(-0.48, -0.06), s(0.05))] {
            let lit = CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.3)
            detail.fill(circle(lit, radius * 0.8), with: radial([Color.white.opacity(0.22), Color.white.opacity(0)], lit, radius * 0.8))
            var seam = Path()
            seam.addArc(center: center, radius: radius, startAngle: .degrees(20), endAngle: .degrees(150), clockwise: false)
            detail.stroke(seam, with: .color(shade.opacity(0.30)), style: round(s(0.005)))
        }
        var cracks = Path()
        cracks.move(to: pt(-0.33, -0.36)); cracks.addLine(to: pt(-0.345, -0.28)); cracks.addLine(to: pt(-0.33, -0.22))
        cracks.move(to: pt(-0.22, -0.30)); cracks.addLine(to: pt(-0.235, -0.20)); cracks.addLine(to: pt(-0.22, -0.12))
        cracks.move(to: pt(-0.50, -0.16)); cracks.addLine(to: pt(-0.47, -0.12))
        detail.stroke(cracks, with: .color(shade.opacity(0.42)), style: round(s(0.004)))

        var crest = Path()
        crest.move(to: pt(-0.45, -0.43))
        crest.addQuadCurve(to: pt(-0.40, -0.468), control: pt(-0.44, -0.455))
        crest.addQuadCurve(to: pt(-0.045, -0.463), control: pt(-0.22, -0.512))
        context.stroke(crest, with: .color(Color(red: 1.0, green: 0.95, blue: 0.80)), style: round(s(0.006)))

        // Loose boulders around the foot.
        for (center, radius, seed) in [(pt(-0.14, -0.015), s(0.035), 11), (pt(-0.56, 0.01), s(0.03), 12), (pt(-0.20, 0.02), s(0.02), 13)] {
            brush.rock(in: &context, center: center, radius: radius, light: sandstone[0], dark: sandstone[2], seed: seed)
        }
        let grass = [Color(red: 0.96, green: 0.78, blue: 0.30), Color(red: 0.80, green: 0.56, blue: 0.16)]
        tuft(&context, pt(-0.30, -0.49), s(0.035), grass, seed: 70)
        tuft(&context, pt(-0.50, -0.20), s(0.03), grass, seed: 71)
        tuft(&context, pt(-0.40, 0.01), s(0.035), grass, seed: 72)
    }

    private func paintAcacia(_ context: inout GraphicsContext, base: CGPoint, crown: CGPoint, width: CGFloat, seed: Int) {
        groundShadow(&context, base, width * 0.5)
        let bark = Color(red: 0.42, green: 0.26, blue: 0.16)
        let trunkEnd = CGPoint(x: crown.x - width * 0.18, y: crown.y + width * 0.05)
        let trunkControl = CGPoint(x: base.x - width * 0.02, y: (base.y + crown.y) * 0.5)
        func onTrunk(_ t: CGFloat) -> CGPoint {
            let a = 1 - t
            return CGPoint(x: a * a * base.x + 2 * a * t * trunkControl.x + t * t * trunkEnd.x,
                           y: a * a * base.y + 2 * a * t * trunkControl.y + t * t * trunkEnd.y)
        }
        var trunk = Path()
        trunk.move(to: base)
        trunk.addQuadCurve(to: trunkEnd, control: trunkControl)
        context.stroke(trunk, with: .color(bark), style: round(width * 0.045))
        // The branches fork from points on the trunk itself.
        let lowFork = onTrunk(0.45)
        let highFork = onTrunk(0.62)
        var branches = Path()
        branches.move(to: lowFork)
        branches.addQuadCurve(to: CGPoint(x: crown.x + width * 0.22, y: crown.y + width * 0.05),
                              control: CGPoint(x: crown.x + width * 0.10, y: (lowFork.y + crown.y) * 0.5))
        branches.move(to: highFork)
        branches.addQuadCurve(to: CGPoint(x: crown.x + width * 0.02, y: crown.y + width * 0.04),
                              control: CGPoint(x: (highFork.x + crown.x) * 0.5, y: highFork.y - width * 0.02))
        context.stroke(branches, with: .color(bark), style: round(width * 0.032))
        let layers: [(CGFloat, CGFloat, Color)] = [(0.0, 1.0, Color(red: 0.34, green: 0.46, blue: 0.16)),
                                                   (-0.045, 0.86, Color(red: 0.48, green: 0.60, blue: 0.20)),
                                                   (-0.085, 0.62, Color(red: 0.62, green: 0.72, blue: 0.28))]
        for (index, layer) in layers.enumerated() {
            let center = CGPoint(x: crown.x - width * 0.03 * CGFloat(index), y: crown.y + width * layer.0)
            let points = brush.blobPoints(center: center, radiusX: width * 0.5 * layer.1, radiusY: width * 0.11 * layer.1,
                                          count: 11, irregularity: 0.22, seed: seed + index * 5)
            context.fill(brush.blob(points), with: .color(layer.2))
        }
    }

    // MARK: - Octopus: Coral Kingdom

    func paintOctopusHeaven(in context: inout GraphicsContext) {
        let sand = [Color(red: 0.99, green: 0.95, blue: 1.0), Color(red: 0.90, green: 0.84, blue: 0.98), Color(red: 0.72, green: 0.62, blue: 0.90)]
        let coralPink = Color(red: 1.0, green: 0.42, blue: 0.62)
        let coralOrange = Color(red: 1.0, green: 0.60, blue: 0.30)
        let teal = Color(red: 0.24, green: 0.80, blue: 0.80)

        paintAura(in: &context, color: Color(red: 0.88, green: 0.80, blue: 1.0), center: pt(0, -0.32), radius: s(0.75))
        paintCloudCollar(in: &context, tint: Color(red: 0.86, green: 0.82, blue: 1.0), front: false)
        paintScallopHalo(&context, center: pt(0, -0.10), radius: s(0.42))
        paintSatellite(in: &context, center: pt(-0.64, -0.38), width: s(0.11), top: sand[1],
                       rock: [Color(red: 0.80, green: 0.50, blue: 0.80), Color(red: 0.42, green: 0.22, blue: 0.56)])
        brush.branchCoral(in: &context, base: pt(-0.64, -0.39), height: s(0.07), color: coralOrange, thickness: s(0.006), seed: 3)

        paintUnderside(in: &context, material: .init(light: Color(red: 0.86, green: 0.56, blue: 0.82),
                                                     mid: Color(red: 0.62, green: 0.36, blue: 0.70),
                                                     deep: Color(red: 0.34, green: 0.18, blue: 0.48),
                                                     strata: Color(red: 0.98, green: 0.80, blue: 1.0),
                                                     glow: Color(red: 0.80, green: 0.70, blue: 1.0)), seed: 21)
        // Porous reef rock.
        var pores = context
        pores.clip(to: undersidePath(seed: 21))
        for index in 0..<26 {
            let x = noise(index, 41, -0.9, 0.9) * rx
            let y = frontY(x) + lip * 1.4 + noise(index, 42, 0, 1) * floorDepth * 0.5
            let radius = s(noise(index, 43, 0.004, 0.010))
            pores.fill(oval(CGPoint(x: x, y: y), radius, radius * 0.8), with: .color(Color(red: 0.24, green: 0.10, blue: 0.34).opacity(0.45)))
            pores.fill(oval(CGPoint(x: x, y: y - radius * 0.5), radius * 0.8, radius * 0.4), with: .color(Color.white.opacity(0.12)))
        }
        paintHangingRoots(in: &context, color: Color(red: 0.22, green: 0.58, blue: 0.42), seed: 44, count: 8)
        paintWaterfalls(in: &context, theme: .octopus)
        paintSlab(in: &context, surface: sand,
                  lipMaterial: .init(top: Color(red: 0.74, green: 0.52, blue: 0.84), bottom: Color(red: 0.52, green: 0.32, blue: 0.68),
                                     drips: true, dripColor: Color(red: 0.86, green: 0.78, blue: 0.98)))
        // Ripple marks in the sand.
        brush.surfaceStrokes(in: &context, bounds: CGRect(x: -rx * 0.75, y: -ry * 0.6, width: rx * 1.5, height: ry * 1.3),
                             count: 12, color: Color(red: 0.62, green: 0.50, blue: 0.86).opacity(0.35),
                             highlight: Color.white.opacity(0.5), lengthRange: 0.04...0.08, seed: 6)

        // Tide pool with its own waterfall.
        let pool = surf(0.66, 0.30)
        context.fill(oval(pool, s(0.09), s(0.03)), with: linear([Color(red: 0.62, green: 0.96, blue: 0.98), Color(red: 0.18, green: 0.66, blue: 0.86)],
                                                               CGPoint(x: pool.x, y: pool.y - s(0.03)), CGPoint(x: pool.x, y: pool.y + s(0.03))))
        context.stroke(oval(pool, s(0.09), s(0.03)), with: .color(Color.white.opacity(0.7)), lineWidth: s(0.004))

        // Left reef garden.
        brush.seaFan(in: &context, base: surf(-0.48, -0.62), height: s(0.20), color: Color(red: 0.70, green: 0.40, blue: 0.96), seed: 2)
        brush.branchCoral(in: &context, base: surf(-0.76, -0.30), height: s(0.30), color: coralPink, thickness: s(0.016), seed: 4)
        brush.sponge(in: &context, base: surf(-0.88, 0.12), height: s(0.07), color: coralOrange,
                     shade: Color(red: 0.86, green: 0.36, blue: 0.20), tubes: 3, seed: 5)
        brush.brainCoral(in: &context, center: surf(-0.56, 0.20), radius: s(0.038), color: Color(red: 1.0, green: 0.72, blue: 0.50),
                         groove: Color(red: 0.86, green: 0.46, blue: 0.30), seed: 3)
        brush.anemone(in: &context, base: surf(-0.36, 0.60), radius: s(0.03), color: Color(red: 1.0, green: 0.56, blue: 0.74),
                      tip: .white, tentacles: 13, seed: 4)

        // Right reef garden.
        brush.kelp(in: &context, base: surf(0.80, -0.40), height: s(0.36), sway: 0.10,
                   color: Color(red: 0.18, green: 0.54, blue: 0.40), blade: Color(red: 0.36, green: 0.78, blue: 0.48), seed: 2)
        brush.kelp(in: &context, base: surf(0.70, -0.55), height: s(0.28), sway: -0.12,
                   color: Color(red: 0.18, green: 0.54, blue: 0.40), blade: Color(red: 0.30, green: 0.70, blue: 0.44), seed: 5)
        brush.branchCoral(in: &context, base: surf(0.52, -0.58), height: s(0.20), color: teal, thickness: s(0.012), seed: 8)
        brush.plateCoral(in: &context, base: surf(0.86, 0.05), width: s(0.10), color: Color(red: 0.98, green: 0.80, blue: 0.40),
                         shade: Color(red: 0.86, green: 0.56, blue: 0.24), seed: 2)
        brush.starfish(in: &context, center: surf(0.40, 0.70), radius: s(0.022), color: Color(red: 1.0, green: 0.50, blue: 0.36),
                       shade: Color(red: 0.86, green: 0.30, blue: 0.24), rotation: 0.3)
        brush.shell(in: &context, center: surf(-0.66, 0.58), radius: s(0.018), color: Color(red: 1.0, green: 0.86, blue: 0.80),
                    shade: Color(red: 0.94, green: 0.60, blue: 0.62))
        brush.shell(in: &context, center: surf(0.22, 0.86), radius: s(0.014), color: .white, shade: Color(red: 0.80, green: 0.72, blue: 0.96))

        paintPedestal(in: &context, top: [.white, Color(red: 0.92, green: 0.88, blue: 1.0), Color(red: 1.0, green: 0.86, blue: 0.94)],
                      side: [Color(red: 0.50, green: 0.30, blue: 0.70), Color(red: 0.74, green: 0.56, blue: 0.92), Color(red: 0.46, green: 0.26, blue: 0.64)],
                      trim: Color(red: 1.0, green: 0.98, blue: 1.0), glow: Color(red: 0.86, green: 0.76, blue: 1.0))
        for index in 0..<11 {
            let angle = Double(index) / 11 * .pi
            let pearl = CGPoint(x: CGFloat(cos(angle)) * s(0.15), y: feetY + s(0.002) + CGFloat(sin(angle)) * s(0.045) + s(0.012))
            context.fill(circle(pearl, s(0.0065)), with: radial([.white, Color(red: 0.86, green: 0.84, blue: 0.96)],
                                                                 CGPoint(x: pearl.x - s(0.002), y: pearl.y - s(0.002)), s(0.008)))
        }
        paintCloudCollar(in: &context, tint: Color(red: 0.86, green: 0.82, blue: 1.0), front: true)
    }

    private func paintScallopHalo(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let ribs = 11
        let start = Double.pi * 1.06
        let end = Double.pi * 1.94
        var shell = Path()
        shell.move(to: center)
        for index in 0..<ribs {
            let a0 = start + (end - start) * Double(index) / Double(ribs)
            let a1 = start + (end - start) * Double(index + 1) / Double(ribs)
            let mid = (a0 + a1) * 0.5
            let p0 = CGPoint(x: center.x + CGFloat(cos(a0)) * radius, y: center.y + CGFloat(sin(a0)) * radius)
            let p1 = CGPoint(x: center.x + CGFloat(cos(a1)) * radius, y: center.y + CGFloat(sin(a1)) * radius)
            let bulge = CGPoint(x: center.x + CGFloat(cos(mid)) * radius * 1.10, y: center.y + CGFloat(sin(mid)) * radius * 1.10)
            if index == 0 { shell.addLine(to: p0) }
            shell.addQuadCurve(to: p1, control: bulge)
        }
        shell.closeSubpath()
        context.fill(circle(center, radius * 1.25), with: radial([Color.white.opacity(0.75), Color(red: 0.92, green: 0.84, blue: 1.0).opacity(0)],
                                                                 CGPoint(x: center.x, y: center.y - radius * 0.4), radius * 1.25))
        context.fill(shell, with: radial([Color.white, Color(red: 1.0, green: 0.86, blue: 0.92), Color(red: 0.94, green: 0.66, blue: 0.84),
                                          Color(red: 0.70, green: 0.50, blue: 0.92)], center, radius * 1.1))
        for index in 0...ribs {
            let angle = start + (end - start) * Double(index) / Double(ribs)
            var rib = Path()
            rib.move(to: CGPoint(x: center.x + CGFloat(cos(angle)) * radius * 0.14, y: center.y + CGFloat(sin(angle)) * radius * 0.14))
            rib.addLine(to: CGPoint(x: center.x + CGFloat(cos(angle)) * radius * 0.99, y: center.y + CGFloat(sin(angle)) * radius * 0.99))
            context.stroke(rib, with: .color(Color(red: 0.66, green: 0.36, blue: 0.70).opacity(0.35)), lineWidth: s(0.005))
        }
        for band in 1...3 {
            var ring = Path()
            ring.addArc(center: center, radius: radius * CGFloat(band) * 0.25, startAngle: .radians(start), endAngle: .radians(end), clockwise: false)
            context.stroke(ring, with: .color(Color.white.opacity(0.35)), lineWidth: s(0.004))
        }
        context.stroke(shell, with: .color(Color.white.opacity(0.85)), lineWidth: s(0.006))
        // Crown pearl.
        let pearl = CGPoint(x: center.x, y: center.y - radius * 1.17)
        context.fill(circle(pearl, s(0.075)), with: radial([Color.white.opacity(0.9), Color.white.opacity(0)], pearl, s(0.075)))
        context.fill(circle(pearl, s(0.034)), with: radial([.white, Color(red: 0.94, green: 0.90, blue: 1.0), Color(red: 0.76, green: 0.70, blue: 0.94)],
                                                           CGPoint(x: pearl.x - s(0.012), y: pearl.y - s(0.012)), s(0.05)))
        context.fill(circle(CGPoint(x: pearl.x - s(0.011), y: pearl.y - s(0.012)), s(0.008)), with: .color(.white))
        for index in 0..<9 {
            let angle = start + (end - start) * (Double(index) + 0.5) / 9
            let bead = CGPoint(x: center.x + CGFloat(cos(angle)) * radius * 1.13, y: center.y + CGFloat(sin(angle)) * radius * 1.13)
            context.fill(circle(bead, s(0.009)), with: radial([.white, Color(red: 0.86, green: 0.82, blue: 0.98)],
                                                              CGPoint(x: bead.x - s(0.003), y: bead.y - s(0.003)), s(0.012)))
        }
    }

    // MARK: - Crab: Sunset Beach

    func paintCrabHeaven(in context: inout GraphicsContext) {
        let sand = [Color(red: 1.0, green: 0.95, blue: 0.80), Color(red: 0.98, green: 0.86, blue: 0.62), Color(red: 0.90, green: 0.72, blue: 0.46)]
        let lagoon = [Color(red: 0.56, green: 0.96, blue: 0.94), Color(red: 0.18, green: 0.74, blue: 0.86)]

        paintAura(in: &context, color: Color(red: 1.0, green: 0.74, blue: 0.60), center: pt(0.04, -0.32), radius: s(0.78))
        // Sunset bands and sun.
        for (index, color) in [Color(red: 1.0, green: 0.56, blue: 0.62), Color(red: 1.0, green: 0.70, blue: 0.48),
                               Color(red: 1.0, green: 0.86, blue: 0.52)].enumerated() {
            let radius = s(0.46 - CGFloat(index) * 0.10)
            context.fill(oval(pt(0.04, -0.22), radius * 1.3, radius * 0.75), with: radial([color.opacity(0.55), color.opacity(0)], pt(0.04, -0.22), radius * 1.3))
        }
        let sun = pt(0.06, -0.32)
        context.fill(circle(sun, s(0.15)), with: vertical([Color(red: 1.0, green: 0.96, blue: 0.66), Color(red: 1.0, green: 0.70, blue: 0.30),
                                                           Color(red: 1.0, green: 0.42, blue: 0.36)], sun.y - s(0.15), sun.y + s(0.15)))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.80, blue: 0.80), front: false)
        paintPuffCloud(in: &context, center: pt(0.30, -0.62), width: s(0.22), height: s(0.06), seed: 5, shade: Color(red: 1.0, green: 0.78, blue: 0.80))

        paintUnderside(in: &context, material: .init(light: Color(red: 0.98, green: 0.80, blue: 0.56),
                                                     mid: Color(red: 0.86, green: 0.60, blue: 0.38),
                                                     deep: Color(red: 0.56, green: 0.34, blue: 0.24),
                                                     strata: Color(red: 1.0, green: 0.92, blue: 0.76),
                                                     glow: Color(red: 1.0, green: 0.76, blue: 0.62)), seed: 33)
        paintHangingRoots(in: &context, color: Color(red: 0.26, green: 0.58, blue: 0.38), seed: 51, count: 7)
        paintWaterfalls(in: &context, theme: .crab)
        paintSlab(in: &context, surface: sand,
                  lipMaterial: .init(top: Color(red: 0.92, green: 0.74, blue: 0.50), bottom: Color(red: 0.76, green: 0.54, blue: 0.34),
                                     drips: false, dripColor: .clear))
        // Shallow water lapping around the front of the beach, with foam.
        var shore = context
        shore.clip(to: surfacePath)
        var waterBand = Path()
        waterBand.addPath(surfacePath)
        waterBand.addPath(oval(CGPoint(x: 0, y: -ry * 0.16), rx * 0.86, ry * 0.86))
        shore.fill(waterBand, with: linear(lagoon, CGPoint(x: 0, y: 0), CGPoint(x: 0, y: ry)), style: FillStyle(eoFill: true))
        var foam = Path()
        let foamSamples = 40
        for index in 0...foamSamples {
            let t = CGFloat(index) / CGFloat(foamSamples)
            let angle = Double.pi * Double(t)
            let wobble = 1 + 0.02 * CGFloat(sin(Double(index) * 1.9))
            let point = CGPoint(x: CGFloat(cos(angle)) * rx * 0.86 * wobble, y: -ry * 0.16 + CGFloat(sin(angle)) * ry * 0.86 * wobble)
            if index == 0 { foam.move(to: point) } else { foam.addLine(to: point) }
        }
        shore.stroke(foam, with: .color(Color.white.opacity(0.9)), style: round(s(0.007)))
        shore.stroke(foam.offsetBy(dx: 0, dy: s(0.012)), with: .color(Color.white.opacity(0.35)), style: round(s(0.004)))
        brush.surfaceStrokes(in: &context, bounds: CGRect(x: -rx * 0.6, y: -ry * 0.8, width: rx * 1.2, height: ry * 0.9),
                             count: 10, color: Color(red: 0.86, green: 0.66, blue: 0.40).opacity(0.4), highlight: Color.white.opacity(0.4),
                             lengthRange: 0.03...0.06, seed: 12)

        paintPalm(&context, base: surf(-0.66, -0.25), top: pt(-0.20, -0.60), seed: 1)
        paintPalm(&context, base: surf(0.76, -0.38), top: pt(0.38, -0.46), seed: 4)
        paintUmbrella(&context, base: surf(-0.50, 0.05))
        paintSandcastle(&context, base: surf(0.58, 0.12))

        brush.starfish(in: &context, center: surf(-0.30, 0.55), radius: s(0.022), color: Color(red: 1.0, green: 0.46, blue: 0.36),
                       shade: Color(red: 0.86, green: 0.26, blue: 0.22), rotation: 0.4)
        brush.starfish(in: &context, center: surf(0.30, 0.62), radius: s(0.016), color: Color(red: 1.0, green: 0.70, blue: 0.30),
                       shade: Color(red: 0.90, green: 0.46, blue: 0.20), rotation: 1.2)
        brush.shell(in: &context, center: surf(-0.72, 0.40), radius: s(0.016), color: .white, shade: Color(red: 1.0, green: 0.70, blue: 0.66))
        brush.shell(in: &context, center: surf(0.18, -0.70), radius: s(0.012), color: Color(red: 1.0, green: 0.86, blue: 0.76),
                    shade: Color(red: 0.96, green: 0.62, blue: 0.50))

        paintPedestal(in: &context, top: [Color(red: 1.0, green: 0.97, blue: 0.88), Color(red: 1.0, green: 0.86, blue: 0.66)],
                      side: [Color(red: 0.72, green: 0.18, blue: 0.10), Color(red: 0.96, green: 0.40, blue: 0.24), Color(red: 0.66, green: 0.14, blue: 0.08)],
                      trim: .white, glow: Color(red: 1.0, green: 0.82, blue: 0.62))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.80, blue: 0.80), front: true)
    }

    private func paintPalm(_ context: inout GraphicsContext, base: CGPoint, top: CGPoint, seed: Int) {
        groundShadow(&context, base, s(0.12))
        let control = CGPoint(x: base.x + (top.x - base.x) * 0.15, y: (base.y + top.y) * 0.5)
        func curvePoint(_ t: CGFloat) -> CGPoint {
            let a = 1 - t
            return CGPoint(x: a * a * base.x + 2 * a * t * control.x + t * t * top.x,
                           y: a * a * base.y + 2 * a * t * control.y + t * t * top.y)
        }
        // A tapered trunk built from short overlapping stroke pieces, then
        // the characteristic ring scars on top.
        let segments = 22
        for index in 0..<segments {
            let t0 = CGFloat(index) / CGFloat(segments)
            let t1 = CGFloat(index + 1) / CGFloat(segments)
            var piece = Path()
            piece.move(to: curvePoint(t0))
            piece.addLine(to: curvePoint(t1))
            let width = s(0.040) * (1 - t0 * 0.45)
            context.stroke(piece, with: .color(Color(red: 0.62, green: 0.44, blue: 0.26)),
                           style: StrokeStyle(lineWidth: width, lineCap: .round))
            context.stroke(piece.offsetBy(dx: -width * 0.18, dy: 0), with: .color(Color(red: 0.80, green: 0.62, blue: 0.40)),
                           style: StrokeStyle(lineWidth: width * 0.34, lineCap: .round))
        }
        for index in 1..<segments where index % 2 == 0 {
            let t = CGFloat(index) / CGFloat(segments)
            let point = curvePoint(t)
            let radius = s(0.020) * (1 - t * 0.45)
            var ring = Path()
            ring.move(to: CGPoint(x: point.x - radius, y: point.y))
            ring.addQuadCurve(to: CGPoint(x: point.x + radius, y: point.y),
                              control: CGPoint(x: point.x, y: point.y + radius * 0.55))
            context.stroke(ring, with: .color(Color(red: 0.40, green: 0.26, blue: 0.14).opacity(0.75)),
                           style: StrokeStyle(lineWidth: s(0.004), lineCap: .round))
        }
        let frondColors = [Color(red: 0.20, green: 0.62, blue: 0.30), Color(red: 0.30, green: 0.74, blue: 0.34)]
        let angles: [Double] = [-2.9, -2.4, -1.9, -1.3, -0.8, -0.3, 0.2, 2.6]
        for (index, angle) in angles.enumerated() {
            brush.frond(in: &context, base: top, length: s(noise(seed + index, 5, 0.17, 0.22)), angle: angle,
                        curl: angle < -1.6 ? -0.18 : 0.18, color: frondColors[index % 2],
                        tipColor: Color(red: 0.46, green: 0.82, blue: 0.40), leaflets: 9)
        }
        for index in 0..<3 {
            let nut = CGPoint(x: top.x + s(-0.012 + CGFloat(index) * 0.012), y: top.y + s(0.016 + CGFloat(index % 2) * 0.008))
            context.fill(circle(nut, s(0.012)), with: radial([Color(red: 0.62, green: 0.44, blue: 0.24), Color(red: 0.36, green: 0.22, blue: 0.12)],
                                                             CGPoint(x: nut.x - s(0.004), y: nut.y - s(0.004)), s(0.016)))
        }
    }

    private func paintUmbrella(_ context: inout GraphicsContext, base: CGPoint) {
        // Towel.
        var towel = Path()
        towel.move(to: CGPoint(x: base.x - s(0.07), y: base.y + s(0.004)))
        towel.addLine(to: CGPoint(x: base.x + s(0.03), y: base.y - s(0.012)))
        towel.addLine(to: CGPoint(x: base.x + s(0.06), y: base.y + s(0.022)))
        towel.addLine(to: CGPoint(x: base.x - s(0.04), y: base.y + s(0.040)))
        towel.closeSubpath()
        context.fill(towel, with: linear([Color(red: 0.26, green: 0.70, blue: 0.92), .white, Color(red: 0.26, green: 0.70, blue: 0.92), .white,
                                          Color(red: 0.26, green: 0.70, blue: 0.92)],
                                         CGPoint(x: base.x - s(0.06), y: base.y), CGPoint(x: base.x + s(0.05), y: base.y + s(0.02))))
        groundShadow(&context, CGPoint(x: base.x + s(0.02), y: base.y + s(0.01)), s(0.14), opacity: 0.16)
        let top = CGPoint(x: base.x + s(0.012), y: base.y - s(0.20))
        var pole = Path()
        pole.move(to: base)
        pole.addLine(to: top)
        context.stroke(pole, with: .color(Color(red: 0.90, green: 0.86, blue: 0.80)), style: round(s(0.006)))
        let canopyWidth = s(0.17)
        let rim = top.y + s(0.05)
        let panels = 6
        for index in 0..<panels {
            let x0 = top.x - canopyWidth * 0.5 + canopyWidth * CGFloat(index) / CGFloat(panels)
            let x1 = top.x - canopyWidth * 0.5 + canopyWidth * CGFloat(index + 1) / CGFloat(panels)
            var panel = Path()
            panel.move(to: top)
            panel.addLine(to: CGPoint(x: x0, y: rim))
            panel.addQuadCurve(to: CGPoint(x: x1, y: rim), control: CGPoint(x: (x0 + x1) * 0.5, y: rim - s(0.012)))
            panel.closeSubpath()
            context.fill(panel, with: .color(index.isMultiple(of: 2) ? character.color : .white))
        }
        var dome = Path()
        dome.move(to: CGPoint(x: top.x - canopyWidth * 0.5, y: rim))
        dome.addQuadCurve(to: top, control: CGPoint(x: top.x - canopyWidth * 0.42, y: top.y + s(0.004)))
        dome.addQuadCurve(to: CGPoint(x: top.x + canopyWidth * 0.5, y: rim), control: CGPoint(x: top.x + canopyWidth * 0.42, y: top.y + s(0.004)))
        context.stroke(dome, with: .color(Color.white.opacity(0.4)), lineWidth: s(0.003))
        context.fill(circle(CGPoint(x: top.x, y: top.y - s(0.006)), s(0.008)), with: .color(Color(red: 1.0, green: 0.84, blue: 0.30)))
    }

    private func paintSandcastle(_ context: inout GraphicsContext, base: CGPoint) {
        let sand = [Color(red: 1.0, green: 0.90, blue: 0.68), Color(red: 0.92, green: 0.74, blue: 0.48), Color(red: 0.76, green: 0.56, blue: 0.34)]
        groundShadow(&context, base, s(0.18))
        func tower(_ x: CGFloat, _ width: CGFloat, _ height: CGFloat) {
            let rect = CGRect(x: base.x + x - width * 0.5, y: base.y - height, width: width, height: height)
            context.fill(Path(rect), with: linear(sand, CGPoint(x: rect.minX, y: 0), CGPoint(x: rect.maxX, y: 0)))
            let merlons = 3
            for index in 0..<merlons {
                let mw = width / CGFloat(merlons * 2 - 1)
                let mx = rect.minX + CGFloat(index * 2) * mw
                context.fill(Path(CGRect(x: mx, y: rect.minY - mw * 0.9, width: mw, height: mw * 0.9)),
                             with: linear(sand, CGPoint(x: rect.minX, y: 0), CGPoint(x: rect.maxX, y: 0)))
            }
            context.fill(Path(roundedRect: CGRect(x: rect.midX - width * 0.14, y: rect.minY + height * 0.25, width: width * 0.28, height: height * 0.22),
                              cornerRadius: width * 0.14),
                         with: .color(Color(red: 0.56, green: 0.38, blue: 0.24)))
        }
        // Wall.
        let wall = CGRect(x: base.x - s(0.075), y: base.y - s(0.05), width: s(0.15), height: s(0.05))
        context.fill(Path(wall), with: linear(sand, CGPoint(x: wall.minX, y: 0), CGPoint(x: wall.maxX, y: 0)))
        tower(s(-0.065), s(0.036), s(0.085))
        tower(s(0.065), s(0.036), s(0.08))
        tower(0, s(0.05), s(0.12))
        var door = Path()
        door.move(to: CGPoint(x: base.x - s(0.014), y: base.y))
        door.addLine(to: CGPoint(x: base.x - s(0.014), y: base.y - s(0.025)))
        door.addArc(center: CGPoint(x: base.x, y: base.y - s(0.025)), radius: s(0.014), startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        door.addLine(to: CGPoint(x: base.x + s(0.014), y: base.y))
        door.closeSubpath()
        context.fill(door, with: .color(Color(red: 0.50, green: 0.32, blue: 0.20)))
        // Flag.
        let poleTop = CGPoint(x: base.x, y: base.y - s(0.19))
        var pole = Path()
        pole.move(to: CGPoint(x: base.x, y: base.y - s(0.13)))
        pole.addLine(to: poleTop)
        context.stroke(pole, with: .color(Color(red: 0.44, green: 0.30, blue: 0.20)), lineWidth: s(0.004))
        var flag = Path()
        flag.move(to: poleTop)
        flag.addQuadCurve(to: CGPoint(x: poleTop.x + s(0.05), y: poleTop.y + s(0.012)), control: CGPoint(x: poleTop.x + s(0.025), y: poleTop.y - s(0.008)))
        flag.addLine(to: CGPoint(x: poleTop.x, y: poleTop.y + s(0.028)))
        flag.closeSubpath()
        context.fill(flag, with: .color(character.color))
        // Bucket and spade.
        let bucket = CGPoint(x: base.x - s(0.11), y: base.y + s(0.02))
        var pail = Path()
        pail.move(to: CGPoint(x: bucket.x - s(0.018), y: bucket.y - s(0.03)))
        pail.addLine(to: CGPoint(x: bucket.x + s(0.018), y: bucket.y - s(0.03)))
        pail.addLine(to: CGPoint(x: bucket.x + s(0.013), y: bucket.y))
        pail.addLine(to: CGPoint(x: bucket.x - s(0.013), y: bucket.y))
        pail.closeSubpath()
        context.fill(pail, with: linear([Color(red: 1.0, green: 0.86, blue: 0.24), Color(red: 0.96, green: 0.62, blue: 0.10)],
                                        CGPoint(x: bucket.x - s(0.018), y: 0), CGPoint(x: bucket.x + s(0.018), y: 0)))
        context.fill(oval(CGPoint(x: bucket.x, y: bucket.y - s(0.03)), s(0.018), s(0.005)), with: .color(Color(red: 0.80, green: 0.50, blue: 0.10)))
    }

    // MARK: - Elephant: Jungle Oasis

    func paintElephantHeaven(in context: inout GraphicsContext) {
        let lawn = [Color(red: 0.62, green: 0.92, blue: 0.44), Color(red: 0.34, green: 0.76, blue: 0.34), Color(red: 0.16, green: 0.52, blue: 0.28)]
        let leaf = [Color(red: 0.18, green: 0.58, blue: 0.30), Color(red: 0.30, green: 0.72, blue: 0.34), Color(red: 0.44, green: 0.82, blue: 0.38)]
        let pink = Color(red: 1.0, green: 0.52, blue: 0.62)

        paintAura(in: &context, color: Color(red: 1.0, green: 0.90, blue: 0.86), center: pt(0, -0.55), radius: s(0.80))
        paintCloudCollar(in: &context, tint: Color(red: 0.96, green: 0.86, blue: 0.92), front: false)
        paintSatellite(in: &context, center: pt(0.65, -0.44), width: s(0.11), top: lawn[1],
                       rock: [Color(red: 0.70, green: 0.58, blue: 0.56), Color(red: 0.36, green: 0.28, blue: 0.30)])
        brush.flower(in: &context, base: pt(0.65, -0.445), height: s(0.035), stem: leaf[0], petal: pink,
                     heart: Color(red: 1.0, green: 0.86, blue: 0.30), petals: 5, seed: 1)

        paintUnderside(in: &context, material: .init(light: Color(red: 0.70, green: 0.56, blue: 0.48),
                                                     mid: Color(red: 0.52, green: 0.40, blue: 0.36),
                                                     deep: Color(red: 0.32, green: 0.24, blue: 0.26),
                                                     strata: Color(red: 0.94, green: 0.80, blue: 0.74),
                                                     glow: Color(red: 1.0, green: 0.84, blue: 0.86)), seed: 45)
        paintHangingRoots(in: &context, color: Color(red: 0.24, green: 0.50, blue: 0.24), seed: 8, count: 9)
        paintWaterfalls(in: &context, theme: .elephant, onlyLip: true)
        paintSlab(in: &context, surface: lawn,
                  lipMaterial: .init(top: Color(red: 0.56, green: 0.42, blue: 0.34), bottom: Color(red: 0.38, green: 0.28, blue: 0.24),
                                     drips: true, dripColor: Color(red: 0.28, green: 0.64, blue: 0.30)))

        paintOasisCliff(&context)
        paintWaterfalls(in: &context, theme: .elephant, onlyLip: false)
        // Plunge pool at the foot of the falls.
        let pool = pt(0, -0.072)
        context.fill(oval(pool, s(0.25), s(0.045)), with: linear([Color(red: 0.60, green: 0.94, blue: 0.96), Color(red: 0.16, green: 0.62, blue: 0.80)],
                                                                CGPoint(x: 0, y: pool.y - s(0.045)), CGPoint(x: 0, y: pool.y + s(0.045))))
        context.stroke(oval(pool, s(0.25), s(0.045)), with: .color(Color(red: 0.46, green: 0.40, blue: 0.38).opacity(0.7)), lineWidth: s(0.008))
        context.stroke(oval(pool, s(0.244), s(0.040)), with: .color(Color.white.opacity(0.45)), lineWidth: s(0.003))
        brush.waterGlints(in: &context, bounds: CGRect(x: s(-0.20), y: pool.y - s(0.03), width: s(0.40), height: s(0.06)), count: 4, color: .white, seed: 2)
        paintPuffCloud(in: &context, center: pt(0, -0.085), width: s(0.22), height: s(0.05), seed: 61, shade: Color(red: 0.86, green: 0.94, blue: 1.0))
        for (index, spot) in [pt(-0.17, -0.07), pt(0.15, -0.06), pt(0.20, -0.085)].enumerated() {
            brush.lilyPad(in: &context, center: spot, radius: s(0.024), color: Color(red: 0.36, green: 0.76, blue: 0.34),
                          rim: Color(red: 0.20, green: 0.54, blue: 0.26), rotation: Double(index) * 1.7)
        }
        paintLotus(&context, center: pt(-0.165, -0.08), size: s(0.03))
        paintLotus(&context, center: pt(0.195, -0.095), size: s(0.024))

        // Jungle on both flanks.
        paintJunglePalm(&context, base: surf(-0.84, -0.20), height: s(0.42), lean: -0.06, seed: 2)
        paintJunglePalm(&context, base: surf(0.86, -0.28), height: s(0.36), lean: 0.06, seed: 6)
        for index in 0..<4 {
            let side: CGFloat = index < 2 ? -1 : 1
            let base = surf(side * (0.70 - CGFloat(index % 2) * 0.12), 0.05 + CGFloat(index % 2) * 0.25)
            paintBananaLeaf(&context, base: base, length: s(0.13), angle: side < 0 ? -2.3 + Double(index % 2) * 0.5 : -0.8 - Double(index % 2) * 0.5,
                            color: leaf[index % 3])
            paintBananaLeaf(&context, base: base, length: s(0.11), angle: side < 0 ? -1.5 : -1.6,
                            color: leaf[(index + 1) % 3])
        }
        for (index, spot) in [surf(-0.62, 0.30), surf(-0.40, 0.70), surf(0.55, 0.42), surf(0.70, 0.12), surf(-0.78, 0.0)].enumerated() {
            paintHibiscus(&context, center: spot, size: s(index.isMultiple(of: 2) ? 0.026 : 0.02),
                          color: index.isMultiple(of: 2) ? pink : Color(red: 1.0, green: 0.70, blue: 0.30))
        }

        paintPedestal(in: &context, top: [Color(red: 0.92, green: 0.90, blue: 0.86), Color(red: 0.76, green: 0.74, blue: 0.70)],
                      side: [Color(red: 0.46, green: 0.44, blue: 0.42), Color(red: 0.66, green: 0.64, blue: 0.60), Color(red: 0.42, green: 0.40, blue: 0.38)],
                      trim: Color(red: 0.40, green: 0.74, blue: 0.36), glow: Color(red: 1.0, green: 0.80, blue: 0.84))
        for index in 0..<9 {
            let angle = Double(index) / 8 * .pi
            let spot = CGPoint(x: CGFloat(cos(angle)) * s(0.155), y: feetY + s(0.014) + CGFloat(sin(angle)) * s(0.044))
            context.fill(circle(spot, s(0.007)), with: .color(index.isMultiple(of: 2) ? pink : .white))
        }
        paintCloudCollar(in: &context, tint: Color(red: 0.96, green: 0.86, blue: 0.92), front: true)
    }

    private func paintOasisCliff(_ context: inout GraphicsContext) {
        let stone = [Color(red: 0.86, green: 0.76, blue: 0.72), Color(red: 0.66, green: 0.54, blue: 0.52), Color(red: 0.42, green: 0.34, blue: 0.36)]
        func cliff(_ points: [CGPoint]) -> Path {
            var path = Path()
            path.move(to: points[0])
            for point in points.dropFirst() { path.addLine(to: point) }
            path.closeSubpath()
            return path
        }
        let left = cliff([pt(-0.44, -0.07), pt(-0.45, -0.30), pt(-0.40, -0.44), pt(-0.31, -0.55), pt(-0.20, -0.60),
                          pt(-0.09, -0.57), pt(-0.055, -0.555), pt(-0.06, -0.09)])
        let right = cliff([pt(0.06, -0.09), pt(0.055, -0.555), pt(0.10, -0.60), pt(0.22, -0.66), pt(0.33, -0.58),
                           pt(0.42, -0.42), pt(0.45, -0.25), pt(0.44, -0.07)])
        for (index, side) in [left, right].enumerated() {
            context.fill(side, with: linear(stone, pt(index == 0 ? -0.40 : 0.06, -0.6), pt(index == 0 ? -0.06 : 0.44, -0.08)))
            var detail = context
            detail.clip(to: side)
            for band in 0..<6 {
                let y = s(-0.56) + CGFloat(band) * s(0.085)
                var ledge = Path()
                ledge.move(to: CGPoint(x: s(-0.5), y: y))
                ledge.addCurve(to: CGPoint(x: s(0.5), y: y + s(0.01)), control1: CGPoint(x: s(-0.2), y: y + s(0.03)),
                               control2: CGPoint(x: s(0.2), y: y - s(0.02)))
                detail.stroke(ledge, with: .color(Color.black.opacity(0.12)), lineWidth: s(0.006))
                detail.stroke(ledge.offsetBy(dx: 0, dy: -s(0.006)), with: .color(Color.white.opacity(0.14)), lineWidth: s(0.003))
            }
            detail.fill(Path(CGRect(x: index == 0 ? s(-0.10) : s(0.055), y: s(-0.7), width: s(0.05), height: s(0.7))),
                        with: linear(index == 0 ? [Color.clear, Color.black.opacity(0.2)] : [Color.black.opacity(0.2), Color.clear],
                                     CGPoint(x: index == 0 ? s(-0.10) : s(0.055), y: 0), CGPoint(x: index == 0 ? s(-0.05) : s(0.105), y: 0)))
        }
        // Moss caps and hanging vines.
        let mossColors = [Color(red: 0.28, green: 0.66, blue: 0.30), Color(red: 0.44, green: 0.80, blue: 0.36)]
        for (index, cap) in [pt(-0.30, -0.56), pt(-0.16, -0.60), pt(0.16, -0.64), pt(0.30, -0.59), pt(-0.40, -0.45), pt(0.40, -0.43)].enumerated() {
            let points = brush.blobPoints(center: cap, radiusX: s(0.06), radiusY: s(0.02), count: 9, irregularity: 0.3, seed: index * 3)
            context.fill(brush.blob(points), with: .color(mossColors[index % 2]))
        }
        for index in 0..<8 {
            let x = s(-0.36) + CGFloat(index) * s(0.10)
            if abs(x) < s(0.08) { continue }
            let top = CGPoint(x: x, y: s(-0.56) + abs(x) * 0.15)
            let length = s(noise(index, 21, 0.12, 0.26))
            var vine = Path()
            vine.move(to: top)
            vine.addQuadCurve(to: CGPoint(x: x + s(0.01), y: top.y + length), control: CGPoint(x: x - s(0.02), y: top.y + length * 0.5))
            context.stroke(vine, with: .color(Color(red: 0.22, green: 0.54, blue: 0.24)), style: round(s(0.004)))
            for leafIndex in 0..<4 {
                let t = CGFloat(leafIndex + 1) / 5
                brush.leaf(in: &context, center: CGPoint(x: x - s(0.006) + (leafIndex.isMultiple(of: 2) ? s(0.008) : -s(0.008)), y: top.y + length * t),
                           length: s(0.018), angle: leafIndex.isMultiple(of: 2) ? 0.6 : 2.5, color: mossColors[leafIndex % 2], vein: 0)
            }
        }
        // Mist at the top lip of the falls.
        context.fill(oval(pt(0, -0.56), s(0.07), s(0.014)), with: .color(Color.white.opacity(0.9)))
    }

    private func paintJunglePalm(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, lean: CGFloat, seed: Int) {
        groundShadow(&context, base, s(0.12))
        let top = CGPoint(x: base.x + s(lean), y: base.y - height)
        brush.trunk(in: &context, base: base, top: top, baseWidth: s(0.03), topWidth: s(0.018),
                    bark: Color(red: 0.52, green: 0.38, blue: 0.26), barkLight: Color(red: 0.70, green: 0.54, blue: 0.36), grain: 2, seed: seed)
        let angles: [Double] = [-2.8, -2.3, -1.8, -1.3, -0.8, -0.35, 0.15]
        for (index, angle) in angles.enumerated() {
            brush.frond(in: &context, base: top, length: s(noise(seed + index, 8, 0.15, 0.19)), angle: angle,
                        curl: angle < -1.55 ? -0.2 : 0.2, color: Color(red: 0.16, green: 0.54, blue: 0.28),
                        tipColor: Color(red: 0.36, green: 0.76, blue: 0.36), leaflets: 9)
        }
    }

    func paintBananaLeaf(_ context: inout GraphicsContext, base: CGPoint, length: CGFloat, angle: Double, color: Color) {
        let direction = CGVector(dx: CGFloat(cos(angle)), dy: CGFloat(sin(angle)))
        let normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let tip = CGPoint(x: base.x + direction.dx * length, y: base.y + direction.dy * length + length * 0.18)
        let mid = CGPoint(x: base.x + direction.dx * length * 0.55, y: base.y + direction.dy * length * 0.55)
        var blade = Path()
        blade.move(to: base)
        blade.addQuadCurve(to: tip, control: CGPoint(x: mid.x + normal.dx * length * 0.30, y: mid.y + normal.dy * length * 0.30))
        blade.addQuadCurve(to: base, control: CGPoint(x: mid.x - normal.dx * length * 0.30, y: mid.y - normal.dy * length * 0.30))
        blade.closeSubpath()
        context.fill(blade, with: linear([color, color.opacity(0.8)], base, tip))
        var rib = Path()
        rib.move(to: base)
        rib.addQuadCurve(to: tip, control: mid)
        context.stroke(rib, with: .color(Color.white.opacity(0.3)), lineWidth: max(0.5, length * 0.03))
        for index in 1..<6 {
            let t = CGFloat(index) / 6
            let point = CGPoint(x: base.x + (tip.x - base.x) * t, y: base.y + (tip.y - base.y) * t)
            var vein = Path()
            vein.move(to: point)
            vein.addLine(to: CGPoint(x: point.x + normal.dx * length * 0.16, y: point.y + normal.dy * length * 0.16 + length * 0.04))
            vein.move(to: point)
            vein.addLine(to: CGPoint(x: point.x - normal.dx * length * 0.16, y: point.y - normal.dy * length * 0.16 + length * 0.04))
            context.stroke(vein, with: .color(Color.black.opacity(0.10)), lineWidth: max(0.4, length * 0.015))
        }
    }

    func paintHibiscus(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat, color: Color) {
        for index in 0..<5 {
            let angle = Double(index) / 5 * 2 * .pi - .pi / 2
            let petal = CGPoint(x: center.x + CGFloat(cos(angle)) * size * 0.5, y: center.y + CGFloat(sin(angle)) * size * 0.38)
            context.fill(oval(petal, size * 0.42, size * 0.34), with: radial([color.opacity(0.85), color], center, size))
        }
        context.fill(circle(center, size * 0.18), with: .color(Color(red: 0.80, green: 0.10, blue: 0.30)))
        var pistil = Path()
        pistil.move(to: center)
        pistil.addLine(to: CGPoint(x: center.x + size * 0.3, y: center.y - size * 0.45))
        context.stroke(pistil, with: .color(Color(red: 1.0, green: 0.86, blue: 0.30)), style: round(max(0.5, size * 0.08)))
    }

    func paintLotus(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        let petals: [(Double, CGFloat)] = [(-2.6, 0.8), (-0.54, 0.8), (-2.1, 1.0), (-1.04, 1.0), (-1.57, 1.1)]
        for petal in petals {
            let tip = CGPoint(x: center.x + CGFloat(cos(petal.0)) * size * petal.1, y: center.y + CGFloat(sin(petal.0)) * size * petal.1)
            var shape = Path()
            shape.move(to: center)
            shape.addQuadCurve(to: tip, control: CGPoint(x: (center.x + tip.x) * 0.5 - size * 0.25, y: (center.y + tip.y) * 0.5))
            shape.addQuadCurve(to: center, control: CGPoint(x: (center.x + tip.x) * 0.5 + size * 0.25, y: (center.y + tip.y) * 0.5))
            shape.closeSubpath()
            context.fill(shape, with: linear([.white, Color(red: 1.0, green: 0.56, blue: 0.70)], center, tip))
        }
        context.fill(circle(CGPoint(x: center.x, y: center.y - size * 0.15), size * 0.14), with: .color(Color(red: 1.0, green: 0.86, blue: 0.30)))
    }
}
