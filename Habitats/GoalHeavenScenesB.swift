//
//  GoalHeavenScenesB.swift
//  Math Steps
//
//  Finish-island paradises for the bear, fox, frog, penguin and bunny.
//  See GoalHeavenIsland.swift for the shared coordinate space.
//

import SwiftUI

extension GoalHeavenPainter {
    /// Anchors shared with the particle layer.
    var bearHive: CGPoint { pt(-0.205, -0.39) }

    var foxLanternString: (start: CGPoint, end: CGPoint, sag: CGFloat) {
        (pt(-0.31, -0.615), pt(0.31, -0.615), s(0.05))
    }

    var foxPaperLanterns: [CGPoint] {
        let string = foxLanternString
        let control = CGPoint(x: (string.start.x + string.end.x) * 0.5, y: (string.start.y + string.end.y) * 0.5 + string.sag)
        return [0.14, 0.38, 0.62, 0.86].map { (t: CGFloat) -> CGPoint in
            let a = 1 - t
            let x = a * a * string.start.x + 2 * a * t * control.x + t * t * string.end.x
            let y = a * a * string.start.y + 2 * a * t * control.y + t * t * string.end.y
            return CGPoint(x: x, y: y + s(0.032))
        }
    }

    var foxStoneLanterns: [CGPoint] { [surf(-0.68, 0.22), surf(0.68, 0.22)] }

    var frogPondCenter: CGPoint { CGPoint(x: 0, y: -ry * 0.08) }
    var frogPondRadii: CGSize { CGSize(width: rx * 0.80, height: ry * 0.80) }

    // MARK: - Bear: Honey Hollow

