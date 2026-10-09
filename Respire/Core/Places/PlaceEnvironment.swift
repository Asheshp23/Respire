//
//  PlaceEnvironment.swift
//  Respire
//
//  How each Place is lit and what moves through its air, for the GPU: the main
//  light (where it sits, its color, how strongly it throws shafts and blooms) and a
//  particle system with real physics: gravity, drag, buoyancy, turbulent air, wind
//  that gusts with the breath, and a ground that rain splashes on and snow settles to.
//
//  Coordinates are fractions of the canvas, 0…1 from the top-left, so a profile fits
//  any screen. Rates are in canvas heights per second.
//

import SwiftUI

struct PlaceEnvironment {
    struct Light {
        /// Where the light sits.
        var point: CGPoint
        var color: Color
        /// Strength of the light shafts streaming from it; 0 for none.
        var rays: Double
        /// Strength of the glow around bright things.
        var bloom: Double = 0.6
        /// Brightness above which things glow and throw shafts.
        var threshold: Double = 0.55
    }

    struct Particles {
        enum Kind: Int {
            case rain, snow, motes, fireflies, steam, bubbles, embers, spray
        }

        var kind: Kind
        var count: Int
        var color: Color
        /// Where particles live and are born.
        var region = CGRect(x: 0, y: 0, width: 1, height: 1)
        /// Where rain splashes, snow settles, and spray falls back; beyond 1 for no ground.
        var groundY = 2.0
        var gravity = 0.0
        var buoyancy = 0.0
        var drag = 1.0
        /// How strongly the drifting air pushes them around.
        var turbulence = 0.05
        /// Steady side wind; it gusts as you breathe in.
        var wind = 0.0
        /// Size in points: width for rain streaks, radius otherwise.
        var size: ClosedRange<Double> = 1...2
        var life: ClosedRange<Double> = 4...8
        /// Rain draws as streaks stretched along its velocity; 0 draws round points.
        var streak = 0.0
        /// Glowing particles add light; others are painted over the scene.
        var glow = false
        /// Pull toward the region's middle as the visit goes on, for gathering fireflies.
        var attract = 0.0
        /// Whether the Canvas drawing's own rain and drifting motes step aside for these.
        var replacesSketch = true
        /// How many are out, 0…1, by stage: rain that builds and eases, snow that thins.
        var density: @Sendable (_ stage: Int) -> Double = { _ in 1 }
    }

    var light: Light?
    var particles: Particles?
}

// MARK: - Presets

extension PlaceEnvironment.Particles {
    static let everywhere = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// Slow, calm rain that splashes where it lands.
    static func rain(count: Int = 650, ground: Double = 0.97, region: CGRect = everywhere,
                     color: Color = Color(red: 0.8, green: 0.88, blue: 1).opacity(0.38),
                     density: @escaping @Sendable (Int) -> Double = { _ in 1 }) -> Self {
        Self(kind: .rain, count: count, color: color, region: region, groundY: ground,
             gravity: 0.6, drag: 1.2, turbulence: 0.02, wind: 0.06,
             size: 1.0...1.5, life: 3...5, streak: 0.05, density: density)
    }

    /// Flakes that wander on the air and settle on the ground before melting away.
    static func snow(count: Int = 420, ground: Double = 0.85, region: CGRect = everywhere,
                     density: @escaping @Sendable (Int) -> Double = { _ in 1 }) -> Self {
        Self(kind: .snow, count: count, color: .white.opacity(0.9), region: region, groundY: ground,
             gravity: 0.1, drag: 1.6, turbulence: 0.05, wind: 0.04,
             size: 1.4...3.4, life: 9...14, density: density)
    }

    /// Dust, pollen, or spores hanging in the light.
    static func motes(count: Int = 140, region: CGRect = everywhere, color: Color = .white.opacity(0.6),
                      replacesSketch: Bool = true) -> Self {
        Self(kind: .motes, count: count, color: color, region: region,
             buoyancy: 0.004, drag: 2, turbulence: 0.05, wind: 0.01,
             size: 0.7...1.8, life: 5...10, glow: true, replacesSketch: replacesSketch)
    }

    /// Wandering lights that blink, and gather as the visit goes on.
    static func fireflies(count: Int = 70, region: CGRect = everywhere,
                          color: Color = Color(red: 0.85, green: 0.95, blue: 0.45)) -> Self {
        Self(kind: .fireflies, count: count, color: color, region: region,
             drag: 1.4, turbulence: 0.14, size: 2...3.6, life: 6...12, glow: true, attract: 0.35,
             replacesSketch: false)
    }

