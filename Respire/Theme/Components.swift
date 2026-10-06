//
//  Components.swift
//  Respire
//
//  Small, reusable pieces of the visual system (from Mindful Prism). When to use each:
//
//  - `paperBackground()`  every full screen and sheet: a still, dim version of the
//                         chosen breath world, with a faint spectral light leak.
//  - `spectralEdge()`     a thin rainbow rim: marks the one action that refracts
//                         (beginning a session).
//  - `card()`             one pane of icy glass for content that belongs together.
//  - `IceGlass`           the glass itself: frosted blur, cool tint, specular rim,
//                         a faint prismatic edge, and Metal-drawn frost crystals.
//  - `.pill`              the primary action on a screen. Solid ink capsule.
//  - `.tool`              secondary tools. Quiet glass circle.
//  - `Rule`               separating sections inside a card.
//
import SwiftUI

// MARK: - Background

extension View {
    /// The room: a still, dim version of the chosen breath world (by default a
    /// Canadian fall night: northern lights over the Rockies), soft pools
    /// of spectrum light, and light refracting in from the top corner. Everything
    /// here is still, so it costs nothing to keep on screen.
    func paperBackground() -> some View {
        background {
            ZStack(alignment: .topTrailing) {
                Theme.Palette.paper
                NightScene()
                AmbientLight()
                LightLeak()
            }
            .ignoresSafeArea()
        }
    }

    /// A thin spectrum rim around a capsule, with a soft glow. Shows only when enabled.
    func spectralEdge(_ isOn: Bool = true) -> some View {
        modifier(SpectralEdge(isOn: isOn))
    }
}

/// The still landscape behind every screen, following the breath theme the person
/// chose. Dim enough that the glass above it reads first.
private struct NightScene: View {
    @AppStorage(BreathTheme.storageKey) private var theme: BreathTheme = .aurora

    var body: some View {
        ThemeBackdrop(theme: theme)
    }
}

/// Soft pools of spectrum light far behind everything, so the glass panes have
/// something to refract. Static (no motion cost), and dim enough that text on
/// the glass keeps its contrast.
private struct AmbientLight: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Circle().fill(Theme.prism[6]).frame(width: w * 0.9).position(x: w * 0.05, y: h * 0.28)
                Circle().fill(Theme.prism[4]).frame(width: w * 0.8).position(x: w * 0.95, y: h * 0.55)
                Circle().fill(Theme.prism[3]).frame(width: w * 0.6).position(x: w * 0.2, y: h * 0.82)
                Circle().fill(Theme.prism[1]).frame(width: w * 0.55).position(x: w * 0.85, y: h * 0.98)
            }
            .blur(radius: 90)
            .opacity(0.1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Decorative. Low enough opacity that text over it keeps its contrast.
private struct LightLeak: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: Theme.rainbow, startPoint: .leading, endPoint: .trailing))
            .frame(width: 420, height: 120)
            .rotationEffect(.degrees(-28))
            .blur(radius: 70)
            .opacity(colorScheme == .dark ? 0.26 : 0.22)
            .offset(x: 140, y: -30)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct SpectralEdge: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        let gradient = AngularGradient(colors: Theme.rainbow + [Theme.rainbow[0]], center: .center)
        content
            .background {
                if isOn {
                    Capsule()
                        .fill(gradient)
                        .blur(radius: 10)
                        .opacity(0.45)
                        .padding(4)
                        .offset(y: 4)
                        .accessibilityHidden(true)
                }
            }
            .overlay {
                if isOn {
                    Capsule()
                        .strokeBorder(gradient, lineWidth: 1.5)
                        .accessibilityHidden(true)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isOn)
    }
}

extension View {

    /// One pane of icy glass. `stacked` tucks two faint sheets behind it.
    /// `glow` washes a corner of the card in a hue.
    func card(padding: CGFloat = Theme.Space.m, stacked: Bool = false, glow: Color? = nil) -> some View {
        modifier(CardModifier(padding: padding, stacked: stacked, glow: glow))
    }
}

private struct CardModifier: ViewModifier {
    let padding: CGFloat
    let stacked: Bool
    let glow: Color?

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.large, style: .continuous)
        content
            .padding(padding)
            .background {
                ZStack {
                    if stacked {
                        // Two sheets peeking out below, narrower as they go back.
                        IceGlass(shape: shape, frost: false)
                            .opacity(0.45)
                            .padding(.horizontal, 20)
                            .offset(y: 16)
                        IceGlass(shape: shape, frost: false)
                            .opacity(0.75)
                            .padding(.horizontal, 10)
                            .offset(y: 8)
                    }
                    IceGlass(shape: shape)
                    if let glow {
                        shape.fill(
                            RadialGradient(
                                colors: [glow.opacity(0.16), glow.opacity(0)],
                                center: .topTrailing,
                                startRadius: 0,
                                endRadius: 320
                            )
                        )
                    }
                }
                .accessibilityHidden(true)
            }
    }
}

// MARK: - Ice glass

/// A pane of icy glass in any shape: frosted blur of what's behind, a cool tint,
/// a highlight band across the top, a specular rim brighter at the top-left, a
/// faint rainbow at the edge where light refracts, and frost crystals drawn by
/// the `frost` Metal shader. With Reduce Transparency it becomes a solid pane.
struct IceGlass<S: InsettableShape>: View {
    let shape: S
    var frost = true

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            shape.fill(Theme.Palette.card)
                .overlay(shape.strokeBorder(.white.opacity(0.12), lineWidth: 1))
        } else {
            ZStack {
                shape.fill(.ultraThinMaterial)
                // Cool, icy tint.
                shape.fill(
                    LinearGradient(
                        colors: [Color(red: 0.75, green: 0.88, blue: 1.0).opacity(0.10), Color(red: 0.6, green: 0.7, blue: 0.9).opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                // Light catching the top of the pane.
                shape.fill(
                    LinearGradient(
                        stops: [.init(color: .white.opacity(0.10), location: 0), .init(color: .white.opacity(0), location: 0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                if frost {
                    GeometryReader { geo in
                        Rectangle()
                            .colorEffect(ShaderLibrary.frost(.float2(geo.size.width, geo.size.height), .float(7)))
                    }
                    .clipShape(shape)
                    .blendMode(.plusLighter)
                }
                // Prismatic edge: a hint of rainbow where light bends at the rim.
                shape.strokeBorder(AngularGradient(colors: Theme.prism + [Theme.prism[0]], center: .center), lineWidth: 1.5)
                    .blur(radius: 1.5)
                    .opacity(0.35)
                // Specular rim, bright at the top-left like light on an ice edge.
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.08), .white.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
        }
    }
}

// MARK: - Buttons

/// Solid ink capsule. The one primary action on a screen.
struct PillButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(Theme.Palette.onInk)
            .padding(.horizontal, Theme.Space.l)
            .frame(minHeight: Theme.minTapTarget + 4)
            .background(Theme.Palette.ink, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

/// A quiet glass circle holding one symbol. For secondary tools.
struct ToolButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = Theme.minTapTarget

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(Theme.Palette.ink)
            .frame(width: size, height: size)
            .background { IceGlass(shape: Circle(), frost: false).opacity(configuration.isPressed ? 0.6 : 1) }
            .opacity(isEnabled ? 1 : 0.35)
            .contentShape(Circle())
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
}

extension ButtonStyle where Self == ToolButtonStyle {
    static var tool: ToolButtonStyle { ToolButtonStyle() }
}

// MARK: - Rule

/// A hairline. The default separator between sections.
struct Rule: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Palette.rule)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}
