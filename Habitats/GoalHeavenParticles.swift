//
//  GoalHeavenParticles.swift
//  Math Steps
//
//  The living layer of the finish islands: twinkles, drifting creatures,
//  falling water and the confetti burst that greets the character. Every
//  particle is a pure function of time and a stable seed, so nothing is
//  stored and the layer can be paused or skipped at any frame.
//

import SwiftUI

extension GoalHeavenPainter {
    private func phase(_ time: Double, period: Double, offset: CGFloat) -> CGFloat {
        let value = time / period + Double(offset)
        return CGFloat(value - floor(value))
    }

    private func fadeInOut(_ t: CGFloat, edge: CGFloat = 0.15) -> Double {
        Double(min(1, min(t / edge, (1 - t) / edge)))
    }

    // MARK: Shared

    func paintTwinkles(in context: inout GraphicsContext, theme: GoalHeavenTheme, time: Double, celebration: Double?) {
        let color: Color
        switch theme {
        case .lion, .bear, .fox: color = Color(red: 1.0, green: 0.94, blue: 0.70)
        case .penguin: color = Color(red: 0.90, green: 0.97, blue: 1.0)
        default: color = .white
        }
        let boost: CGFloat = celebration == nil ? 1 : 1.5
        for index in 0..<18 {
            let x = noise(index, 201, -0.62, 0.62)
            let y = noise(index, 202, -0.92, -0.08)
            if abs(x) < 0.14 && y > -0.36 { continue }
            let speed = Double(noise(index, 203, 1.2, 2.6))
            let wave = sin(time * speed + Double(index) * 1.7)
            let strength = CGFloat(max(0, wave))
            guard strength > 0.05 else { continue }
            let radius = s(noise(index, 204, 0.008, 0.016)) * strength * boost
            sparkle(in: &context, center: pt(x, y), radius: radius, color: color.opacity(Double(strength)))
        }
    }

    func paintWaterfallShimmer(in context: inout GraphicsContext, theme: GoalHeavenTheme, time: Double) {
        for (fallIndex, fall) in waterfalls(for: theme).enumerated() {
            let top = fall.top ?? (frontY(fall.x) + lip * 0.4)
            let length = fall.bottom - top
            for dash in 0..<4 {
                let t = phase(time, period: 1.1, offset: CGFloat(dash) / 4 + CGFloat(fallIndex) * 0.13)
                let y = top + length * t * 0.8
                let lane = (CGFloat(dash % 3) - 1) * fall.width * 0.25
                var streak = Path()
                streak.move(to: CGPoint(x: fall.x + lane, y: y))
                streak.addLine(to: CGPoint(x: fall.x + lane, y: y + length * 0.10))
                context.stroke(streak, with: .color(Color.white.opacity(0.75 * Double(1 - t))), style: round(max(0.8, fall.width * 0.12)))
            }
            // Mist where the fall dissolves.
            let mist = 1 + 0.08 * CGFloat(sin(time * 2 + Double(fallIndex)))
            let bottom = CGPoint(x: fall.x, y: fall.top == nil ? fall.bottom - length * 0.12 : fall.bottom)
            context.fill(oval(bottom, fall.width * 1.2 * mist, fall.width * 0.45 * mist),
                         with: radial([Color.white.opacity(0.55), Color.white.opacity(0)], bottom, fall.width * 1.2 * mist))
        }
    }