    /// Warm vapor rising and spreading.
    static func steam(count: Int = 60, region: CGRect, color: Color = .white.opacity(0.14),
                      life: ClosedRange<Double> = 2.5...4) -> Self {
        Self(kind: .steam, count: count, color: color, region: region,
             buoyancy: 0.06, drag: 1.3, turbulence: 0.08, wind: 0.02,
             size: 5...12, life: life, replacesSketch: false)
    }

    /// Bubbles wobbling up toward the light.
    static func bubbles(count: Int = 120, region: CGRect = everywhere) -> Self {
        Self(kind: .bubbles, count: count, color: Color(red: 0.75, green: 0.95, blue: 1).opacity(0.5), region: region,
             buoyancy: 0.11, drag: 2, turbulence: 0.04, size: 1.2...3.6, life: 5...9, replacesSketch: false)
    }

    /// Sparks lifting off flames and fading.
    static func embers(count: Int = 70, region: CGRect, color: Color = Color(red: 1, green: 0.62, blue: 0.25)) -> Self {
        Self(kind: .embers, count: count, color: color, region: region,
             buoyancy: 0.09, drag: 1, turbulence: 0.16, size: 0.8...1.8, life: 1.5...3, glow: true,
             replacesSketch: false)
    }

    /// Droplets thrown up where falling water lands, arcing back down.
    static func spray(count: Int = 160, region: CGRect, ground: Double,
                      color: Color = .white.opacity(0.7), glow: Bool = true) -> Self {
        Self(kind: .spray, count: count, color: color, region: region, groundY: ground,
             gravity: 0.6, drag: 0.8, turbulence: 0.03, size: 0.9...2.2, life: 0.8...1.4, glow: glow,
             replacesSketch: false)
    }
}

// MARK: - Each place

