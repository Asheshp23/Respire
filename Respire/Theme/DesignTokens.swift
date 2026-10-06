//
//  DesignTokens.swift
//  Respire
//
//  The whole visual system in one place, carried over from Mindful Prism. The app
//  is a dark room, so that light has something to shine against: the interface
//  itself stays colorless (soft white on near-black and charcoal), and color only
//  appears where light has been refracted: the prism's seven colors, the breath
//  worlds, the spectral edge on the one action that starts a session.
//
//  The app runs in dark appearance throughout (set at the app root). Light values
//  are kept so the tokens still work anywhere a light context is forced.
//
//  Rules of use:
//
//  - A near-black room holds icy glass cards. Content that belongs together sits
//    on one card; the room (or the breath world) carries headlines and metadata.
//  - Monochrome first. `accent` is ink: primary actions are solid ink pills,
//    secondary tools are quiet glass circles.
//  - Serif = the breath's guiding voice. SF Pro = the app's voice (labels, data,
//    controls).
//  - Liquid Glass only on controls that float over content (system toolbars).
//
import SwiftUI
import UIKit

enum Theme {

    // MARK: - Color

    /// Light / dark pairs. Every text token clears WCAG AA (4.5:1) on both
    /// `paper` and `card`.
    enum Palette {
        /// The canvas behind cards: cool soft gray / near-black.
        static let paper = dynamic(light: 0xECECEF, dark: 0x0A0A0C)
        /// Card surface: white / raised charcoal.
        static let card = dynamic(light: 0xFFFFFF, dark: 0x1C1C1F)

        /// Primary text. ~16:1.
        static let ink = dynamic(light: 0x111113, dark: 0xF2F2F5)
        /// Supporting copy. ~7:1.
        static let inkSecondary = dynamic(light: 0x4E4E55, dark: 0xB4B4BC)
        /// Metadata, placeholders. ~4.6:1 on `paper`.
        static let inkTertiary = dynamic(light: 0x68686F, dark: 0x8E8E96)
        /// Text drawn on an ink fill (pill buttons).
        static let onInk = dynamic(light: 0xFFFFFF, dark: 0x111113)
        /// Hairline rules.
        static let rule = dynamic(light: 0xE3E3E8, dark: 0x2E2E33)

        /// Interactive text and primary actions. Monochrome by design.
        static let accent = ink

        /// The heartbeat: the pulse ring and resting pulse. Always paired with words.
        static let pulse = dynamic(light: 0xC8321F, dark: 0xFF6B5E)
    }

    /// The prism's seven colors, red through violet: rays, the corner light leak,
    /// the spectral edge, rhythm hues. Decorative light only; never for body text.
    static let prism: [Color] = [
        Color(red: 1.0, green: 0.36, blue: 0.33),   // red
        Color(red: 1.0, green: 0.62, blue: 0.24),   // orange
        Color(red: 1.0, green: 0.85, blue: 0.30),   // yellow
        Color(red: 0.37, green: 0.84, blue: 0.54),  // green
        Color(red: 0.31, green: 0.66, blue: 1.0),   // blue
        Color(red: 0.44, green: 0.48, blue: 1.0),   // indigo
        Color(red: 0.71, green: 0.55, blue: 1.0),   // violet
    ]

    /// Same sweep, kept as a name for gradients.
    static let rainbow: [Color] = prism

    // MARK: - Type

    /// All styles are Dynamic Type text styles, so everything scales.
    enum Typography {
        /// The breath's instruction ("Breathe in"), large and serif.
        static let instruction = Font.system(.largeTitle, design: .serif)
        /// Sheet and screen headlines.
        static let title = Font.system(.title2, weight: .bold)
        /// A large numeral (resting pulse, countdown).
        static let numeral = Font.system(.largeTitle, design: .rounded, weight: .light)
        /// The app's voice: guiding lines and explanatory copy.
        static let note = Font.body
        static let noteLineSpacing: CGFloat = 4
        /// Small labels ("Rhythm").
        static let label = Font.subheadline.weight(.semibold)
        /// Small uppercase section heading.
        static let eyebrow = Font.caption2.weight(.semibold)
        /// Dates, hints, small print.
        static let meta = Font.footnote
        static let caption = Font.caption
    }

    // MARK: - Space

    /// 4-pt based scale. `page` is the horizontal margin for all content.
    enum Space {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let page: CGFloat = 20
    }

    // MARK: - Shape

    enum Radius {
        static let small: CGFloat = 6
        /// Tiles and inline blocks.
        static let medium: CGFloat = 16
        /// Primary content cards.
        static let large: CGFloat = 28
    }

    /// Apple's minimum tap target.
    static let minTapTarget: CGFloat = 44

    // MARK: - Helpers

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