    func paintBearHeaven(in context: inout GraphicsContext) {
        let lawn = [Color(red: 0.62, green: 0.86, blue: 0.40), Color(red: 0.40, green: 0.70, blue: 0.30), Color(red: 0.24, green: 0.50, blue: 0.24)]
        let honeyGold = [Color(red: 1.0, green: 0.88, blue: 0.40), Color(red: 0.98, green: 0.66, blue: 0.12), Color(red: 0.78, green: 0.42, blue: 0.06)]

        paintAura(in: &context, color: Color(red: 1.0, green: 0.88, blue: 0.56), center: pt(0.04, -0.44), radius: s(0.78))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.90, blue: 0.78), front: false)
        paintSatellite(in: &context, center: pt(0.66, -0.42), width: s(0.10), top: lawn[1],
                       rock: [Color(red: 0.56, green: 0.40, blue: 0.28), Color(red: 0.30, green: 0.20, blue: 0.14)])
        paintHoneyPot(&context, base: pt(0.66, -0.425), size: s(0.03))

        paintUnderside(in: &context, material: .init(light: Color(red: 0.62, green: 0.44, blue: 0.30),
                                                     mid: Color(red: 0.46, green: 0.31, blue: 0.21),
                                                     deep: Color(red: 0.27, green: 0.18, blue: 0.14),
                                                     strata: Color(red: 0.18, green: 0.10, blue: 0.06),
                                                     glow: Color(red: 1.0, green: 0.84, blue: 0.56)), seed: 52)
        paintHangingRoots(in: &context, color: Color(red: 0.36, green: 0.24, blue: 0.14), seed: 17, count: 8)
        paintWaterfalls(in: &context, theme: .bear)
        paintSlab(in: &context, surface: lawn,
                  lipMaterial: .init(top: Color(red: 0.50, green: 0.36, blue: 0.24), bottom: Color(red: 0.34, green: 0.23, blue: 0.15),
                                     drips: true, dripColor: Color(red: 0.34, green: 0.62, blue: 0.26)))

        // Background pines with a clear window in the middle for the light.
        let farPine = (Color(red: 0.30, green: 0.52, blue: 0.46), Color(red: 0.46, green: 0.66, blue: 0.56))
        let nearPine = (Color(red: 0.12, green: 0.42, blue: 0.24), Color(red: 0.24, green: 0.58, blue: 0.30))
        for (index, x) in ([-0.44, -0.31, 0.21, 0.33, 0.45] as [CGFloat]).enumerated() {
            paintPine(&context, base: CGPoint(x: s(x), y: backY(s(x)) + s(0.01)), height: s(noise(index, 71, 0.34, 0.44)),
                      width: s(0.15), dark: farPine.0, light: farPine.1, trunk: nil)
        }
        for (index, x) in ([-0.37, 0.27, 0.40] as [CGFloat]).enumerated() {
            paintPine(&context, base: CGPoint(x: s(x), y: backY(s(x)) + s(0.03)), height: s(noise(index, 72, 0.26, 0.32)),
                      width: s(0.13), dark: nearPine.0, light: nearPine.1,
                      trunk: Color(red: 0.36, green: 0.22, blue: 0.14))
        }

        // Fallen leaves on the forest floor.
        for index in 0..<16 {
            let spot = surf(noise(index, 81, -0.85, 0.85), noise(index, 82, -0.5, 0.85))
            if abs(spot.x) < s(0.16) && spot.y > 0 { continue }
            let colors = [Color(red: 0.96, green: 0.62, blue: 0.16), Color(red: 0.86, green: 0.36, blue: 0.14), Color(red: 1.0, green: 0.82, blue: 0.30)]
            context.fill(oval(spot, s(0.009), s(0.004)), with: .color(colors[index % 3].opacity(0.85)))
        }

        // Honey pond spilling over the edge.
        let pond = surf(0.62, 0.30)
        // Stone rim, a darker recessed bank and a glossy, slightly domed
        // honey surface.
        for index in 0..<14 {
            let angle = Double(index) / 14 * 2 * .pi
            let stone = CGPoint(x: pond.x + s(0.122) * CGFloat(cos(angle)), y: pond.y + s(0.040) * CGFloat(sin(angle)))
            let size = s(noise(index, 83, 0.011, 0.016))
            context.fill(oval(stone, size, size * 0.62), with: linear([Color(red: 0.80, green: 0.74, blue: 0.62), Color(red: 0.52, green: 0.46, blue: 0.38)],
                                                                      CGPoint(x: stone.x, y: stone.y - size), CGPoint(x: stone.x, y: stone.y + size)))
        }
        context.fill(oval(pond, s(0.112), s(0.034)), with: .color(Color(red: 0.50, green: 0.28, blue: 0.06)))
        context.fill(oval(CGPoint(x: pond.x, y: pond.y + s(0.003)), s(0.106), s(0.030)),
                     with: radial([Color(red: 1.0, green: 0.86, blue: 0.36), Color(red: 0.96, green: 0.64, blue: 0.12), Color(red: 0.78, green: 0.44, blue: 0.06)],
                                  CGPoint(x: pond.x - s(0.03), y: pond.y - s(0.008)), s(0.11)))
        var swirl = Path()
        swirl.addEllipse(in: CGRect(x: pond.x - s(0.05), y: pond.y - s(0.010), width: s(0.10), height: s(0.022)))
        swirl.addEllipse(in: CGRect(x: pond.x - s(0.025), y: pond.y - s(0.004), width: s(0.05), height: s(0.011)))
        context.stroke(swirl, with: .color(Color(red: 1.0, green: 0.92, blue: 0.60).opacity(0.55)), lineWidth: s(0.003))
        context.fill(oval(CGPoint(x: pond.x - s(0.045), y: pond.y - s(0.014)), s(0.035), s(0.006)), with: .color(Color.white.opacity(0.75)))
        // Honey dribbling over the rim towards the honey fall.
        var spill = Path()
        spill.move(to: CGPoint(x: pond.x + s(0.06), y: pond.y + s(0.022)))
        spill.addQuadCurve(to: CGPoint(x: pond.x + s(0.10), y: pond.y + s(0.07)),
                           control: CGPoint(x: pond.x + s(0.10), y: pond.y + s(0.03)))
        context.stroke(spill, with: .color(Color(red: 0.96, green: 0.66, blue: 0.14)),
                       style: StrokeStyle(lineWidth: s(0.012), lineCap: .round))

        paintHoneyTree(&context)
        for (index, base) in [surf(0.84, -0.30), surf(0.94, 0.05), surf(0.68, -0.58)].enumerated() {
            paintSunflower(&context, base: base, height: s([0.20, 0.15, 0.25][index]), seed: index)
        }

        brush.mushroom(in: &context, base: surf(-0.88, 0.02), height: s(0.04), cap: Color(red: 0.90, green: 0.26, blue: 0.18),
                       capShade: Color(red: 0.64, green: 0.12, blue: 0.10), stem: Color(red: 0.98, green: 0.94, blue: 0.86), speckles: true, seed: 2)
        brush.mushroom(in: &context, base: surf(-0.80, 0.18), height: s(0.028), cap: Color(red: 0.90, green: 0.26, blue: 0.18),
                       capShade: Color(red: 0.64, green: 0.12, blue: 0.10), stem: Color(red: 0.98, green: 0.94, blue: 0.86), speckles: true, seed: 5)

        paintPedestal(in: &context, top: [Color(red: 0.98, green: 0.84, blue: 0.60), Color(red: 0.86, green: 0.64, blue: 0.40)],
                      side: [Color(red: 0.36, green: 0.22, blue: 0.12), Color(red: 0.56, green: 0.36, blue: 0.20), Color(red: 0.32, green: 0.20, blue: 0.11)],
                      trim: Color(red: 0.62, green: 0.40, blue: 0.20), glow: Color(red: 1.0, green: 0.82, blue: 0.40))
        // Growth rings make the dais a freshly cut stump.
        for ring in 1...4 {
            let factor = CGFloat(ring) * 0.17
            context.stroke(oval(CGPoint(x: 0, y: feetY + s(0.002)), s(0.155) * factor, s(0.155) * factor * (ry / rx) * 1.05),
                           with: .color(Color(red: 0.62, green: 0.40, blue: 0.20).opacity(0.45)), lineWidth: s(0.003))
        }

        paintHoneyPot(&context, base: surf(-0.62, 0.36), size: s(0.05))
        paintHoneyPot(&context, base: surf(-0.42, 0.64), size: s(0.034))
        context.fill(oval(surf(-0.34, 0.74), s(0.03), s(0.008)), with: linear(honeyGold, surf(-0.4, 0.7), surf(-0.28, 0.8)))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.90, blue: 0.78), front: true)
    }

    private func paintPine(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat,
                           dark: Color, light: Color, trunk: Color?) {
        if let trunk {
            context.fill(Path(CGRect(x: base.x - width * 0.05, y: base.y - height * 0.2, width: width * 0.1, height: height * 0.2)),
                         with: .color(trunk))
        }
        let tiers = 4
        for tier in 0..<tiers {
            let t = CGFloat(tier) / CGFloat(tiers - 1)
            let bottom = base.y - height * (0.12 + t * 0.52)
            let tierWidth = width * (1 - t * 0.55)
            let apex = CGPoint(x: base.x, y: bottom - height * (0.40 - t * 0.04))
            var skirt = Path()
            skirt.move(to: apex)
            skirt.addQuadCurve(to: CGPoint(x: base.x + tierWidth * 0.5, y: bottom),
                               control: CGPoint(x: base.x + tierWidth * 0.18, y: bottom - height * 0.12))
            // Scalloped hem.
            let scallops = 4
            for index in 0..<scallops {
                let x0 = base.x + tierWidth * (0.5 - CGFloat(index) / CGFloat(scallops))
                let x1 = base.x + tierWidth * (0.5 - CGFloat(index + 1) / CGFloat(scallops))
                skirt.addQuadCurve(to: CGPoint(x: x1, y: bottom),
                                   control: CGPoint(x: (x0 + x1) * 0.5, y: bottom + height * 0.035))
            }
            skirt.addQuadCurve(to: apex, control: CGPoint(x: base.x - tierWidth * 0.18, y: bottom - height * 0.12))
            skirt.closeSubpath()
            context.fill(skirt, with: linear([light, dark], CGPoint(x: base.x - tierWidth * 0.5, y: apex.y),
                                             CGPoint(x: base.x + tierWidth * 0.4, y: bottom)))
            var highlight = context
            highlight.clip(to: skirt)
            highlight.fill(Path(CGRect(x: base.x - tierWidth * 0.5, y: apex.y, width: tierWidth * 0.32, height: bottom - apex.y)),
                           with: .color(Color.white.opacity(0.10)))
        }
    }

    private func paintHoneyTree(_ context: inout GraphicsContext) {
        let base = surf(-0.64, -0.36)
        groundShadow(&context, base, s(0.20))
        let crownColors = [Color(red: 0.22, green: 0.54, blue: 0.24), Color(red: 0.34, green: 0.66, blue: 0.28),
                           Color(red: 0.50, green: 0.76, blue: 0.30), Color(red: 0.86, green: 0.66, blue: 0.20)]
        brush.crown(in: &context, center: pt(-0.36, -0.57), width: s(0.40), height: s(0.24), colors: crownColors, seed: 4, lobes: 6)
        brush.trunk(in: &context, base: base, top: pt(-0.31, -0.46), baseWidth: s(0.085), topWidth: s(0.045),
                    bark: Color(red: 0.42, green: 0.27, blue: 0.16), barkLight: Color(red: 0.60, green: 0.42, blue: 0.26), grain: 4, seed: 3)
        // Roots flaring into the ground.
        for side in [-1.0, 1.0] as [CGFloat] {
            var root = Path()
            root.move(to: CGPoint(x: base.x + side * s(0.03), y: base.y - s(0.04)))
            root.addQuadCurve(to: CGPoint(x: base.x + side * s(0.075), y: base.y + s(0.008)), control: CGPoint(x: base.x + side * s(0.05), y: base.y - s(0.005)))
            context.stroke(root, with: .color(Color(red: 0.42, green: 0.27, blue: 0.16)), style: round(s(0.016)))
        }
        // Branch carrying the hive.
        var branch = Path()
        branch.move(to: pt(-0.31, -0.42))
        branch.addQuadCurve(to: pt(-0.17, -0.475), control: pt(-0.24, -0.47))
        context.stroke(branch, with: .color(Color(red: 0.42, green: 0.27, blue: 0.16)), style: round(s(0.018)))
        brush.crown(in: &context, center: pt(-0.18, -0.52), width: s(0.16), height: s(0.10), colors: crownColors, seed: 8, lobes: 5)
        // Glowing hollow full of honey.
        let hollow = CGPoint(x: base.x + s(0.01), y: base.y - s(0.14))
        context.fill(oval(hollow, s(0.022), s(0.032)), with: .color(Color(red: 0.20, green: 0.10, blue: 0.06)))
        context.fill(oval(CGPoint(x: hollow.x, y: hollow.y + s(0.012)), s(0.017), s(0.016)),
                     with: radial([Color(red: 1.0, green: 0.86, blue: 0.40), Color(red: 0.94, green: 0.58, blue: 0.08)], hollow, s(0.03)))
        var drip = Path()
        drip.move(to: CGPoint(x: hollow.x - s(0.008), y: hollow.y + s(0.026)))
        drip.addQuadCurve(to: CGPoint(x: hollow.x, y: hollow.y + s(0.06)), control: CGPoint(x: hollow.x - s(0.01), y: hollow.y + s(0.05)))
        drip.addQuadCurve(to: CGPoint(x: hollow.x + s(0.008), y: hollow.y + s(0.026)), control: CGPoint(x: hollow.x + s(0.01), y: hollow.y + s(0.05)))
        context.fill(drip, with: .color(Color(red: 0.98, green: 0.70, blue: 0.14)))
        paintBeehive(&context, center: bearHive)
    }

    private func paintBeehive(_ context: inout GraphicsContext, center: CGPoint) {
        var stem = Path()
        stem.move(to: CGPoint(x: center.x, y: center.y - s(0.085)))
        stem.addLine(to: CGPoint(x: center.x, y: center.y - s(0.05)))
        context.stroke(stem, with: .color(Color(red: 0.42, green: 0.27, blue: 0.16)), style: round(s(0.006)))
        let bands: [(CGFloat, CGFloat)] = [(-0.040, 0.022), (-0.020, 0.034), (0.002, 0.040), (0.024, 0.036), (0.044, 0.024)]
        for band in bands {
            let rect = CGRect(x: center.x - s(band.1), y: center.y + s(band.0) - s(0.013), width: s(band.1) * 2, height: s(0.026))
            context.fill(Path(roundedRect: rect, cornerRadius: s(0.013)),
                         with: linear([Color(red: 1.0, green: 0.84, blue: 0.40), Color(red: 0.92, green: 0.62, blue: 0.16), Color(red: 0.70, green: 0.42, blue: 0.10)],
                                      CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.maxY)))
            context.stroke(Path(roundedRect: rect, cornerRadius: s(0.013)), with: .color(Color(red: 0.56, green: 0.32, blue: 0.08).opacity(0.5)),
                           lineWidth: s(0.002))
        }
        context.fill(oval(CGPoint(x: center.x, y: center.y + s(0.012)), s(0.010), s(0.008)), with: .color(Color(red: 0.24, green: 0.12, blue: 0.06)))
        var drip = Path()
        drip.move(to: CGPoint(x: center.x + s(0.012), y: center.y + s(0.052)))
        drip.addQuadCurve(to: CGPoint(x: center.x + s(0.016), y: center.y + s(0.085)), control: CGPoint(x: center.x + s(0.008), y: center.y + s(0.075)))
        drip.addQuadCurve(to: CGPoint(x: center.x + s(0.022), y: center.y + s(0.050)), control: CGPoint(x: center.x + s(0.024), y: center.y + s(0.075)))
        context.fill(drip, with: .color(Color(red: 0.98, green: 0.68, blue: 0.12)))
    }

    func paintHoneyPot(_ context: inout GraphicsContext, base: CGPoint, size: CGFloat) {
        groundShadow(&context, base, size * 1.6)
        var pot = Path()
        pot.move(to: CGPoint(x: base.x - size * 0.42, y: base.y - size * 0.95))
        pot.addQuadCurve(to: CGPoint(x: base.x - size * 0.40, y: base.y), control: CGPoint(x: base.x - size * 0.72, y: base.y - size * 0.45))
        pot.addLine(to: CGPoint(x: base.x + size * 0.40, y: base.y))
        pot.addQuadCurve(to: CGPoint(x: base.x + size * 0.42, y: base.y - size * 0.95), control: CGPoint(x: base.x + size * 0.72, y: base.y - size * 0.45))
        pot.closeSubpath()
        context.fill(pot, with: linear([Color(red: 1.0, green: 0.84, blue: 0.36), Color(red: 0.94, green: 0.60, blue: 0.10), Color(red: 0.70, green: 0.40, blue: 0.06)],
                                       CGPoint(x: base.x - size * 0.6, y: 0), CGPoint(x: base.x + size * 0.6, y: 0)))
        context.fill(Path(roundedRect: CGRect(x: base.x - size * 0.5, y: base.y - size * 1.08, width: size, height: size * 0.18), cornerRadius: size * 0.08),
                     with: .color(Color(red: 0.44, green: 0.24, blue: 0.10)))
        context.fill(Path(roundedRect: CGRect(x: base.x - size * 0.3, y: base.y - size * 0.62, width: size * 0.6, height: size * 0.3), cornerRadius: size * 0.06),
                     with: .color(Color(red: 1.0, green: 0.97, blue: 0.86)))
        context.fill(oval(CGPoint(x: base.x, y: base.y - size * 0.47), size * 0.08, size * 0.07), with: .color(Color(red: 0.94, green: 0.60, blue: 0.10)))
        var drip = Path()
        drip.move(to: CGPoint(x: base.x - size * 0.42, y: base.y - size * 0.92))
        drip.addQuadCurve(to: CGPoint(x: base.x - size * 0.16, y: base.y - size * 0.92), control: CGPoint(x: base.x - size * 0.30, y: base.y - size * 0.62))
        context.fill(drip, with: .color(Color(red: 1.0, green: 0.76, blue: 0.18)))
        context.fill(oval(CGPoint(x: base.x - size * 0.24, y: base.y - size * 0.40), size * 0.06, size * 0.18), with: .color(Color.white.opacity(0.35)))
    }

    private func paintSunflower(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, seed: Int) {
        let head = CGPoint(x: base.x - height * 0.06, y: base.y - height)
        var stem = Path()
        stem.move(to: base)
        stem.addQuadCurve(to: head, control: CGPoint(x: base.x + height * 0.05, y: base.y - height * 0.5))
        context.stroke(stem, with: .color(Color(red: 0.30, green: 0.58, blue: 0.22)), style: round(height * 0.04))
        brush.leaf(in: &context, center: CGPoint(x: base.x + height * 0.10, y: base.y - height * 0.40), length: height * 0.30, angle: -0.4,
                   color: Color(red: 0.34, green: 0.64, blue: 0.24), vein: 0.15)
        brush.leaf(in: &context, center: CGPoint(x: base.x - height * 0.09, y: base.y - height * 0.58), length: height * 0.26, angle: .pi + 0.4,
                   color: Color(red: 0.30, green: 0.58, blue: 0.22), vein: 0.15)
        let radius = height * 0.17
        for index in 0..<14 {
            let angle = Double(index) / 14 * 2 * .pi
            brush.leaf(in: &context, center: CGPoint(x: head.x + CGFloat(cos(angle)) * radius * 0.95, y: head.y + CGFloat(sin(angle)) * radius * 0.95),
                       length: radius * 1.0, angle: angle,
                       color: index.isMultiple(of: 2) ? Color(red: 1.0, green: 0.82, blue: 0.16) : Color(red: 1.0, green: 0.70, blue: 0.10), vein: 0)
        }
        context.fill(circle(head, radius * 0.62), with: radial([Color(red: 0.56, green: 0.32, blue: 0.12), Color(red: 0.30, green: 0.16, blue: 0.08)], head, radius * 0.62))
        for index in 0..<6 {
            let angle = Double(index) / 6 * 2 * .pi + Double(seed)
            context.fill(circle(CGPoint(x: head.x + CGFloat(cos(angle)) * radius * 0.32, y: head.y + CGFloat(sin(angle)) * radius * 0.32), radius * 0.06),
                         with: .color(Color(red: 0.80, green: 0.56, blue: 0.24)))
        }
    }

    // MARK: - Fox: Lantern Shrine

    func paintFoxHeaven(in context: inout GraphicsContext) {
        let lawn = [Color(red: 0.80, green: 0.88, blue: 0.44), Color(red: 0.56, green: 0.72, blue: 0.30), Color(red: 0.36, green: 0.52, blue: 0.22)]
        let vermilion = [Color(red: 1.0, green: 0.46, blue: 0.30), Color(red: 0.90, green: 0.24, blue: 0.14), Color(red: 0.62, green: 0.12, blue: 0.08)]

        paintAura(in: &context, color: Color(red: 1.0, green: 0.80, blue: 0.54), center: pt(0, -0.42), radius: s(0.80))
        // A rising moon behind the shrine.
        let moon = pt(0, -0.36)
        context.fill(circle(moon, s(0.13)), with: radial([Color(red: 1.0, green: 0.98, blue: 0.86), Color(red: 1.0, green: 0.90, blue: 0.66)],
                                                         CGPoint(x: moon.x - s(0.03), y: moon.y - s(0.03)), s(0.16)))
        context.fill(circle(CGPoint(x: moon.x + s(0.04), y: moon.y - s(0.02)), s(0.018)), with: .color(Color(red: 0.96, green: 0.84, blue: 0.62).opacity(0.6)))
        context.fill(circle(CGPoint(x: moon.x - s(0.03), y: moon.y + s(0.04)), s(0.012)), with: .color(Color(red: 0.96, green: 0.84, blue: 0.62).opacity(0.6)))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.86, blue: 0.78), front: false)
        paintSatellite(in: &context, center: pt(-0.65, -0.40), width: s(0.11), top: lawn[1],
                       rock: [Color(red: 0.52, green: 0.40, blue: 0.32), Color(red: 0.28, green: 0.20, blue: 0.18)])
        brush.mushroom(in: &context, base: pt(-0.65, -0.405), height: s(0.03), cap: Color(red: 1.0, green: 0.56, blue: 0.20),
                       capShade: Color(red: 0.80, green: 0.30, blue: 0.10), stem: Color(red: 1.0, green: 0.96, blue: 0.86), speckles: true, seed: 3)

        paintUnderside(in: &context, material: .init(light: Color(red: 0.56, green: 0.42, blue: 0.34),
                                                     mid: Color(red: 0.40, green: 0.28, blue: 0.24),
                                                     deep: Color(red: 0.24, green: 0.16, blue: 0.16),
                                                     strata: Color(red: 0.14, green: 0.08, blue: 0.06),
                                                     glow: Color(red: 1.0, green: 0.76, blue: 0.56)), seed: 63)
        paintHangingRoots(in: &context, color: Color(red: 0.34, green: 0.22, blue: 0.16), seed: 22, count: 8)
        paintWaterfalls(in: &context, theme: .fox)
        paintSlab(in: &context, surface: lawn,
                  lipMaterial: .init(top: Color(red: 0.46, green: 0.32, blue: 0.24), bottom: Color(red: 0.30, green: 0.20, blue: 0.16),
                                     drips: true, dripColor: Color(red: 0.62, green: 0.66, blue: 0.26)))
        // Fallen maple leaves.
        for index in 0..<22 {
            let spot = surf(noise(index, 91, -0.88, 0.88), noise(index, 92, -0.6, 0.85))
            if abs(spot.x) < s(0.16) && spot.y > 0 { continue }
            let colors = [Color(red: 0.92, green: 0.24, blue: 0.12), Color(red: 1.0, green: 0.56, blue: 0.14), Color(red: 1.0, green: 0.78, blue: 0.24)]
            paintMapleLeaf(&context, center: spot, size: s(0.012), angle: Double(index) * 0.9, color: colors[index % 3].opacity(0.9), squash: 0.5)
        }

        paintMapleArch(&context)
        paintTorii(&context, colors: vermilion)
        let string = foxLanternString
        var cord = Path()
        cord.move(to: string.start)
        cord.addQuadCurve(to: string.end, control: CGPoint(x: 0, y: string.start.y + string.sag))
        context.stroke(cord, with: .color(Color(red: 0.30, green: 0.18, blue: 0.12)), lineWidth: s(0.003))
        for lantern in foxPaperLanterns {
            paintPaperLantern(&context, center: lantern, size: s(0.032))
        }

        brush.mushroom(in: &context, base: surf(-0.88, -0.10), height: s(0.036), cap: Color(red: 1.0, green: 0.56, blue: 0.20),
                       capShade: Color(red: 0.80, green: 0.30, blue: 0.10), stem: Color(red: 1.0, green: 0.96, blue: 0.86), speckles: true, seed: 1)
        brush.mushroom(in: &context, base: surf(-0.78, 0.08), height: s(0.026), cap: Color(red: 1.0, green: 0.70, blue: 0.24),
                       capShade: Color(red: 0.84, green: 0.40, blue: 0.12), stem: Color(red: 1.0, green: 0.96, blue: 0.86), speckles: true, seed: 6)
        paintPumpkin(&context, center: surf(0.86, -0.08), size: s(0.036))
        paintPumpkin(&context, center: surf(0.76, 0.12), size: s(0.026))
        for lantern in foxStoneLanterns {
            paintStoneLantern(&context, base: lantern)
        }

        paintPedestal(in: &context, top: [Color(red: 0.94, green: 0.92, blue: 0.88), Color(red: 0.76, green: 0.74, blue: 0.72)],
                      side: [Color(red: 0.42, green: 0.40, blue: 0.40), Color(red: 0.62, green: 0.60, blue: 0.58), Color(red: 0.40, green: 0.38, blue: 0.38)],
                      trim: vermilion[1], glow: Color(red: 1.0, green: 0.78, blue: 0.46))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.86, blue: 0.78), front: true)
    }

    func paintMapleLeaf(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat, angle: Double, color: Color, squash: CGFloat = 1) {
        var leaf = Path()
        let points = 10
        for index in 0..<points {
            let a = angle + Double(index) / Double(points) * 2 * .pi
            let r = index.isMultiple(of: 2) ? size : size * 0.48
            let point = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r * squash)
            if index == 0 { leaf.move(to: point) } else { leaf.addLine(to: point) }
        }
        leaf.closeSubpath()
        context.fill(leaf, with: .color(color))
    }

    private func paintMapleArch(_ context: inout GraphicsContext) {
        let bark = Color(red: 0.36, green: 0.22, blue: 0.16)
        for side in [-1.0, 1.0] as [CGFloat] {
            let base = surf(side * 0.74, -0.36)
            groundShadow(&context, base, s(0.16))
            var trunk = Path()
            trunk.move(to: CGPoint(x: base.x - s(0.024), y: base.y))
            trunk.addQuadCurve(to: CGPoint(x: side * s(0.22), y: s(-0.60)), control: CGPoint(x: base.x - side * s(0.02), y: s(-0.36)))
            trunk.addLine(to: CGPoint(x: side * s(0.25), y: s(-0.60)))
            trunk.addQuadCurve(to: CGPoint(x: base.x + s(0.024), y: base.y), control: CGPoint(x: base.x + side * s(0.0), y: s(-0.34)))
            trunk.closeSubpath()
            context.fill(trunk, with: linear([bark, Color(red: 0.54, green: 0.36, blue: 0.24), bark],
                                             CGPoint(x: base.x - s(0.03), y: 0), CGPoint(x: base.x + s(0.03), y: 0)))
            var bough = Path()
            bough.move(to: CGPoint(x: side * s(0.33), y: s(-0.40)))
            bough.addQuadCurve(to: CGPoint(x: side * s(0.46), y: s(-0.50)), control: CGPoint(x: side * s(0.42), y: s(-0.42)))
            context.stroke(bough, with: .color(bark), style: round(s(0.012)))
        }
        let crimson = Color(red: 0.86, green: 0.20, blue: 0.12)
        let orange = Color(red: 0.98, green: 0.48, blue: 0.12)
        let amber = Color(red: 1.0, green: 0.70, blue: 0.20)
        let gold = Color(red: 1.0, green: 0.86, blue: 0.36)
        let clusters: [(CGFloat, CGFloat, CGFloat, [Color])] = [
            (-0.46, -0.48, 0.20, [crimson, orange, amber]), (0.46, -0.48, 0.20, [orange, crimson, amber]),
            (-0.38, -0.62, 0.26, [orange, amber, crimson]), (0.38, -0.62, 0.26, [crimson, amber, orange]),
            (-0.18, -0.72, 0.26, [amber, orange, gold]), (0.18, -0.72, 0.26, [orange, gold, amber]),
            (0, -0.76, 0.22, [gold, amber, orange])
        ]
        for (index, cluster) in clusters.enumerated() {
            brush.crown(in: &context, center: pt(cluster.0, cluster.1), width: s(cluster.2), height: s(cluster.2 * 0.62),
                        colors: cluster.3, seed: index * 4 + 1, lobes: 6)
        }
        for index in 0..<26 {
            let center = pt(noise(index, 95, -0.50, 0.50), noise(index, 96, -0.82, -0.46))
            if abs(center.x) < s(0.12) && center.y > s(-0.60) { continue }
            paintMapleLeaf(&context, center: center, size: s(0.013), angle: Double(index), color: [crimson, gold, orange][index % 3])
        }
    }

    private func paintTorii(_ context: inout GraphicsContext, colors: [Color]) {
        let postTop = s(-0.46)
        for side in [-1.0, 1.0] as [CGFloat] {
            let x = side * s(0.19)
            let base = backY(x) + s(0.016)
            groundShadow(&context, CGPoint(x: x, y: base), s(0.08))
            var post = Path()
            post.move(to: CGPoint(x: x - s(0.017), y: base))
            post.addLine(to: CGPoint(x: x - s(0.013), y: postTop))
            post.addLine(to: CGPoint(x: x + s(0.013), y: postTop))
            post.addLine(to: CGPoint(x: x + s(0.017), y: base))
            post.closeSubpath()
            context.fill(post, with: linear(colors, CGPoint(x: x - s(0.017), y: 0), CGPoint(x: x + s(0.017), y: 0)))
            context.fill(Path(CGRect(x: x - s(0.021), y: base - s(0.02), width: s(0.042), height: s(0.02))), with: .color(Color(red: 0.16, green: 0.12, blue: 0.12)))
        }
        // Nuki (tie beam) and plaque.
        context.fill(Path(CGRect(x: s(-0.25), y: s(-0.405), width: s(0.50), height: s(0.022))),
                     with: vertical([colors[0], colors[1]], s(-0.405), s(-0.383)))
        context.fill(Path(CGRect(x: s(-0.012), y: s(-0.455), width: s(0.024), height: s(0.05))), with: .color(colors[1]))
        context.fill(Path(roundedRect: CGRect(x: s(-0.026), y: s(-0.448), width: s(0.052), height: s(0.034)), cornerRadius: s(0.004)),
                     with: .color(Color(red: 0.18, green: 0.12, blue: 0.10)))
        context.stroke(Path(roundedRect: CGRect(x: s(-0.026), y: s(-0.448), width: s(0.052), height: s(0.034)), cornerRadius: s(0.004)),
                       with: .color(Color(red: 1.0, green: 0.82, blue: 0.36)), lineWidth: s(0.003))
        // Kasagi (curved top beam).
        var beam = Path()
        beam.move(to: pt(-0.31, -0.505))
        beam.addQuadCurve(to: pt(0.31, -0.505), control: pt(0, -0.465))
        beam.addLine(to: pt(0.29, -0.475))
        beam.addQuadCurve(to: pt(-0.29, -0.475), control: pt(0, -0.44))
        beam.closeSubpath()
        context.fill(beam, with: vertical([colors[0], colors[1], colors[2]], s(-0.50), s(-0.45)))
        var cap = Path()
        cap.move(to: pt(-0.325, -0.522))
        cap.addQuadCurve(to: pt(0.325, -0.522), control: pt(0, -0.48))
        cap.addLine(to: pt(0.31, -0.502))
        cap.addQuadCurve(to: pt(-0.31, -0.502), control: pt(0, -0.462))
        cap.closeSubpath()
        context.fill(cap, with: .color(Color(red: 0.16, green: 0.12, blue: 0.12)))
    }

    private func paintPaperLantern(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        var cord = Path()
        cord.move(to: CGPoint(x: center.x, y: center.y - size * 1.0))
        cord.addLine(to: CGPoint(x: center.x, y: center.y - size * 0.6))
        context.stroke(cord, with: .color(Color(red: 0.30, green: 0.18, blue: 0.12)), lineWidth: s(0.0025))
        context.fill(circle(center, size * 1.3), with: radial([Color(red: 1.0, green: 0.80, blue: 0.40).opacity(0.6), Color.clear], center, size * 1.3))
        let body = oval(center, size * 0.42, size * 0.55)
        context.fill(body, with: radial([Color(red: 1.0, green: 0.92, blue: 0.60), Color(red: 1.0, green: 0.50, blue: 0.20), Color(red: 0.86, green: 0.24, blue: 0.10)],
                                        center, size * 0.6))
        for rib in [-0.25, 0.0, 0.25] as [CGFloat] {
            var line = Path()
            line.move(to: CGPoint(x: center.x - size * 0.40, y: center.y + size * rib * 1.6))
            line.addQuadCurve(to: CGPoint(x: center.x + size * 0.40, y: center.y + size * rib * 1.6),
                              control: CGPoint(x: center.x, y: center.y + size * rib * 1.6 + size * 0.06))
            context.stroke(line, with: .color(Color(red: 0.70, green: 0.20, blue: 0.08).opacity(0.5)), lineWidth: s(0.0018))
        }
        for cap in [-0.55, 0.55] as [CGFloat] {
            context.fill(Path(roundedRect: CGRect(x: center.x - size * 0.22, y: center.y + size * cap - size * 0.06, width: size * 0.44, height: size * 0.12),
                              cornerRadius: size * 0.03), with: .color(Color(red: 0.20, green: 0.12, blue: 0.10)))
        }
    }

    private func paintStoneLantern(_ context: inout GraphicsContext, base: CGPoint) {
        groundShadow(&context, base, s(0.08))
        let stone = [Color(red: 0.86, green: 0.84, blue: 0.80), Color(red: 0.64, green: 0.62, blue: 0.60), Color(red: 0.46, green: 0.44, blue: 0.44)]
        func slab(_ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
            let rect = CGRect(x: base.x - width * 0.5, y: base.y - y - height, width: width, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: height * 0.2), with: linear(stone, CGPoint(x: rect.minX, y: 0), CGPoint(x: rect.maxX, y: 0)))
        }
        slab(0, s(0.05), s(0.012))
        slab(s(0.012), s(0.018), s(0.045))
        slab(s(0.057), s(0.044), s(0.01))
        // Fire box.
        let box = CGRect(x: base.x - s(0.018), y: base.y - s(0.097), width: s(0.036), height: s(0.03))
        context.fill(Path(box), with: linear(stone, CGPoint(x: box.minX, y: 0), CGPoint(x: box.maxX, y: 0)))
        context.fill(Path(CGRect(x: box.minX + s(0.008), y: box.minY + s(0.006), width: s(0.02), height: s(0.018))),
                     with: radial([Color(red: 1.0, green: 0.96, blue: 0.70), Color(red: 1.0, green: 0.62, blue: 0.20)], CGPoint(x: box.midX, y: box.midY), s(0.016)))
        var roof = Path()
        roof.move(to: CGPoint(x: base.x - s(0.04), y: base.y - s(0.097)))
        roof.addQuadCurve(to: CGPoint(x: base.x, y: base.y - s(0.122)), control: CGPoint(x: base.x - s(0.02), y: base.y - s(0.102)))
        roof.addQuadCurve(to: CGPoint(x: base.x + s(0.04), y: base.y - s(0.097)), control: CGPoint(x: base.x + s(0.02), y: base.y - s(0.102)))
        roof.closeSubpath()
        context.fill(roof, with: linear(stone, CGPoint(x: base.x - s(0.04), y: 0), CGPoint(x: base.x + s(0.04), y: 0)))
        context.fill(circle(CGPoint(x: base.x, y: base.y - s(0.127)), s(0.007)), with: .color(stone[1]))
    }

    private func paintPumpkin(_ context: inout GraphicsContext, center: CGPoint, size: CGFloat) {
        groundShadow(&context, CGPoint(x: center.x, y: center.y + size * 0.4), size * 2)
        for lobe in [-0.5, 0.5, -0.2, 0.2, 0.0] as [CGFloat] {
            context.fill(oval(CGPoint(x: center.x + lobe * size, y: center.y), size * 0.5, size * 0.55),
                         with: linear([Color(red: 1.0, green: 0.66, blue: 0.24), Color(red: 0.90, green: 0.42, blue: 0.08)],
                                      CGPoint(x: center.x + lobe * size - size * 0.4, y: center.y - size * 0.5),
                                      CGPoint(x: center.x + lobe * size + size * 0.4, y: center.y + size * 0.5)))
        }
        var stem = Path()
        stem.move(to: CGPoint(x: center.x, y: center.y - size * 0.5))
        stem.addQuadCurve(to: CGPoint(x: center.x + size * 0.15, y: center.y - size * 0.8), control: CGPoint(x: center.x, y: center.y - size * 0.75))
        context.stroke(stem, with: .color(Color(red: 0.30, green: 0.40, blue: 0.16)), style: round(size * 0.14))
    }

    // MARK: - Frog: Lotus Lagoon

    func paintFrogHeaven(in context: inout GraphicsContext) {
        let lawn = [Color(red: 0.66, green: 0.92, blue: 0.44), Color(red: 0.40, green: 0.76, blue: 0.30), Color(red: 0.20, green: 0.54, blue: 0.24)]
        let pondColors = [Color(red: 0.56, green: 0.92, blue: 0.86), Color(red: 0.24, green: 0.68, blue: 0.70), Color(red: 0.12, green: 0.46, blue: 0.54)]

        paintAura(in: &context, color: Color(red: 0.92, green: 1.0, blue: 0.84), center: pt(0, -0.34), radius: s(0.78))
        paintCloudCollar(in: &context, tint: Color(red: 0.84, green: 0.96, blue: 0.90), front: false)
        paintGiantLotus(&context, center: pt(0, -0.13), radius: s(0.38))
        paintSatellite(in: &context, center: pt(0.65, -0.42), width: s(0.11), top: lawn[1],
                       rock: [Color(red: 0.46, green: 0.52, blue: 0.44), Color(red: 0.22, green: 0.28, blue: 0.26)])
        brush.reedStand(in: &context, base: pt(0.655, -0.425), height: s(0.06), spread: s(0.03), count: 4,
                        stem: Color(red: 0.24, green: 0.54, blue: 0.22), stemLight: Color(red: 0.42, green: 0.70, blue: 0.30),
                        headColor: Color(red: 0.50, green: 0.30, blue: 0.16), seed: 3)

        paintUnderside(in: &context, material: .init(light: Color(red: 0.52, green: 0.58, blue: 0.48),
                                                     mid: Color(red: 0.36, green: 0.42, blue: 0.36),
                                                     deep: Color(red: 0.20, green: 0.26, blue: 0.24),
                                                     strata: Color(red: 0.70, green: 0.86, blue: 0.62),
                                                     glow: Color(red: 0.84, green: 1.0, blue: 0.80)), seed: 74)
        paintHangingRoots(in: &context, color: Color(red: 0.30, green: 0.58, blue: 0.28), seed: 31, count: 10)
        paintWaterfalls(in: &context, theme: .frog)
        paintSlab(in: &context, surface: lawn,
                  lipMaterial: .init(top: Color(red: 0.42, green: 0.40, blue: 0.32), bottom: Color(red: 0.28, green: 0.28, blue: 0.22),
                                     drips: true, dripColor: Color(red: 0.32, green: 0.66, blue: 0.28)))

        // The pond fills most of the island.
        let pond = oval(frogPondCenter, frogPondRadii.width, frogPondRadii.height)
        context.fill(oval(CGPoint(x: frogPondCenter.x, y: frogPondCenter.y + s(0.004)), frogPondRadii.width * 1.02, frogPondRadii.height * 1.06),
                     with: .color(Color(red: 0.46, green: 0.44, blue: 0.36)))
        context.fill(pond, with: linear(pondColors, CGPoint(x: 0, y: frogPondCenter.y - frogPondRadii.height),
                                        CGPoint(x: 0, y: frogPondCenter.y + frogPondRadii.height)))
        var pondDetail = context
        pondDetail.clip(to: pond)
        pondDetail.fill(oval(CGPoint(x: -rx * 0.2, y: frogPondCenter.y - ry * 0.4), rx * 0.5, ry * 0.3),
                        with: radial([Color.white.opacity(0.35), Color.white.opacity(0)], CGPoint(x: -rx * 0.2, y: frogPondCenter.y - ry * 0.4), rx * 0.5))
        brush.waterGlints(in: &pondDetail, bounds: CGRect(x: -rx * 0.6, y: frogPondCenter.y - ry * 0.6, width: rx * 1.2, height: ry * 1.1),
                          count: 6, color: .white, seed: 9)
        // Stepping stones around the rim.
        for index in 0..<9 {
            let angle = Double(index) / 9 * 2 * .pi + 0.2
            let spot = CGPoint(x: CGFloat(cos(angle)) * frogPondRadii.width * 1.0, y: frogPondCenter.y + CGFloat(sin(angle)) * frogPondRadii.height * 1.02)
            if abs(spot.x) < s(0.18) && spot.y > 0 { continue }
            context.fill(oval(spot, s(0.02), s(0.008)), with: linear([Color(red: 0.80, green: 0.80, blue: 0.74), Color(red: 0.52, green: 0.52, blue: 0.48)],
                                                                    CGPoint(x: spot.x, y: spot.y - s(0.008)), CGPoint(x: spot.x, y: spot.y + s(0.008))))
        }
        let pads: [(CGFloat, CGFloat, CGFloat, Bool)] = [(-0.58, -0.30, 0.032, true), (-0.36, 0.10, 0.026, false), (-0.70, 0.20, 0.022, false),
                                                         (0.42, -0.36, 0.030, true), (0.62, 0.05, 0.026, false), (0.30, -0.66, 0.022, false),
                                                         (-0.20, -0.62, 0.024, true), (0.48, 0.42, 0.020, false)]
        for (index, pad) in pads.enumerated() {
            let center = surf(pad.0, pad.1)
            paintLilyPad(&context, center: center, radius: s(pad.2), rotation: Double(index) * 1.3)
            if pad.3 { paintLotus(&context, center: CGPoint(x: center.x + s(0.006), y: center.y - s(0.004)), size: s(pad.2 * 0.95)) }
        }

        paintWillow(&context)
        brush.reedStand(in: &context, base: surf(0.80, -0.42), height: s(0.20), spread: s(0.06), count: 7,
                        stem: Color(red: 0.24, green: 0.54, blue: 0.22), stemLight: Color(red: 0.42, green: 0.70, blue: 0.30),
                        headColor: Color(red: 0.50, green: 0.30, blue: 0.16), seed: 7)
        brush.reedStand(in: &context, base: surf(0.92, 0.02), height: s(0.15), spread: s(0.05), count: 6,
                        stem: Color(red: 0.24, green: 0.54, blue: 0.22), stemLight: Color(red: 0.42, green: 0.70, blue: 0.30),
                        headColor: Color(red: 0.50, green: 0.30, blue: 0.16), seed: 12)
        brush.mushroom(in: &context, base: surf(0.66, 0.66), height: s(0.04), cap: Color(red: 0.92, green: 0.20, blue: 0.20),
                       capShade: Color(red: 0.66, green: 0.10, blue: 0.12), stem: Color(red: 1.0, green: 0.96, blue: 0.88), speckles: true, seed: 4)
        brush.mushroom(in: &context, base: surf(0.56, 0.80), height: s(0.026), cap: Color(red: 0.92, green: 0.20, blue: 0.20),
                       capShade: Color(red: 0.66, green: 0.10, blue: 0.12), stem: Color(red: 1.0, green: 0.96, blue: 0.88), speckles: true, seed: 8)
        brush.rock(in: &context, center: surf(-0.62, 0.62), radius: s(0.026), light: Color(red: 0.76, green: 0.78, blue: 0.70),
                   dark: Color(red: 0.42, green: 0.46, blue: 0.40), seed: 5)

        // Giant lily pad dais.
        let dais = CGPoint(x: 0, y: feetY + s(0.002))
        context.fill(oval(CGPoint(x: 0, y: dais.y + s(0.01)), s(0.24), s(0.07)),
                     with: radial([Color(red: 0.86, green: 1.0, blue: 0.70).opacity(0.7), Color.clear], CGPoint(x: 0, y: dais.y + s(0.01)), s(0.24)))
        paintLilyPad(&context, center: CGPoint(x: 0, y: dais.y + s(0.008)), radius: s(0.165), rotation: 1.2, thickness: s(0.012))
        paintLotus(&context, center: CGPoint(x: s(-0.135), y: dais.y - s(0.006)), size: s(0.034))
        paintCloudCollar(in: &context, tint: Color(red: 0.84, green: 0.96, blue: 0.90), front: true)
    }

    func paintLilyPad(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat, rotation: Double, thickness: CGFloat = 0) {
        let squash = (ry / rx) * 1.05
        func padPath(_ c: CGPoint) -> Path {
            var pad = Path()
            let samples = 28
            let notch = 0.30
            for index in 0...samples {
                let a = rotation + notch + (2 * .pi - notch * 2) * Double(index) / Double(samples)
                let point = CGPoint(x: c.x + CGFloat(cos(a)) * radius, y: c.y + CGFloat(sin(a)) * radius * squash)
                if index == 0 { pad.move(to: point) } else { pad.addLine(to: point) }
            }
            pad.addLine(to: c)
            pad.closeSubpath()
            return pad
        }
        if thickness > 0 {
            context.fill(padPath(CGPoint(x: center.x, y: center.y + thickness)), with: .color(Color(red: 0.16, green: 0.42, blue: 0.20)))
        }
        let top = padPath(center)
        context.fill(top, with: linear([Color(red: 0.62, green: 0.90, blue: 0.40), Color(red: 0.30, green: 0.68, blue: 0.28)],
                                       CGPoint(x: center.x - radius, y: center.y - radius * squash), CGPoint(x: center.x + radius, y: center.y + radius * squash)))
        for index in 0..<7 {
            let a = rotation + 0.7 + Double(index) * 0.8
            var vein = Path()
            vein.move(to: center)
            vein.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * radius * 0.85, y: center.y + CGFloat(sin(a)) * radius * 0.85 * squash))
            context.stroke(vein, with: .color(Color(red: 0.84, green: 1.0, blue: 0.66).opacity(0.45)), lineWidth: max(0.5, radius * 0.03))
        }
        context.stroke(top, with: .color(Color(red: 0.18, green: 0.48, blue: 0.20).opacity(0.6)), lineWidth: max(0.5, radius * 0.03))
    }

    private func paintGiantLotus(_ context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        context.fill(circle(center, radius * 1.3), with: radial([Color.white.opacity(0.7), Color(red: 1.0, green: 0.86, blue: 0.94).opacity(0)],
                                                                CGPoint(x: center.x, y: center.y - radius * 0.4), radius * 1.3))
        func petal(_ angle: Double, _ length: CGFloat, _ width: CGFloat, _ colors: [Color]) {
            let direction = CGVector(dx: CGFloat(cos(angle)), dy: CGFloat(sin(angle)))
            let normal = CGVector(dx: -direction.dy, dy: direction.dx)
            let tip = CGPoint(x: center.x + direction.dx * length, y: center.y + direction.dy * length)
            let mid = CGPoint(x: center.x + direction.dx * length * 0.55, y: center.y + direction.dy * length * 0.55)
            var shape = Path()
            shape.move(to: center)
            shape.addQuadCurve(to: tip, control: CGPoint(x: mid.x + normal.dx * width, y: mid.y + normal.dy * width))
            shape.addQuadCurve(to: center, control: CGPoint(x: mid.x - normal.dx * width, y: mid.y - normal.dy * width))
            shape.closeSubpath()
            context.fill(shape, with: linear(colors, center, tip))
            context.stroke(shape, with: .color(Color.white.opacity(0.55)), lineWidth: s(0.003))
            var vein = Path()
            vein.move(to: CGPoint(x: center.x + direction.dx * length * 0.2, y: center.y + direction.dy * length * 0.2))
            vein.addLine(to: CGPoint(x: center.x + direction.dx * length * 0.85, y: center.y + direction.dy * length * 0.85))
            context.stroke(vein, with: .color(Color(red: 0.96, green: 0.50, blue: 0.70).opacity(0.35)), lineWidth: s(0.003))
        }
        let outer = [Color(red: 1.0, green: 0.96, blue: 0.98), Color(red: 1.0, green: 0.72, blue: 0.84), Color(red: 0.94, green: 0.42, blue: 0.66)]
        let inner = [Color.white, Color(red: 1.0, green: 0.84, blue: 0.92), Color(red: 1.0, green: 0.60, blue: 0.76)]
        for index in 0..<9 {
            let angle = Double.pi * (1.06 + 0.88 * Double(index) / 8)
            petal(angle, radius, radius * 0.22, outer)
        }
        for index in 0..<7 {
            let angle = Double.pi * (1.14 + 0.72 * Double(index) / 6)
            petal(angle, radius * 0.74, radius * 0.18, inner)
        }
        for index in 0..<5 {
            let angle = Double.pi * (1.22 + 0.56 * Double(index) / 4)
            petal(angle, radius * 0.48, radius * 0.13, [Color.white, Color(red: 1.0, green: 0.90, blue: 0.94)])
        }
    }

    private func paintWillow(_ context: inout GraphicsContext) {
        let base = surf(-0.76, -0.30)
        groundShadow(&context, base, s(0.18))
        brush.trunk(in: &context, base: base, top: pt(-0.36, -0.46), baseWidth: s(0.06), topWidth: s(0.03),
                    bark: Color(red: 0.40, green: 0.32, blue: 0.24), barkLight: Color(red: 0.58, green: 0.48, blue: 0.36), grain: 3, seed: 6)
        let crownColors = [Color(red: 0.42, green: 0.70, blue: 0.30), Color(red: 0.56, green: 0.82, blue: 0.36), Color(red: 0.34, green: 0.60, blue: 0.26)]
        brush.crown(in: &context, center: pt(-0.38, -0.54), width: s(0.36), height: s(0.15), colors: crownColors, seed: 12, lobes: 6)
        for index in 0..<15 {
            let x = s(-0.54) + CGFloat(index) * s(0.024)
            let top = CGPoint(x: x, y: s(-0.53) + abs(x - s(-0.38)) * 0.25)
            let length = s(noise(index, 33, 0.18, 0.30))
            var strand = Path()
            strand.move(to: top)
            strand.addQuadCurve(to: CGPoint(x: x + s(0.012), y: top.y + length), control: CGPoint(x: x - s(0.012), y: top.y + length * 0.55))
            context.stroke(strand, with: .color(crownColors[index % 3]), style: round(s(0.009)))
            context.stroke(strand, with: .color(Color.white.opacity(0.14)), style: round(s(0.003)))
        }
    }

    // MARK: - Penguin: Ice Palace

    func paintPenguinHeaven(in context: inout GraphicsContext) {
        let snow = [Color.white, Color(red: 0.92, green: 0.96, blue: 1.0), Color(red: 0.74, green: 0.84, blue: 0.96)]
        paintAura(in: &context, color: Color(red: 0.80, green: 0.92, blue: 1.0), center: pt(0, -0.50), radius: s(0.80))
        paintCloudCollar(in: &context, tint: Color(red: 0.80, green: 0.88, blue: 1.0), front: false)
        paintSatellite(in: &context, center: pt(-0.64, -0.40), width: s(0.11), top: .white,
                       rock: [Color(red: 0.70, green: 0.84, blue: 0.96), Color(red: 0.30, green: 0.44, blue: 0.70)])
        paintIceCrystal(&context, base: pt(-0.64, -0.405), height: s(0.06), width: s(0.02), tilt: -0.1)

        paintUnderside(in: &context, material: .init(light: Color(red: 0.78, green: 0.90, blue: 1.0),
                                                     mid: Color(red: 0.48, green: 0.64, blue: 0.86),
                                                     deep: Color(red: 0.22, green: 0.32, blue: 0.58),
                                                     strata: Color.white,
                                                     glow: Color(red: 0.70, green: 0.90, blue: 1.0)), seed: 85)
        // Glowing crystals growing out of the underside.
        for (index, spec) in [(-0.30, 0.05, 2.9), (0.10, 0.075, 3.3), (0.32, 0.045, 3.0), (-0.08, 0.06, 3.15)].enumerated() {
            let x = s(CGFloat(spec.0))
            let root = CGPoint(x: x, y: floorDepth * pow(max(0, 1 - pow(x / rx, 2)), 0.62) * 0.82)
            paintIceCrystal(&context, base: root, height: s(CGFloat(spec.1)), width: s(0.022), tilt: spec.2 - .pi + Double(index) * 0.02)
        }
        var roots: [CGPoint] = []
        for index in 0..<22 {
            let x = -rx * 0.9 + CGFloat(index) / 21 * rx * 1.8
            roots.append(CGPoint(x: x, y: frontY(x) + lip * 0.85))
        }
        brush.icicles(in: &context, roots: roots, maxLength: s(0.09), color: Color(red: 0.94, green: 0.98, blue: 1.0),
                      tip: Color(red: 0.62, green: 0.84, blue: 1.0).opacity(0.5), seed: 4)
        paintSlab(in: &context, surface: snow,
                  lipMaterial: .init(top: Color(red: 0.86, green: 0.94, blue: 1.0), bottom: Color(red: 0.58, green: 0.74, blue: 0.94),
                                     drips: true, dripColor: .white),
                  rim: .white)
        // Blue snow shadows and sparkle dust.
        brush.surfaceStrokes(in: &context, bounds: CGRect(x: -rx * 0.7, y: -ry * 0.5, width: rx * 1.4, height: ry * 1.2),
                             count: 10, color: Color(red: 0.62, green: 0.76, blue: 0.96).opacity(0.4), highlight: nil, lengthRange: 0.04...0.08, seed: 5)

        paintIcePalace(&context)
        paintIceCrystal(&context, base: surf(-0.86, -0.20), height: s(0.12), width: s(0.035), tilt: -0.25)
        paintIceCrystal(&context, base: surf(-0.80, -0.30), height: s(0.08), width: s(0.03), tilt: 0.15)
        paintIceCrystal(&context, base: surf(0.88, -0.22), height: s(0.11), width: s(0.034), tilt: 0.25)
        paintIceCrystal(&context, base: surf(0.80, -0.36), height: s(0.07), width: s(0.026), tilt: -0.1)
        paintIgloo(&context, center: surf(-0.62, 0.10))
        paintSnowman(&context, base: surf(0.66, 0.02))

        // Fishing hole with a fresh catch.
        let hole = surf(0.42, 0.66)
        context.fill(oval(hole, s(0.04), s(0.012)), with: .color(Color(red: 0.70, green: 0.84, blue: 0.98)))
        context.fill(oval(CGPoint(x: hole.x, y: hole.y + s(0.002)), s(0.032), s(0.009)),
                     with: linear([Color(red: 0.10, green: 0.30, blue: 0.56), Color(red: 0.24, green: 0.56, blue: 0.84)],
                                  CGPoint(x: 0, y: hole.y - s(0.01)), CGPoint(x: 0, y: hole.y + s(0.01))))
        brush.fish(in: &context, center: CGPoint(x: hole.x + s(0.06), y: hole.y - s(0.004)), length: s(0.04),
                   color: Color(red: 0.36, green: 0.70, blue: 0.94), facingRight: false)

        paintPedestal(in: &context, top: [.white, Color(red: 0.84, green: 0.94, blue: 1.0), Color(red: 0.66, green: 0.84, blue: 1.0)],
                      side: [Color(red: 0.40, green: 0.62, blue: 0.90), Color(red: 0.72, green: 0.88, blue: 1.0), Color(red: 0.36, green: 0.56, blue: 0.86)],
                      trim: .white, glow: Color(red: 0.74, green: 0.92, blue: 1.0))
        paintCloudCollar(in: &context, tint: Color(red: 0.80, green: 0.88, blue: 1.0), front: true)
    }

    func paintIceCrystal(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, width: CGFloat, tilt: Double) {
        var local = context
        local.translateBy(x: base.x, y: base.y)
        local.rotate(by: .radians(tilt))
        var shard = Path()
        shard.move(to: CGPoint(x: -width * 0.5, y: 0))
        shard.addLine(to: CGPoint(x: -width * 0.5, y: -height * 0.72))
        shard.addLine(to: CGPoint(x: 0, y: -height))
        shard.addLine(to: CGPoint(x: width * 0.5, y: -height * 0.72))
        shard.addLine(to: CGPoint(x: width * 0.5, y: 0))
        shard.closeSubpath()
        local.fill(shard, with: linear([Color.white, Color(red: 0.70, green: 0.90, blue: 1.0), Color(red: 0.44, green: 0.70, blue: 0.96)],
                                       CGPoint(x: -width * 0.5, y: -height), CGPoint(x: width * 0.5, y: 0)))
        var facet = Path()
        facet.move(to: CGPoint(x: 0, y: -height))
        facet.addLine(to: CGPoint(x: width * 0.05, y: 0))
        local.stroke(facet, with: .color(Color.white.opacity(0.7)), lineWidth: max(0.5, width * 0.08))
        local.stroke(shard, with: .color(Color.white.opacity(0.6)), lineWidth: max(0.5, width * 0.05))
    }

    private func paintIcePalace(_ context: inout GraphicsContext) {
        let ice = [Color.white, Color(red: 0.80, green: 0.92, blue: 1.0), Color(red: 0.56, green: 0.76, blue: 0.98)]
        let roof = [Color(red: 0.86, green: 0.96, blue: 1.0), Color(red: 0.40, green: 0.66, blue: 0.96), Color(red: 0.24, green: 0.44, blue: 0.84)]
        let ground = backY(0) + s(0.02)
        // Glow behind the keep.
        context.fill(oval(pt(0, -0.40), s(0.34), s(0.40)), with: radial([Color.white.opacity(0.8), Color(red: 0.80, green: 0.92, blue: 1.0).opacity(0)],
                                                                        pt(0, -0.40), s(0.40)))
        func tower(_ x: CGFloat, _ width: CGFloat, _ top: CGFloat, _ spire: CGFloat, _ flag: Bool) {
            let base = backY(s(x)) + s(0.02)
            let rect = CGRect(x: s(x) - width * 0.5, y: s(top), width: width, height: base - s(top))
            context.fill(Path(rect), with: linear(ice, CGPoint(x: rect.minX, y: 0), CGPoint(x: rect.maxX, y: 0)))
            context.stroke(Path(rect), with: .color(Color.white.opacity(0.8)), lineWidth: s(0.002))
            var facet = Path()
            facet.move(to: CGPoint(x: rect.midX + width * 0.12, y: rect.minY))
            facet.addLine(to: CGPoint(x: rect.midX + width * 0.12, y: rect.maxY))
            context.stroke(facet, with: .color(Color.white.opacity(0.6)), lineWidth: s(0.003))
            var cone = Path()
            cone.move(to: CGPoint(x: rect.minX - width * 0.12, y: rect.minY))
            cone.addLine(to: CGPoint(x: rect.midX, y: s(spire)))
            cone.addLine(to: CGPoint(x: rect.maxX + width * 0.12, y: rect.minY))
            cone.closeSubpath()
            context.fill(cone, with: linear(roof, CGPoint(x: rect.minX, y: s(spire)), CGPoint(x: rect.maxX, y: rect.minY)))
            var coneLight = Path()
            coneLight.move(to: CGPoint(x: rect.midX, y: s(spire)))
            coneLight.addLine(to: CGPoint(x: rect.minX - width * 0.12, y: rect.minY))
            coneLight.addLine(to: CGPoint(x: rect.midX - width * 0.1, y: rect.minY))
            coneLight.closeSubpath()
            context.fill(coneLight, with: .color(Color.white.opacity(0.35)))
            // Glowing window.
            let window = CGRect(x: rect.midX - width * 0.16, y: rect.minY + width * 0.4, width: width * 0.32, height: width * 0.5)
            var arch = Path()
            arch.move(to: CGPoint(x: window.minX, y: window.maxY))
            arch.addLine(to: CGPoint(x: window.minX, y: window.minY + window.width * 0.5))
            arch.addArc(center: CGPoint(x: window.midX, y: window.minY + window.width * 0.5), radius: window.width * 0.5,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            arch.addLine(to: CGPoint(x: window.maxX, y: window.maxY))
            arch.closeSubpath()
            context.fill(arch, with: vertical([Color(red: 1.0, green: 0.96, blue: 0.76), Color(red: 0.70, green: 0.90, blue: 1.0)], window.minY, window.maxY))
            if flag {
                var pole = Path()
                pole.move(to: CGPoint(x: rect.midX, y: s(spire)))
                pole.addLine(to: CGPoint(x: rect.midX, y: s(spire) - s(0.045)))
                context.stroke(pole, with: .color(Color(red: 0.30, green: 0.40, blue: 0.60)), lineWidth: s(0.003))
                var pennant = Path()
                pennant.move(to: CGPoint(x: rect.midX, y: s(spire) - s(0.045)))
                pennant.addLine(to: CGPoint(x: rect.midX + s(0.04), y: s(spire) - s(0.035)))
                pennant.addLine(to: CGPoint(x: rect.midX, y: s(spire) - s(0.025)))
                pennant.closeSubpath()
                context.fill(pennant, with: .color(character.color))
            }
        }
        tower(-0.33, s(0.06), -0.27, -0.40, false)
        tower(0.33, s(0.06), -0.27, -0.40, false)
        // Curtain wall with crenellations.
        let wallTop = s(-0.25)
        let wall = CGRect(x: s(-0.31), y: wallTop, width: s(0.62), height: ground - wallTop)
        context.fill(Path(wall), with: vertical([Color(red: 0.90, green: 0.96, blue: 1.0), Color(red: 0.66, green: 0.82, blue: 0.98)], wallTop, ground))
        for index in 0..<13 {
            let x = wall.minX + CGFloat(index) * wall.width / 12.5
            context.fill(Path(CGRect(x: x, y: wallTop - s(0.016), width: s(0.022), height: s(0.016))), with: .color(Color(red: 0.92, green: 0.97, blue: 1.0)))
        }
        for row in 1..<4 {
            var seam = Path()
            let y = wallTop + (ground - wallTop) * CGFloat(row) / 4
            seam.move(to: CGPoint(x: wall.minX, y: y))
            seam.addLine(to: CGPoint(x: wall.maxX, y: y))
            context.stroke(seam, with: .color(Color(red: 0.56, green: 0.74, blue: 0.96).opacity(0.5)), lineWidth: s(0.002))
        }
        tower(-0.19, s(0.08), -0.40, -0.58, true)
        tower(0.19, s(0.08), -0.40, -0.58, true)
        tower(0, s(0.12), -0.47, -0.80, true)
        // Grand gate behind the dais.
        var gate = Path()
        gate.move(to: CGPoint(x: s(-0.055), y: ground))
        gate.addLine(to: CGPoint(x: s(-0.055), y: s(-0.24)))
        gate.addArc(center: CGPoint(x: 0, y: s(-0.24)), radius: s(0.055), startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        gate.addLine(to: CGPoint(x: s(0.055), y: ground))
        gate.closeSubpath()
        context.fill(gate, with: vertical([Color(red: 1.0, green: 0.98, blue: 0.86), Color(red: 0.74, green: 0.90, blue: 1.0)], s(-0.30), ground))
        context.stroke(gate, with: .color(Color.white), lineWidth: s(0.005))
        // Star atop the spire.
        sparkle(in: &context, center: pt(0, -0.84), radius: s(0.035), color: Color(red: 1.0, green: 0.96, blue: 0.70))
    }

    private func paintIgloo(_ context: inout GraphicsContext, center: CGPoint) {
        groundShadow(&context, center, s(0.20), opacity: 0.16)
        let radius = s(0.085)
        var dome = Path()
        dome.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        dome.closeSubpath()
        context.fill(dome, with: linear([.white, Color(red: 0.86, green: 0.93, blue: 1.0), Color(red: 0.62, green: 0.76, blue: 0.94)],
                                        CGPoint(x: center.x - radius, y: center.y - radius), CGPoint(x: center.x + radius, y: center.y)))
        var blocks = context
        blocks.clip(to: dome)
        for row in 1..<4 {
            let y = center.y - radius * CGFloat(row) * 0.26
            var seam = Path()
            seam.move(to: CGPoint(x: center.x - radius, y: y))
            seam.addLine(to: CGPoint(x: center.x + radius, y: y))
            blocks.stroke(seam, with: .color(Color(red: 0.62, green: 0.76, blue: 0.94).opacity(0.7)), lineWidth: s(0.002))
            for column in 0..<6 {
                let x = center.x - radius + CGFloat(column) * radius * 0.4 + (row.isMultiple(of: 2) ? radius * 0.2 : 0)
                var joint = Path()
                joint.move(to: CGPoint(x: x, y: y))
                joint.addLine(to: CGPoint(x: x, y: y + radius * 0.26))
                blocks.stroke(joint, with: .color(Color(red: 0.62, green: 0.76, blue: 0.94).opacity(0.6)), lineWidth: s(0.002))
            }
        }
        // Entrance tunnel facing the centre.
        let entrance = CGPoint(x: center.x + radius * 0.6, y: center.y)
        var tunnel = Path()
        tunnel.move(to: CGPoint(x: entrance.x - radius * 0.32, y: entrance.y))
        tunnel.addArc(center: entrance, radius: radius * 0.32, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        tunnel.closeSubpath()
        context.fill(tunnel, with: linear([.white, Color(red: 0.80, green: 0.90, blue: 1.0)], CGPoint(x: entrance.x, y: entrance.y - radius * 0.3), entrance))
        var hole = Path()
        hole.move(to: CGPoint(x: entrance.x - radius * 0.2, y: entrance.y))
        hole.addArc(center: entrance, radius: radius * 0.2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        hole.closeSubpath()
        context.fill(hole, with: vertical([Color(red: 1.0, green: 0.86, blue: 0.50), Color(red: 0.96, green: 0.62, blue: 0.24)], entrance.y - radius * 0.2, entrance.y))
    }

    private func paintSnowman(_ context: inout GraphicsContext, base: CGPoint) {
        groundShadow(&context, base, s(0.10), opacity: 0.16)
        let snowShade = [Color.white, Color(red: 0.84, green: 0.92, blue: 1.0)]
        let balls: [(CGFloat, CGFloat)] = [(0.032, 0.03), (0.084, 0.024), (0.124, 0.018)]
        for ball in balls {
            let center = CGPoint(x: base.x, y: base.y - s(ball.0))
            context.fill(circle(center, s(ball.1)), with: linear(snowShade, CGPoint(x: center.x - s(ball.1), y: center.y - s(ball.1)),
                                                                 CGPoint(x: center.x + s(ball.1), y: center.y + s(ball.1))))
        }
        let head = CGPoint(x: base.x, y: base.y - s(0.124))
        // Scarf.
        context.fill(Path(roundedRect: CGRect(x: base.x - s(0.022), y: base.y - s(0.108), width: s(0.044), height: s(0.01)), cornerRadius: s(0.005)),
                     with: .color(character.color))
        context.fill(Path(roundedRect: CGRect(x: base.x + s(0.006), y: base.y - s(0.104), width: s(0.01), height: s(0.03)), cornerRadius: s(0.004)),
                     with: .color(character.deepColor))
        // Face.
        for dx in [-0.006, 0.006] as [CGFloat] {
            context.fill(circle(CGPoint(x: head.x + s(dx), y: head.y - s(0.004)), s(0.0028)), with: .color(Color(red: 0.12, green: 0.12, blue: 0.16)))
        }
        var nose = Path()
        nose.move(to: CGPoint(x: head.x, y: head.y + s(0.001)))
        nose.addLine(to: CGPoint(x: head.x - s(0.02), y: head.y + s(0.004)))
        nose.addLine(to: CGPoint(x: head.x, y: head.y + s(0.006)))
        nose.closeSubpath()
        context.fill(nose, with: .color(Color(red: 1.0, green: 0.56, blue: 0.16)))
        // Hat.
        context.fill(Path(CGRect(x: head.x - s(0.02), y: head.y - s(0.018), width: s(0.04), height: s(0.005))), with: .color(Color(red: 0.14, green: 0.16, blue: 0.24)))
        context.fill(Path(CGRect(x: head.x - s(0.013), y: head.y - s(0.042), width: s(0.026), height: s(0.025))), with: .color(Color(red: 0.14, green: 0.16, blue: 0.24)))
        context.fill(Path(CGRect(x: head.x - s(0.013), y: head.y - s(0.024), width: s(0.026), height: s(0.004))), with: .color(character.color))
        // Stick arms.
        var arms = Path()
        arms.move(to: CGPoint(x: base.x - s(0.02), y: base.y - s(0.088)))
        arms.addLine(to: CGPoint(x: base.x - s(0.05), y: base.y - s(0.11)))
        arms.move(to: CGPoint(x: base.x + s(0.02), y: base.y - s(0.088)))
        arms.addLine(to: CGPoint(x: base.x + s(0.052), y: base.y - s(0.104)))
        context.stroke(arms, with: .color(Color(red: 0.42, green: 0.28, blue: 0.18)), style: round(s(0.0035)))
    }

    // MARK: - Bunny: Rainbow Meadow

    func paintBunnyHeaven(in context: inout GraphicsContext) {
        let lawn = [Color(red: 0.74, green: 0.96, blue: 0.56), Color(red: 0.50, green: 0.84, blue: 0.40), Color(red: 0.30, green: 0.64, blue: 0.32)]
        let pink = Color(red: 1.0, green: 0.62, blue: 0.74)

        paintAura(in: &context, color: Color(red: 1.0, green: 0.90, blue: 0.94), center: pt(0, -0.40), radius: s(0.80))
        paintRainbow(&context, center: pt(0, -0.06), outer: s(0.56), bandWidth: s(0.026))
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.86, blue: 0.92), front: false)
        paintPuffCloud(in: &context, center: pt(-0.46, -0.12), width: s(0.22), height: s(0.09), seed: 51, shade: Color(red: 1.0, green: 0.86, blue: 0.92))
        paintPuffCloud(in: &context, center: pt(0.46, -0.12), width: s(0.22), height: s(0.09), seed: 53, shade: Color(red: 1.0, green: 0.86, blue: 0.92))
        paintSatellite(in: &context, center: pt(0.66, -0.44), width: s(0.10), top: lawn[1],
                       rock: [Color(red: 0.66, green: 0.48, blue: 0.40), Color(red: 0.36, green: 0.24, blue: 0.22)])
        paintCarrot(&context, top: pt(0.66, -0.455), length: s(0.035), planted: true)

        let soil = GoalHeavenPainter.RockMaterial(light: Color(red: 0.70, green: 0.50, blue: 0.40),
                                                  mid: Color(red: 0.54, green: 0.36, blue: 0.30),
                                                  deep: Color(red: 0.34, green: 0.22, blue: 0.22),
                                                  strata: Color(red: 0.24, green: 0.14, blue: 0.12),
                                                  glow: Color(red: 1.0, green: 0.84, blue: 0.90))
        paintUnderside(in: &context, material: soil, seed: 96)
        // Carrots growing down through the soil cross-section.
        var soilClip = context
        soilClip.clip(to: undersidePath(seed: 96))
        for (index, x) in ([-0.34, -0.22, -0.08, 0.06, 0.20, 0.31] as [CGFloat]).enumerated() {
            let top = CGPoint(x: s(x), y: frontY(s(x)) + lip * 1.05)
            paintCarrotRoot(&soilClip, top: top, length: s(noise(index, 13, 0.07, 0.12)), width: s(0.022))
        }
        paintHangingRoots(in: &context, color: Color(red: 0.46, green: 0.30, blue: 0.22), seed: 41, count: 5)
        paintWaterfalls(in: &context, theme: .bunny)
        paintSlab(in: &context, surface: lawn,
                  lipMaterial: .init(top: Color(red: 0.62, green: 0.44, blue: 0.36), bottom: Color(red: 0.46, green: 0.30, blue: 0.26),
                                     drips: true, dripColor: Color(red: 0.44, green: 0.78, blue: 0.36)))

        // Rolling pastel hills behind the meadow.
        var hills = Path()
        hills.move(to: pt(-0.47, -0.02))
        hills.addQuadCurve(to: pt(-0.24, -0.20), control: pt(-0.40, -0.22))
        hills.addQuadCurve(to: pt(0.0, -0.13), control: pt(-0.10, -0.18))
        hills.addQuadCurve(to: pt(0.22, -0.19), control: pt(0.12, -0.20))
        hills.addQuadCurve(to: pt(0.47, -0.02), control: pt(0.40, -0.22))
        hills.addLine(to: pt(0.47, 0))
        hills.addLine(to: pt(-0.47, 0))
        hills.closeSubpath()
        var hillClip = context
        hillClip.clip(to: Path(CGRect(x: -rx, y: s(-0.4), width: rx * 2, height: s(0.4) - ry * 0.25)))
        hillClip.fill(hills, with: vertical([Color(red: 0.80, green: 0.98, blue: 0.70), Color(red: 0.56, green: 0.86, blue: 0.48)], s(-0.2), 0))
        for (index, spot) in [pt(-0.30, -0.15), pt(-0.20, -0.17), pt(0.16, -0.16), pt(0.26, -0.15), pt(-0.08, -0.13)].enumerated() {
            hillClip.fill(circle(spot, s(0.006)), with: .color([Color.white, pink, Color(red: 1.0, green: 0.86, blue: 0.30)][index % 3]))
        }

        paintBlossomTree(&context, base: surf(-0.74, -0.28))
        paintBurrow(&context, center: surf(0.62, -0.40))
        paintCarrotPatch(&context, center: surf(-0.56, 0.36))

        let tulipColors = [Color(red: 1.0, green: 0.36, blue: 0.48), Color(red: 1.0, green: 0.80, blue: 0.24), Color(red: 0.74, green: 0.52, blue: 1.0),
                           Color(red: 1.0, green: 0.56, blue: 0.74)]
        for (index, spot) in [surf(0.70, 0.30), surf(0.82, 0.10), surf(0.58, 0.55), surf(0.88, -0.10)].enumerated() {
            paintTulip(&context, base: spot, height: s(0.06 + CGFloat(index % 2) * 0.015), color: tulipColors[index])
        }
        for (index, spot) in [surf(-0.88, -0.02), surf(-0.30, 0.78), surf(0.36, 0.80)].enumerated() {
            brush.flower(in: &context, base: spot, height: s(0.035), stem: Color(red: 0.30, green: 0.62, blue: 0.28), petal: .white,
                         heart: Color(red: 1.0, green: 0.80, blue: 0.20), petals: 8, seed: index + 4)
        }
        brush.mushroom(in: &context, base: surf(0.46, 0.70), height: s(0.03), cap: pink, capShade: Color(red: 0.88, green: 0.40, blue: 0.56),
                       stem: Color(red: 1.0, green: 0.96, blue: 0.92), speckles: true, seed: 9)

        paintPedestal(in: &context, top: [.white, Color(red: 1.0, green: 0.92, blue: 0.95)],
                      side: [Color(red: 0.86, green: 0.40, blue: 0.54), Color(red: 1.0, green: 0.66, blue: 0.76), Color(red: 0.82, green: 0.36, blue: 0.50)],
                      trim: Color(red: 1.0, green: 0.84, blue: 0.30), glow: Color(red: 1.0, green: 0.84, blue: 0.92))
        for index in 0..<16 {
            let angle = Double(index) / 16 * 2 * .pi
            let petal = CGPoint(x: CGFloat(cos(angle)) * s(0.17), y: feetY + s(0.002) + CGFloat(sin(angle)) * s(0.048))
            if petal.y < feetY - s(0.02) { continue }
            context.fill(oval(petal, s(0.02), s(0.008)), with: .color(Color.white.opacity(0.95)))
        }
        paintCloudCollar(in: &context, tint: Color(red: 1.0, green: 0.86, blue: 0.92), front: true)
    }

    private func paintRainbow(_ context: inout GraphicsContext, center: CGPoint, outer: CGFloat, bandWidth: CGFloat) {
        let colors = [Color(red: 1.0, green: 0.42, blue: 0.46), Color(red: 1.0, green: 0.64, blue: 0.30), Color(red: 1.0, green: 0.88, blue: 0.36),
                      Color(red: 0.52, green: 0.86, blue: 0.44), Color(red: 0.36, green: 0.72, blue: 1.0), Color(red: 0.56, green: 0.48, blue: 0.96),
                      Color(red: 0.80, green: 0.50, blue: 0.96)]
        for (index, color) in colors.enumerated() {
            var arc = Path()
            arc.addArc(center: center, radius: outer - bandWidth * (CGFloat(index) + 0.5), startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            context.stroke(arc, with: .color(color.opacity(0.85)), lineWidth: bandWidth * 1.02)
        }
        var shine = Path()
        shine.addArc(center: center, radius: outer - bandWidth * 0.2, startAngle: .degrees(195), endAngle: .degrees(250), clockwise: false)
        context.stroke(shine, with: .color(Color.white.opacity(0.5)), style: round(bandWidth * 0.25))
    }

    func paintCarrot(_ context: inout GraphicsContext, top: CGPoint, length: CGFloat, planted: Bool) {
        if planted {
            for (index, angle) in ([-2.0, -1.57, -1.15] as [Double]).enumerated() {
                brush.leaf(in: &context, center: CGPoint(x: top.x + CGFloat(cos(angle)) * length * 0.4, y: top.y + CGFloat(sin(angle)) * length * 0.4),
                           length: length * 0.8, angle: angle, color: index == 1 ? Color(red: 0.36, green: 0.72, blue: 0.28) : Color(red: 0.26, green: 0.60, blue: 0.24),
                           vein: 0.1)
            }
            context.fill(oval(CGPoint(x: top.x, y: top.y + length * 0.05), length * 0.24, length * 0.12),
                         with: .color(Color(red: 1.0, green: 0.56, blue: 0.14)))
        }
    }

    private func paintCarrotRoot(_ context: inout GraphicsContext, top: CGPoint, length: CGFloat, width: CGFloat) {
        var root = Path()
        root.move(to: CGPoint(x: top.x - width * 0.5, y: top.y))
        root.addQuadCurve(to: CGPoint(x: top.x + width * 0.1, y: top.y + length), control: CGPoint(x: top.x - width * 0.35, y: top.y + length * 0.7))
        root.addQuadCurve(to: CGPoint(x: top.x + width * 0.5, y: top.y), control: CGPoint(x: top.x + width * 0.4, y: top.y + length * 0.6))
        root.closeSubpath()
        context.fill(root, with: linear([Color(red: 1.0, green: 0.70, blue: 0.26), Color(red: 0.94, green: 0.46, blue: 0.10)],
                                        CGPoint(x: top.x - width * 0.5, y: top.y), CGPoint(x: top.x + width * 0.5, y: top.y)))
        for index in 1..<4 {
            let y = top.y + length * CGFloat(index) * 0.22
            var ring = Path()
            ring.move(to: CGPoint(x: top.x - width * 0.3 + CGFloat(index) * width * 0.05, y: y))
            ring.addLine(to: CGPoint(x: top.x + width * 0.05, y: y + width * 0.08))
            context.stroke(ring, with: .color(Color(red: 0.70, green: 0.30, blue: 0.06).opacity(0.5)), lineWidth: max(0.5, width * 0.06))
        }
    }

    private func paintBlossomTree(_ context: inout GraphicsContext, base: CGPoint) {
        groundShadow(&context, base, s(0.18))
        brush.trunk(in: &context, base: base, top: pt(-0.34, -0.44), baseWidth: s(0.05), topWidth: s(0.025),
                    bark: Color(red: 0.46, green: 0.30, blue: 0.26), barkLight: Color(red: 0.64, green: 0.46, blue: 0.40), grain: 3, seed: 2)
        var branch = Path()
        branch.move(to: pt(-0.35, -0.38))
        branch.addQuadCurve(to: pt(-0.22, -0.48), control: pt(-0.26, -0.40))
        context.stroke(branch, with: .color(Color(red: 0.46, green: 0.30, blue: 0.26)), style: round(s(0.010)))
        let blossom = [Color(red: 1.0, green: 0.78, blue: 0.86), Color(red: 1.0, green: 0.66, blue: 0.78), Color(red: 1.0, green: 0.88, blue: 0.92)]
        brush.crown(in: &context, center: pt(-0.38, -0.55), width: s(0.34), height: s(0.22), colors: blossom, seed: 6, lobes: 6)
        brush.crown(in: &context, center: pt(-0.22, -0.52), width: s(0.16), height: s(0.11), colors: blossom, seed: 11, lobes: 5)
        for index in 0..<18 {
            let spot = pt(noise(index, 77, -0.52, -0.16), noise(index, 78, -0.66, -0.44))
            context.fill(circle(spot, s(0.006)), with: .color(index.isMultiple(of: 2) ? .white : Color(red: 0.96, green: 0.46, blue: 0.62)))
        }
    }

    private func paintBurrow(_ context: inout GraphicsContext, center: CGPoint) {
        groundShadow(&context, center, s(0.28), opacity: 0.16)
        var mound = Path()
        mound.move(to: CGPoint(x: center.x - s(0.15), y: center.y))
        mound.addQuadCurve(to: CGPoint(x: center.x + s(0.15), y: center.y), control: CGPoint(x: center.x, y: center.y - s(0.30)))
        mound.closeSubpath()
        context.fill(mound, with: linear([Color(red: 0.70, green: 0.94, blue: 0.54), Color(red: 0.42, green: 0.76, blue: 0.36)],
                                         CGPoint(x: center.x - s(0.1), y: center.y - s(0.15)), CGPoint(x: center.x + s(0.12), y: center.y)))
        // Round door with frame.
        let door = CGPoint(x: center.x - s(0.01), y: center.y - s(0.045))
        context.fill(circle(door, s(0.046)), with: .color(Color(red: 0.56, green: 0.40, blue: 0.30)))
        var clipped = context
        clipped.clip(to: Path(CGRect(x: door.x - s(0.05), y: door.y - s(0.05), width: s(0.1), height: s(0.05) + s(0.045))))
        clipped.fill(circle(door, s(0.038)), with: linear([Color(red: 1.0, green: 0.82, blue: 0.40), Color(red: 0.94, green: 0.64, blue: 0.22)],
                                                          CGPoint(x: door.x - s(0.04), y: 0), CGPoint(x: door.x + s(0.04), y: 0)))
        for plank in [-0.02, 0.0, 0.02] as [CGFloat] {
            var line = Path()
            line.move(to: CGPoint(x: door.x + s(plank), y: door.y - s(0.036)))
            line.addLine(to: CGPoint(x: door.x + s(plank), y: door.y + s(0.045)))
            clipped.stroke(line, with: .color(Color(red: 0.70, green: 0.44, blue: 0.16).opacity(0.5)), lineWidth: s(0.002))
        }
        context.fill(circle(CGPoint(x: door.x + s(0.022), y: door.y + s(0.012)), s(0.005)), with: .color(Color(red: 0.62, green: 0.36, blue: 0.10)))
        context.fill(Path(CGRect(x: door.x - s(0.06), y: center.y - s(0.002), width: s(0.12), height: s(0.004))), with: .color(Color(red: 0.56, green: 0.40, blue: 0.30)))
        // Round window and flowers on the roof.
        let window = CGPoint(x: center.x + s(0.07), y: center.y - s(0.08))
        context.fill(circle(window, s(0.018)), with: .color(Color(red: 0.56, green: 0.40, blue: 0.30)))
        context.fill(circle(window, s(0.013)), with: radial([Color(red: 1.0, green: 0.96, blue: 0.70), Color(red: 1.0, green: 0.80, blue: 0.40)], window, s(0.013)))
        for (index, spot) in [CGPoint(x: center.x - s(0.06), y: center.y - s(0.11)), CGPoint(x: center.x + s(0.01), y: center.y - s(0.145)),
                              CGPoint(x: center.x + s(0.08), y: center.y - s(0.11))].enumerated() {
            brush.flower(in: &context, base: spot, height: s(0.03), stem: Color(red: 0.30, green: 0.62, blue: 0.28),
                         petal: [Color(red: 1.0, green: 0.62, blue: 0.74), .white, Color(red: 1.0, green: 0.86, blue: 0.30)][index],
                         heart: Color(red: 1.0, green: 0.70, blue: 0.20), petals: 6, seed: index)
        }
    }

    private func paintCarrotPatch(_ context: inout GraphicsContext, center: CGPoint) {
        let soil = oval(center, s(0.12), s(0.036))
        context.fill(soil, with: linear([Color(red: 0.56, green: 0.38, blue: 0.28), Color(red: 0.42, green: 0.28, blue: 0.22)],
                                        CGPoint(x: 0, y: center.y - s(0.03)), CGPoint(x: 0, y: center.y + s(0.03))))
        for row in 0..<2 {
            for column in 0..<4 {
                let spot = CGPoint(x: center.x - s(0.075) + CGFloat(column) * s(0.05) + (row == 1 ? s(0.022) : 0),
                                   y: center.y - s(0.012) + CGFloat(row) * s(0.022))
                paintCarrot(&context, top: spot, length: s(0.04), planted: true)
            }
        }
        // Watering can.
        let can = CGPoint(x: center.x + s(0.15), y: center.y + s(0.02))
        groundShadow(&context, can, s(0.06), opacity: 0.18)
        context.fill(Path(roundedRect: CGRect(x: can.x - s(0.02), y: can.y - s(0.035), width: s(0.04), height: s(0.035)), cornerRadius: s(0.008)),
                     with: linear([Color(red: 0.56, green: 0.86, blue: 0.96), Color(red: 0.26, green: 0.62, blue: 0.84)],
                                  CGPoint(x: can.x - s(0.02), y: 0), CGPoint(x: can.x + s(0.02), y: 0)))
        var spout = Path()
        spout.move(to: CGPoint(x: can.x - s(0.018), y: can.y - s(0.012)))
        spout.addLine(to: CGPoint(x: can.x - s(0.045), y: can.y - s(0.04)))
        context.stroke(spout, with: .color(Color(red: 0.26, green: 0.62, blue: 0.84)), style: round(s(0.006)))
        var handle = Path()
        handle.addArc(center: CGPoint(x: can.x + s(0.004), y: can.y - s(0.035)), radius: s(0.014), startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        context.stroke(handle, with: .color(Color(red: 0.26, green: 0.62, blue: 0.84)), style: round(s(0.004)))
    }

    private func paintTulip(_ context: inout GraphicsContext, base: CGPoint, height: CGFloat, color: Color) {
        let head = CGPoint(x: base.x, y: base.y - height)
        var stem = Path()
        stem.move(to: base)
        stem.addQuadCurve(to: head, control: CGPoint(x: base.x + height * 0.1, y: base.y - height * 0.5))
        context.stroke(stem, with: .color(Color(red: 0.30, green: 0.62, blue: 0.28)), style: round(height * 0.06))
        brush.leaf(in: &context, center: CGPoint(x: base.x - height * 0.12, y: base.y - height * 0.3), length: height * 0.5, angle: -2.0,
                   color: Color(red: 0.34, green: 0.68, blue: 0.30), vein: 0.12)
        var cup = Path()
        cup.move(to: CGPoint(x: head.x - height * 0.16, y: head.y - height * 0.18))
        cup.addLine(to: CGPoint(x: head.x - height * 0.08, y: head.y - height * 0.08))
        cup.addLine(to: CGPoint(x: head.x, y: head.y - height * 0.22))
        cup.addLine(to: CGPoint(x: head.x + height * 0.08, y: head.y - height * 0.08))
        cup.addLine(to: CGPoint(x: head.x + height * 0.16, y: head.y - height * 0.18))
        cup.addQuadCurve(to: CGPoint(x: head.x, y: head.y + height * 0.04), control: CGPoint(x: head.x + height * 0.18, y: head.y))
        cup.addQuadCurve(to: CGPoint(x: head.x - height * 0.16, y: head.y - height * 0.18), control: CGPoint(x: head.x - height * 0.18, y: head.y))
        cup.closeSubpath()
        context.fill(cup, with: linear([color.opacity(0.75), color], CGPoint(x: head.x - height * 0.16, y: head.y - height * 0.2),
                                       CGPoint(x: head.x + height * 0.16, y: head.y)))
    }
}
