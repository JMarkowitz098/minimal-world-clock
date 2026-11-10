import SwiftUI

/// A window's colors: background, text, and an accent for the zone button (city and globe).
/// Themes follow well-known palettes and are fixed (the same in light and dark mode).
/// Planned (see design_doc.md): a System theme as the default, and a choice in Settings.
public struct Theme: Sendable, Equatable {
    public let name: String
    public let background: Color
    public let text: Color
    public let accent: Color
    /// A softer background for popovers (the zone picker): between `background` and white for
    /// light themes. A full `background` there looked too heavy, plain white too stark.
    public let surface: Color

    public init(name: String, background: Color, text: Color, accent: Color, surface: Color) {
        self.name = name
        self.background = background
        self.text = text
        self.accent = accent
        self.surface = surface
    }

    /// Solarized light (Ethan Schoonover): base3 background, base01 text, blue accent.
    public static let solarizedLight = Theme(
        name: "Solarized Light",
        background: Color(hex: 0xFDF6E3),
        text: Color(hex: 0x586E75),
        accent: Color(hex: 0x268BD2),
        surface: Color(hex: 0xFEFAF1)  // base3 halfway to white
    )

    /// Solarized dark: base03 background, base1 text (brighter than the usual base0, for
    /// contrast), blue accent, base02 (Solarized's highlight background) for popovers.
    public static let solarizedDark = Theme(
        name: "Solarized Dark",
        background: Color(hex: 0x002B36),
        text: Color(hex: 0x93A1A1),
        accent: Color(hex: 0x268BD2),
        surface: Color(hex: 0x073642)
    )
}

/// A light and a dark theme used together: the window shows the one matching the Mac's
/// appearance. The default for M7's theme setting ("System") follows the appearance this way.
public struct ThemePair: Sendable, Equatable {
    public let light: Theme
    public let dark: Theme

    public init(light: Theme, dark: Theme) {
        self.light = light
        self.dark = dark
    }

    public func theme(for scheme: ColorScheme) -> Theme {
        scheme == .dark ? dark : light
    }

    public static let solarized = ThemePair(light: .solarizedLight, dark: .solarizedDark)
}

extension Color {
    /// A color from 0xRRGGBB, in sRGB.
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