extension Place {
    /// How this place is lit and what moves through it.
    var environment: PlaceEnvironment {
        typealias P = PlaceEnvironment.Particles
        typealias L = PlaceEnvironment.Light
        let warm = Color(red: 1, green: 0.82, blue: 0.5)
        let moon = Color(red: 0.85, green: 0.88, blue: 1)

        switch id {
        case "dream-station":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.45), color: Color(red: 0.8, green: 1, blue: 0.6), rays: 0.5),
                         particles: .motes(count: 120))
        case "rain-station":
            // Rain builds through the first three platforms, then eases, as in the drawing.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.3), color: warm, rays: 0.45),
                         particles: .rain(count: 750, ground: 0.95) { [0.3, 0.55, 1, 0.5, 0.15][min($0, 4)] })
        case "waterfall-house":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.2), color: .white, rays: 0, bloom: 0.2, threshold: 0.9),
                         particles: .spray(region: CGRect(x: 0.42, y: 0.74, width: 0.16, height: 0.04), ground: 0.8,
                                           color: Color(red: 0.25, green: 0.55, blue: 0.52).opacity(0.7), glow: false))
        case "cabin-falls":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.2), color: .white, rays: 0, bloom: 0.2, threshold: 0.9),
                         particles: .spray(region: CGRect(x: 0.52, y: 0.78, width: 0.2, height: 0.03), ground: 0.83,
                                           color: Color(red: 0.25, green: 0.55, blue: 0.52).opacity(0.7), glow: false))
        case "moth-garden":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.4), color: warm, rays: 0.25),
                         particles: .motes(count: 110, color: Color(red: 0.85, green: 1, blue: 0.75).opacity(0.5)))
        case "root-tree":
            // Its rain falls only in the current band, drawn with the art; spores drift in the canopy.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.18), color: Color(red: 0.7, green: 0.6, blue: 1), rays: 0.35),
                         particles: .motes(count: 120, region: CGRect(x: 0, y: 0, width: 1, height: 0.45),
                                           color: Color(red: 0.6, green: 1, blue: 0.8).opacity(0.6), replacesSketch: false))
        case "lighthouse":
            // The white tower is bright too; only the lamp and the lit windows should shine.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.17), color: Color(red: 1, green: 0.92, blue: 0.7),
                                  rays: 0.6, bloom: 0.35, threshold: 0.9),
                         particles: .motes(count: 70, region: CGRect(x: 0, y: 0, width: 1, height: 0.6),
                                           color: .white.opacity(0.35), replacesSketch: false))
        case "tea-house":
            // Rain behind the paper screen stays with the art; steam rises from the cups.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.3), color: .white, rays: 0, bloom: 0.2, threshold: 0.9),
                         particles: .steam(count: 50, region: CGRect(x: 0.42, y: 0.6, width: 0.52, height: 0.02),
                                           color: .white.opacity(0.32), life: 1.5...2.5))
        case "night-library":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.06), color: moon, rays: 0.9),
                         particles: .motes(count: 130, region: CGRect(x: 0.2, y: 0.05, width: 0.6, height: 0.9),
                                           color: Color(red: 1, green: 0.9, blue: 0.7).opacity(0.55), replacesSketch: false))
        case "lantern-bridge":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.35), color: Color(red: 1, green: 0.7, blue: 0.4), rays: 0.5),
                         particles: .fireflies(count: 40, region: CGRect(x: 0, y: 0.25, width: 1, height: 0.5),
                                               color: Color(red: 1, green: 0.75, blue: 0.4)))
        case "snow-cabin":
            // Heavy snow at first, thinning to a few flakes as the fire catches.
            // The snowfield is bright; only the window and the glints above it should glow.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.62), color: Color(red: 1, green: 0.7, blue: 0.4),
                                  rays: 0.35, bloom: 0.35, threshold: 0.88),
                         particles: .snow(count: 450, ground: 0.84) { [1, 0.8, 0.55, 0.35][min($0, 3)] })
        case "deep-sea":
            return .init(light: L(point: CGPoint(x: 0.5, y: -0.05), color: Color(red: 0.6, green: 0.9, blue: 1), rays: 0.9),
                         particles: .bubbles())
        case "observatory":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.3), color: moon, rays: 0, bloom: 0.9, threshold: 0.6),
                         particles: .motes(count: 60, region: CGRect(x: 0, y: 0, width: 1, height: 0.7),
                                           color: .white.opacity(0.3), replacesSketch: false))
        case "cloud-ferry":
            return .init(light: L(point: CGPoint(x: 0.62, y: 0.05), color: Color(red: 1, green: 0.95, blue: 0.85), rays: 0, bloom: 0.25, threshold: 0.92),
                         particles: nil)
        case "greenhouse":
            // Its rain falls on the glass, drawn with the art; pollen floats inside.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.25), color: Color(red: 0.85, green: 1, blue: 0.8), rays: 0.3),
                         particles: .motes(count: 90, region: CGRect(x: 0.1, y: 0.35, width: 0.8, height: 0.55),
                                           color: Color(red: 1, green: 0.95, blue: 0.6).opacity(0.6), replacesSketch: false))
        case "paper-boats":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.42), color: Color(red: 1, green: 0.8, blue: 0.6), rays: 0.8, threshold: 0.6),
                         particles: .motes(count: 60, region: CGRect(x: 0, y: 0.3, width: 1, height: 0.5),
                                           color: Color(red: 1, green: 0.85, blue: 0.7).opacity(0.4), replacesSketch: false))
        case "hut-window":
            // Weather behind the glass stays with the art; steam rises from the cup on the sill.
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.35), color: Color(red: 0.85, green: 0.9, blue: 1), rays: 0.3),
                         particles: .steam(count: 30, region: CGRect(x: 0.66, y: 0.68, width: 0.04, height: 0.02)))
        case "firefly-meadow":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.1), color: moon, rays: 0.2),
                         particles: .fireflies(count: 60, region: CGRect(x: 0, y: 0.3, width: 1, height: 0.6)))
        case "moon-gates":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.14), color: moon, rays: 0.9),
                         particles: .motes(count: 90, region: CGRect(x: 0, y: 0.45, width: 1, height: 0.35),
                                           color: Color(red: 0.95, green: 0.9, blue: 1).opacity(0.4), replacesSketch: false))
        case "ocean-postbox":
            // An evenly bright sky leaves the sun nothing to throw shafts past; keep them gentle.
            return .init(light: L(point: CGPoint(x: 0.7, y: 0.535), color: Color(red: 1, green: 0.8, blue: 0.6),
                                  rays: 0.6, bloom: 0.5, threshold: 0.72),
                         particles: .motes(count: 50, region: CGRect(x: 0, y: 0.3, width: 1, height: 0.4),
                                           color: Color(red: 1, green: 0.85, blue: 0.7).opacity(0.35), replacesSketch: false))
        case "bowl-temple":
            return .init(light: L(point: CGPoint(x: 0.5, y: 0.47), color: Color(red: 1, green: 0.95, blue: 0.85), rays: 0.7),
                         particles: .embers(count: 50, region: CGRect(x: 0.12, y: 0.8, width: 0.76, height: 0.02)))
        default:
            return .init(light: nil, particles: nil)
        }
    }
}
