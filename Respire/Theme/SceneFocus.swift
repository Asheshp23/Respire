//
//  SceneFocus.swift
//  Respire
//
//  The light each world breathes with: the lotus keeps its rainbow orb;
//  elsewhere the light belongs to the scene: a corona round the moon, the sun on
//  the sea, a candle, crater heat, a lit cabin window. Plus `SceneThumbnail`,
//  each world standing still at a calm half-breath, for the scene picker.
//

import SwiftUI

/// Each world at a calm half-breath, standing still.
struct SceneThumbnail: View {
    let theme: BreathTheme

    var body: some View {
        Group {
            switch theme {
            case .aurora: AuroraLakeScene(openness: 0.6, time: 0, showsLeaves: false)
            case .ocean: OceanTideScene(openness: 0.6, time: 3)
            case .sakura: SakuraMoonScene(openness: 0.8, time: 3)
            case .desert: DesertStarsScene(openness: 0.6, time: 3)
            case .waterfall: WaterfallScene(openness: 0.7, time: 3)
            case .volcano: VolcanoScene(openness: 0.5, time: 3)
            case .rain: RainScene(openness: 0.6, time: 3)
            case .wind: WindScene(openness: 0.6, time: 3)
            case .thunder: ThunderScene(openness: 0.6, time: 3)
            case .cymatics: CymaticsScene(openness: 0.7, time: 3)
            case .meadow, .alpine, .seaside, .garden, .forest, .lake: DaylightScene(theme: theme, openness: 0.6, time: 3)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - The light each world breathes with

struct SceneFocus: View {
    let theme: BreathTheme
    var openness: Double
    var time: Double

    var body: some View {
        Canvas { context, size in
            context.blendMode = .plusLighter
            draw(in: &context, size: size)
        }
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        let o = openness
        switch theme {
        case .aurora, .cymatics, .meadow, .alpine, .seaside, .garden, .forest, .lake:
            // The lotus opening is the guide, with no ring of light over it;
            // Cymatics lights its own bowl, and daylight needs no extra glow.
            break
        case .ocean:
            // The setting sun swells, and its path of light widens across the sea.
            let sun = CGPoint(x: w / 2, y: h * 0.56)
            bloom(&context, at: sun, radius: w * (0.3 + 0.2 * o), color: Color(red: 1, green: 0.62, blue: 0.35), opacity: 0.18 + 0.2 * o)
            let pathWidth = w * (0.08 + 0.14 * o)
            context.fill(Path(ellipseIn: CGRect(x: sun.x - pathWidth, y: sun.y, width: pathWidth * 2, height: h * 0.4)),
                                      with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.75, blue: 0.5).opacity(0.25 * o), .clear]),
                                                                                  center: CGPoint(x: sun.x, y: sun.y + h * 0.05), startRadius: 0, endRadius: h * 0.3))
        case .sakura:
            // A lunar corona: the soft rings of color light makes in thin cloud
            // around the moon, widening as you breathe in.
            let moon = CGPoint(x: w * 0.72, y: h * 0.2)
            let r = w * 0.12
            let reach = r * (1.5 + 0.8 * o)
            // Inner to outer: pale blue aureole, warm gold, rose; real coronas fade outward.
            let rings: [(Color, Double)] = [
                (Color(red: 0.8, green: 0.88, blue: 1), 0.1), (Color(red: 1, green: 0.88, blue: 0.6), 0.07),
                (Color(red: 1, green: 0.62, blue: 0.75), 0.05),
            ]
            var soft = context
            soft.addFilter(.blur(radius: r * 0.25))
            bloom(&soft, at: moon, radius: reach, color: .white, opacity: 0.06 + 0.08 * o)
            for (i, ring) in rings.enumerated() {
                let radius = reach * (1 + Double(i) * 0.3)
                soft.stroke(Path(ellipseIn: CGRect(x: moon.x - radius, y: moon.y - radius, width: radius * 2, height: radius * 2)),
                                        with: .color(ring.0.opacity(ring.1 * (0.4 + 0.6 * o))),
                                        style: StrokeStyle(lineWidth: r * 0.22))
            }
        case .desert:
            // The candle's light, reaching further on the in-breath.
            let flame = CGPoint(x: w / 2, y: h * 0.86 - w * 0.1)
            bloom(&context, at: flame, radius: w * (0.14 + 0.16 * o), color: Color(red: 1, green: 0.66, blue: 0.3), opacity: 0.22 + 0.2 * o)
        case .waterfall:
            // Mist rising from the plunge pool.
            let foot = CGPoint(x: w / 2, y: h * 0.66)
            let rx = w * (0.3 + 0.2 * o)
            context.fill(Path(ellipseIn: CGRect(x: foot.x - rx, y: foot.y - rx * 0.5, width: rx * 2, height: rx)),
                                      with: .radialGradient(Gradient(colors: [Color.white.opacity(0.12 + 0.16 * o), .clear]),
                                                                                  center: foot, startRadius: 0, endRadius: rx))
        case .volcano:
            // Heat gathering above the crater.
            let crater = CGPoint(x: w / 2, y: h * 0.4)
            bloom(&context, at: crater, radius: w * (0.18 + 0.26 * o), color: Color(red: 1, green: 0.35, blue: 0.12), opacity: 0.2 + 0.25 * o)
            bloom(&context, at: CGPoint(x: crater.x, y: crater.y - h * 0.08 * o), radius: w * 0.12 * (0.5 + o), color: Color(red: 1, green: 0.7, blue: 0.3), opacity: 0.12 * o)
        case .rain:
            // Moonlight resting in the circle of stillness.
            let center = CGPoint(x: w / 2, y: h * 0.74)
            let rx = w * (0.12 + 0.34 * o)
            context.fill(Path(ellipseIn: CGRect(x: center.x - rx, y: center.y - rx * 0.24, width: rx * 2, height: rx * 0.48)),
                                      with: .radialGradient(Gradient(colors: [Color(red: 0.7, green: 0.85, blue: 1).opacity(0.14 + 0.14 * o), .clear]),
                                                                                  center: center, startRadius: 0, endRadius: rx))
        case .wind:
            // The low sun, and slow rays that lengthen with the breath.
            let sun = CGPoint(x: w * 0.78, y: h * 0.54)
            bloom(&context, at: sun, radius: w * (0.25 + 0.2 * o), color: Color(red: 1, green: 0.85, blue: 0.55), opacity: 0.16 + 0.18 * o)
            var rays = context
            rays.addFilter(.blur(radius: 6))
            for i in 0..<7 {
                let angle = .pi * (0.95 + Double(i) * 0.12) + sin(time * 0.1 + Double(i)) * 0.02
                let length = w * (0.35 + 0.45 * o)
                var ray = Path()
                ray.move(to: sun)
                ray.addLine(to: CGPoint(x: sun.x + cos(angle - 0.02) * length, y: sun.y + sin(angle - 0.02) * length))
                ray.addLine(to: CGPoint(x: sun.x + cos(angle + 0.02) * length, y: sun.y + sin(angle + 0.02) * length))
                ray.closeSubpath()
                rays.fill(ray, with: .linearGradient(Gradient(colors: [Color(red: 1, green: 0.9, blue: 0.65).opacity(0.12 * o), .clear]),
                                                                                          startPoint: sun, endPoint: CGPoint(x: sun.x + cos(angle) * length, y: sun.y + sin(angle) * length)))
            }
        case .thunder:
            // The cabin window, warming the dark.
            let cabin = CGPoint(x: w / 2, y: h * 0.68)
            bloom(&context, at: cabin, radius: w * (0.14 + 0.18 * o), color: Color(red: 1, green: 0.72, blue: 0.38), opacity: 0.18 + 0.22 * o)
        }
    }

    private func bloom(_ context: inout GraphicsContext, at center: CGPoint, radius: Double, color: Color, opacity: Double) {
        context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                                  with: .radialGradient(Gradient(colors: [color.opacity(opacity), color.opacity(opacity * 0.3), .clear]),
                                                                              center: center, startRadius: 0, endRadius: radius))
    }
}

#Preview("Focus: Sakura corona") {
    ZStack {
        SakuraMoonScene(openness: 0.9, time: 3)
        SceneFocus(theme: .sakura, openness: 0.9, time: 3)
    }
    .ignoresSafeArea()
}

#Preview("Focus: Ember Peak") {
    ZStack {
        VolcanoScene(openness: 0.8, time: 3)
        SceneFocus(theme: .volcano, openness: 0.8, time: 3)
    }
    .ignoresSafeArea()
}