    func paintConfetti(in context: inout GraphicsContext, age: Double) {
        guard age < 3.2 else { return }
        let palette = [character.color, character.tintColor, Color(red: 1.0, green: 0.84, blue: 0.24),
                       Color(red: 1.0, green: 0.46, blue: 0.56), .white, Color(red: 0.40, green: 0.76, blue: 1.0)]
        let origin = CGPoint(x: 0, y: feetY - s(0.08))
        let fade = age > 2.2 ? 1 - (age - 2.2) : 1
        // Paper confetti: a fast launch that air drag stops quickly, then a
        // slow fluttering sink.
        let drag: CGFloat = 3.2
        for index in 0..<96 {
            let angle = -Double.pi / 2 + Double(noise(index, 301, -1.15, 1.15))
            let speed = s(noise(index, 302, 1.1, 2.3))
            let delay = Double(noise(index, 303, 0, 0.14))
            let t = CGFloat(max(0, age - delay))
            guard t > 0 else { continue }
            let launch = speed / drag * (1 - CGFloat(exp(-Double(drag * t))))
            let sink = s(noise(index, 305, 0.12, 0.22)) * t
            let sway = CGFloat(sin(Double(t) * Double(noise(index, 306, 3, 6)) + Double(index))) * s(0.022) * min(1, t)
            let x = origin.x + CGFloat(cos(angle)) * launch + sway
            let y = origin.y + CGFloat(sin(angle)) * launch + sink
            let spin = Double(t) * Double(noise(index, 304, 4, 11))
            let width = s(noise(index, 307, 0.018, 0.026))
            let height = width * 0.55 * CGFloat(abs(cos(spin)))
            var piece = context
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(spin * 0.4))
            piece.fill(Path(CGRect(x: -width * 0.5, y: -height * 0.5, width: width, height: max(0.5, height))),
                       with: .color(palette[index % palette.count].opacity(fade)))
        }
        // Expanding ring of light from the dais at the moment of landing.
        if age < 0.9 {
            let progress = CGFloat(age / 0.9)
            let center = CGPoint(x: 0, y: feetY)
            context.stroke(oval(center, s(0.16 + 0.30 * progress), s(0.05 + 0.09 * progress)),
                           with: .color(Color.white.opacity(Double(1 - progress) * 0.9)), lineWidth: s(0.012) * (1 - progress) + 0.5)
        }
    }

    func paintAurora(in context: inout GraphicsContext, time: Double) {
        let bands: [(Color, CGFloat, Double)] = [(Color(red: 0.40, green: 1.0, blue: 0.74), -0.86, 0.0),
                                                 (Color(red: 0.36, green: 0.86, blue: 1.0), -0.76, 1.3),
                                                 (Color(red: 0.74, green: 0.56, blue: 1.0), -0.94, 2.4)]
        for band in bands {
            var ribbon = Path()
            let samples = 24
            var tops: [CGPoint] = []
            for index in 0...samples {
                let t = CGFloat(index) / CGFloat(samples)
                let x = s(-0.80) + t * s(1.60)
                let wave = sin(Double(t) * 5.5 + time * 0.45 + band.2) * 0.045 + sin(Double(t) * 11 + time * 0.8) * 0.012
                tops.append(CGPoint(x: x, y: s(band.1 + CGFloat(wave))))
            }
            ribbon.move(to: tops[0])
            for point in tops.dropFirst() { ribbon.addLine(to: point) }
            for point in tops.reversed() { ribbon.addLine(to: CGPoint(x: point.x, y: point.y + s(0.16))) }
            ribbon.closeSubpath()
            context.fill(ribbon, with: vertical([band.0.opacity(0), band.0.opacity(0.42), band.0.opacity(0)], s(band.1 - 0.05), s(band.1 + 0.17)))
        }
    }

    // MARK: Dog

    func paintFloatingHearts(in context: inout GraphicsContext, time: Double) {
        let colors = [Color(red: 1.0, green: 0.46, blue: 0.56), Color(red: 1.0, green: 0.64, blue: 0.72), character.color]
        for index in 0..<9 {
            let t = phase(time, period: Double(noise(index, 401, 4.5, 7.0)), offset: noise(index, 402, 0, 1))
            let startX = noise(index, 403, -0.46, 0.46)
            if abs(startX) < 0.12 { continue }
            let x = s(startX) + CGFloat(sin(Double(t) * 6 + Double(index))) * s(0.02)
            let y = s(-0.05) - t * s(0.55)
            let size = s(noise(index, 404, 0.018, 0.028))
            context.fill(heartPath(CGPoint(x: x, y: y), size), with: .color(colors[index % 3].opacity(fadeInOut(t) * 0.85)))
        }
    }

    // MARK: Lion

    func paintGoldDust(in context: inout GraphicsContext, time: Double) {
        for index in 0..<26 {
            let t = phase(time, period: Double(noise(index, 411, 5, 9)), offset: noise(index, 412, 0, 1))
            let x = s(noise(index, 413, -0.55, 0.55)) + CGFloat(sin(Double(t) * 4 + Double(index))) * s(0.015)
            let y = s(0.0) - t * s(0.75)
            let radius = s(noise(index, 414, 0.003, 0.006))
            let glow = Color(red: 1.0, green: 0.86, blue: 0.40).opacity(fadeInOut(t) * 0.9)
            context.fill(circle(CGPoint(x: x, y: y), radius * 2.5), with: radial([glow, glow.opacity(0)], CGPoint(x: x, y: y), radius * 2.5))
            context.fill(circle(CGPoint(x: x, y: y), radius), with: .color(Color.white.opacity(fadeInOut(t))))
        }
    }

    func paintBirds(in context: inout GraphicsContext, time: Double) {
        for index in 0..<3 {
            let t = phase(time, period: 16, offset: CGFloat(index) * 0.33)
            let x = s(-0.80) + t * s(1.60)
            let y = s(-0.78 + CGFloat(index) * 0.06) + CGFloat(sin(Double(t) * 8)) * s(0.01)
            let flap = CGFloat(sin(time * 7 + Double(index)))
            let span = s(0.022 - CGFloat(index) * 0.003)
            var wings = Path()
            wings.move(to: CGPoint(x: x - span, y: y + span * 0.2 * flap))
            wings.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - span * 0.5, y: y - span * 0.45 * flap))
            wings.addQuadCurve(to: CGPoint(x: x + span, y: y + span * 0.2 * flap), control: CGPoint(x: x + span * 0.5, y: y - span * 0.45 * flap))
            context.stroke(wings, with: .color(Color(red: 0.36, green: 0.20, blue: 0.14).opacity(fadeInOut(t, edge: 0.08) * 0.75)),
                           style: round(s(0.004)))
        }
    }

    // MARK: Water creatures

    func paintBubbles(in context: inout GraphicsContext, time: Double, count: Int = 16) {
        for index in 0..<count {
            let t = phase(time, period: Double(noise(index, 421, 4.0, 7.5)), offset: noise(index, 422, 0, 1))
            let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let baseX = side * noise(index, 423, 0.20, 0.52)
            let x = s(baseX) + CGFloat(sin(Double(t) * 7 + Double(index))) * s(0.018)
            let y = s(-0.02) - t * s(0.85)
            let radius = s(noise(index, 424, 0.007, 0.018)) * (0.7 + t * 0.5)
            let alpha = fadeInOut(t)
            let center = CGPoint(x: x, y: y)
            context.fill(circle(center, radius), with: radial([Color.white.opacity(0.05 * alpha), Color(red: 0.80, green: 0.90, blue: 1.0).opacity(0.25 * alpha)],
                                                              center, radius))
            context.stroke(circle(center, radius), with: .color(Color.white.opacity(0.75 * alpha)), lineWidth: max(0.6, radius * 0.14))
            context.fill(circle(CGPoint(x: x - radius * 0.35, y: y - radius * 0.35), radius * 0.22), with: .color(Color.white.opacity(0.9 * alpha)))
        }
    }

    func paintSkyFish(in context: inout GraphicsContext, time: Double) {
        let colors = [Color(red: 1.0, green: 0.60, blue: 0.24), Color(red: 1.0, green: 0.84, blue: 0.30), Color(red: 0.36, green: 0.84, blue: 0.90)]
        for index in 0..<3 {
            let angle = time * (0.35 + Double(index) * 0.08) + Double(index) * 2.1
            let x = CGFloat(cos(angle)) * s(0.52 - CGFloat(index) * 0.04)
            let y = s(-0.42 - CGFloat(index) * 0.10) + CGFloat(sin(angle * 2)) * s(0.05)
            let facingRight = sin(angle) < 0
            brush.fish(in: &context, center: CGPoint(x: x, y: y), length: s(0.04), color: colors[index],
                       facingRight: facingRight, flick: CGFloat(sin(time * 9 + Double(index))))
        }
    }

    func paintGulls(in context: inout GraphicsContext, time: Double) {
        for index in 0..<3 {
            let t = phase(time, period: 14, offset: CGFloat(index) * 0.37)
            let x = s(0.80) - t * s(1.60)
            let y = s(-0.70 + CGFloat(index) * 0.07) + CGFloat(sin(Double(t) * 9 + Double(index))) * s(0.015)
            let flap = CGFloat(sin(time * 6 + Double(index) * 2))
            let span = s(0.026)
            var wings = Path()
            wings.move(to: CGPoint(x: x - span, y: y + span * 0.15 * flap))
            wings.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - span * 0.45, y: y - span * 0.5 * flap))
            wings.addQuadCurve(to: CGPoint(x: x + span, y: y + span * 0.15 * flap), control: CGPoint(x: x + span * 0.45, y: y - span * 0.5 * flap))
            let alpha = fadeInOut(t, edge: 0.08)
            context.stroke(wings, with: .color(Color.white.opacity(alpha)), style: round(s(0.006)))
            context.stroke(wings, with: .color(Color(red: 0.36, green: 0.40, blue: 0.50).opacity(alpha * 0.5)), style: round(s(0.002)))
        }
    }

    // MARK: Insects

    func paintButterflies(in context: inout GraphicsContext, time: Double, palette: [Color]) {
        for index in 0..<4 {
            let speed = 0.30 + Double(index) * 0.06
            let a = time * speed + Double(index) * 1.6
            let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
            let x = side * s(0.34) + CGFloat(sin(a)) * s(0.12)
            let y = s(-0.20 - CGFloat(index % 2) * 0.12) + CGFloat(sin(a * 2.3)) * s(0.06)
            let flap = CGFloat(abs(sin(time * 11 + Double(index))))
            let wing = s(0.018)
            let color = palette[index % palette.count]
            for direction in [-1.0, 1.0] as [CGFloat] {
                let upper = CGPoint(x: x + direction * wing * 0.55 * (0.3 + flap * 0.7), y: y - wing * 0.25)
                let lower = CGPoint(x: x + direction * wing * 0.40 * (0.3 + flap * 0.7), y: y + wing * 0.35)
                context.fill(oval(upper, wing * 0.55 * (0.3 + flap * 0.7), wing * 0.50), with: .color(color))
                context.fill(oval(lower, wing * 0.38 * (0.3 + flap * 0.7), wing * 0.34), with: .color(color.opacity(0.8)))
                context.fill(circle(upper, wing * 0.12), with: .color(Color.white.opacity(0.7)))
            }
            context.fill(oval(CGPoint(x: x, y: y), wing * 0.10, wing * 0.45), with: .color(Color(red: 0.20, green: 0.14, blue: 0.16)))
        }
    }

    func paintBees(in context: inout GraphicsContext, time: Double) {
        let hive = bearHive
        for index in 0..<6 {
            let speed = 1.1 + Double(index) * 0.17
            let a = time * speed * (index.isMultiple(of: 2) ? 1 : -1) + Double(index) * 1.05
            let radius = s(0.06 + CGFloat(index % 3) * 0.035)
            let x = hive.x + CGFloat(cos(a)) * radius
            let y = hive.y + CGFloat(sin(a * 1.4)) * radius * 0.55 + s(0.01)
            let size = s(0.011)
            let flap = CGFloat(abs(sin(time * 30 + Double(index))))
            context.fill(oval(CGPoint(x: x - size * 0.2, y: y - size * 0.7), size * 0.45, size * 0.6 * flap + size * 0.1),
                         with: .color(Color.white.opacity(0.8)))
            context.fill(oval(CGPoint(x: x + size * 0.3, y: y - size * 0.7), size * 0.40, size * 0.55 * flap + size * 0.1),
                         with: .color(Color.white.opacity(0.7)))
            context.fill(oval(CGPoint(x: x, y: y), size, size * 0.68), with: .color(Color(red: 1.0, green: 0.80, blue: 0.16)))
            for stripe in [-0.25, 0.25] as [CGFloat] {
                context.fill(Path(CGRect(x: x + stripe * size - size * 0.11, y: y - size * 0.6, width: size * 0.22, height: size * 1.2)),
                             with: .color(Color(red: 0.16, green: 0.12, blue: 0.10)))
            }
        }
    }

    func paintHoneyDrips(in context: inout GraphicsContext, time: Double) {
        let sources = [CGPoint(x: bearHive.x + s(0.016), y: bearHive.y + s(0.085))]
        for (index, source) in sources.enumerated() {
            let t = phase(time, period: 2.4, offset: CGFloat(index) * 0.5)
            let y = source.y + t * t * s(0.18)
            let radius = s(0.006)
            var drop = Path()
            drop.move(to: CGPoint(x: source.x, y: y - radius * 2))
            drop.addQuadCurve(to: CGPoint(x: source.x, y: y + radius), control: CGPoint(x: source.x - radius * 1.6, y: y + radius))
            drop.addQuadCurve(to: CGPoint(x: source.x, y: y - radius * 2), control: CGPoint(x: source.x + radius * 1.6, y: y + radius))
            context.fill(drop, with: .color(Color(red: 1.0, green: 0.70, blue: 0.14).opacity(Double(1 - t))))
        }
    }

    func paintDragonflies(in context: inout GraphicsContext, time: Double) {
        for index in 0..<2 {
            let a = time * (0.5 + Double(index) * 0.2) + Double(index) * 3
            let x = CGFloat(sin(a)) * s(0.40)
            let y = s(-0.16 - CGFloat(index) * 0.14) + CGFloat(sin(a * 3)) * s(0.03)
            let flap = CGFloat(abs(sin(time * 28 + Double(index))))
            let length = s(0.04)
            let facing: CGFloat = cos(a) > 0 ? 1 : -1
            var body = Path()
            body.move(to: CGPoint(x: x - facing * length * 0.5, y: y))
            body.addLine(to: CGPoint(x: x + facing * length * 0.5, y: y))
            context.stroke(body, with: .color(Color(red: 0.20, green: 0.60, blue: 0.86)), style: round(s(0.004)))
            for wing in [-0.05, 0.12] as [CGFloat] {
                let wx = x + facing * length * wing
                context.fill(oval(CGPoint(x: wx, y: y - length * 0.18 * (0.4 + flap)), length * 0.12, length * 0.22 * (0.4 + flap)),
                             with: .color(Color.white.opacity(0.6)))
            }
        }
    }

    func paintFireflies(in context: inout GraphicsContext, time: Double) {
        for index in 0..<14 {
            let a = time * Double(noise(index, 431, 0.2, 0.5)) + Double(index) * 2.3
            let x = s(noise(index, 432, -0.52, 0.52)) + CGFloat(sin(a)) * s(0.05)
            let y = s(noise(index, 433, -0.50, -0.04)) + CGFloat(cos(a * 1.3)) * s(0.03)
            let blink = max(0, sin(time * Double(noise(index, 434, 1.5, 3.0)) + Double(index)))
            guard blink > 0.05 else { continue }
            let center = CGPoint(x: x, y: y)
            let glow = Color(red: 0.86, green: 1.0, blue: 0.46)
            context.fill(circle(center, s(0.018)), with: radial([glow.opacity(0.6 * blink), glow.opacity(0)], center, s(0.018)))
            context.fill(circle(center, s(0.0035)), with: .color(Color.white.opacity(blink)))
        }
    }

    // MARK: Fox

    func paintFallingLeaves(in context: inout GraphicsContext, time: Double) {
        let colors = [Color(red: 0.92, green: 0.24, blue: 0.12), Color(red: 1.0, green: 0.56, blue: 0.14), Color(red: 1.0, green: 0.80, blue: 0.24)]
        for index in 0..<14 {
            let t = phase(time, period: Double(noise(index, 441, 6, 10)), offset: noise(index, 442, 0, 1))
            let x = s(noise(index, 443, -0.55, 0.55)) + CGFloat(sin(Double(t) * 9 + Double(index))) * s(0.05)
            let y = s(-0.80) + t * s(0.95)
            let tumble = CGFloat(abs(cos(Double(t) * 12 + Double(index))))
            paintMapleLeaf(&context, center: CGPoint(x: x, y: y), size: s(0.014), angle: Double(t) * 8 + Double(index),
                           color: colors[index % 3].opacity(fadeInOut(t, edge: 0.1)), squash: 0.35 + tumble * 0.65)
        }
    }

    func paintLanternGlow(in context: inout GraphicsContext, time: Double) {
        for (index, lantern) in (foxPaperLanterns + foxStoneLanterns.map { CGPoint(x: $0.x, y: $0.y - s(0.082)) }).enumerated() {
            let pulse = 0.75 + 0.25 * sin(time * 2.4 + Double(index) * 1.3)
            let radius = s(index < 4 ? 0.06 : 0.05) * CGFloat(0.9 + 0.1 * pulse)
            context.fill(circle(lantern, radius), with: radial([Color(red: 1.0, green: 0.82, blue: 0.40).opacity(0.45 * pulse),
                                                                Color(red: 1.0, green: 0.60, blue: 0.20).opacity(0)], lantern, radius))
        }
    }

    // MARK: Frog

    func paintPondRipples(in context: inout GraphicsContext, time: Double) {
        let spots = [surf(-0.40, -0.40), surf(0.20, -0.30), surf(-0.06, -0.62), surf(0.50, -0.10), surf(-0.55, 0.05)]
        let squash = (ry / rx) * 1.05
        for (index, spot) in spots.enumerated() {
            let t = phase(time, period: 2.8, offset: CGFloat(index) * 0.21)
            for ring in 0..<2 {
                let progress = min(1, t + CGFloat(ring) * 0.18)
                let radius = s(0.012 + 0.05 * progress)
                context.stroke(oval(spot, radius, radius * squash), with: .color(Color.white.opacity(Double(1 - progress) * 0.6)),
                               lineWidth: s(0.003))
            }
        }
    }

    // MARK: Penguin

    func paintSnowfall(in context: inout GraphicsContext, time: Double) {
        for index in 0..<40 {
            let t = phase(time, period: Double(noise(index, 451, 7, 13)), offset: noise(index, 452, 0, 1))
            let x = s(noise(index, 453, -0.66, 0.66)) + CGFloat(sin(Double(t) * 7 + Double(index))) * s(0.025)
            let y = s(-1.05) + t * s(1.25)
            let radius = s(noise(index, 454, 0.003, 0.008))
            let alpha = fadeInOut(t, edge: 0.08)
            let center = CGPoint(x: x, y: y)
            context.fill(circle(center, radius * 1.8), with: radial([Color.white.opacity(0.5 * alpha), Color.white.opacity(0)], center, radius * 1.8))
            context.fill(circle(center, radius), with: .color(Color.white.opacity(alpha)))
        }
    }

    // MARK: Bunny

    func paintPetals(in context: inout GraphicsContext, time: Double) {
        let colors = [Color(red: 1.0, green: 0.76, blue: 0.86), Color.white, Color(red: 1.0, green: 0.62, blue: 0.76)]
        for index in 0..<16 {
            let t = phase(time, period: Double(noise(index, 461, 6, 10)), offset: noise(index, 462, 0, 1))
            let x = s(-0.62) + t * s(1.0) + s(noise(index, 463, -0.1, 0.3))
            let y = s(noise(index, 464, -0.90, -0.55)) + t * s(0.75) + CGFloat(sin(Double(t) * 8 + Double(index))) * s(0.02)
            var petal = context
            petal.translateBy(x: x, y: y)
            petal.rotate(by: .radians(Double(t) * 9 + Double(index)))
            let flutter = CGFloat(abs(cos(Double(t) * 10 + Double(index))))
            petal.fill(oval(.zero, s(0.009), s(0.005) * (0.3 + flutter * 0.7)), with: .color(colors[index % 3].opacity(fadeInOut(t, edge: 0.1))))
        }
    }
}
