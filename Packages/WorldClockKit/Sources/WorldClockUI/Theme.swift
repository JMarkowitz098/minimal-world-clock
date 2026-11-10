import SwiftUI
import WorldClockCore

/// The colors of the windows and the widget: background, text, and an accent (the city and
/// globe, hover states, Compare's difference and strip), plus a softer `surface` for popovers.
/// The user picks one in Settings (`SettingsViewModel.theme`); it doesn't change with the Mac's
/// light or dark mode.
public struct Theme: Sendable, Equatable, Identifiable {
    /// Saved in the settings (`AppSettings.theme`). Never change one.
    public let id: String
    /// Shown in the Settings window.
    public let name: String
    public let background: Color
    public let text: Color
    public let accent: Color
    /// A softer background for popovers (the zone picker): between `background` and white for
    /// light themes, a step lighter for dark ones. A full `background` there looked too heavy
    /// on Solarized light, plain white too stark.
    public let surface: Color
    /// Whether the background is dark. The window then uses macOS's dark appearance, so system
    /// controls (text fields, scroll bars, menus) match the theme rather than the Mac.
    public let isDark: Bool

    public init(id: String, name: String, background: Color, text: Color, accent: Color, surface: Color, isDark: Bool) {
        self.id = id
        self.name = name
        self.background = background
        self.text = text
        self.accent = accent
        self.surface = surface
        self.isDark = isDark
    }

    private init(_ id: String, _ name: String, background: UInt32, text: UInt32, accent: UInt32, surface: UInt32, isDark: Bool) {
        self.init(id: id, name: name, background: Color(hex: background), text: Color(hex: text),
                  accent: Color(hex: accent), surface: Color(hex: surface), isDark: isDark)
    }

    // Light and dark themes from the same palette sit side by side. Palettes are by their
    // authors (Solarized: Ethan Schoonover; Nord: Sven Greb; Rosé Pine; Gruvbox: Pavel
    // Pertsev; Dracula), MIT licensed and credited in the About window (Apps/Mac/Credits.rtf);
    // in-app names are to be checked before release (ROADMAP Handoff). Navy on Cream, Paper and
    // the retro looks (generic names) are plain color choices of our own.

    /// Solarized light: base3 background, base01 text, blue accent, base3 halfway to white.
    public static let solarizedLight = Theme("solarizedLight", "Solarized Light",
        background: 0xFDF6E3, text: 0x586E75, accent: 0x268BD2, surface: 0xFEFAF1, isDark: false)
    /// Solarized dark: base03 background, base1 text (brighter than the usual base0, for
    /// contrast), blue accent, base02 (Solarized's highlight background) for popovers.
    public static let solarizedDark = Theme("solarizedDark", "Solarized Dark",
        background: 0x002B36, text: 0x93A1A1, accent: 0x268BD2, surface: 0x073642, isDark: true)
    /// Nord's Snow Storm background with Polar Night text and a Frost blue accent.
    public static let nordLight = Theme("nordLight", "Nord Light",
        background: 0xECEFF4, text: 0x2E3440, accent: 0x5E81AC, surface: 0xF5F7FA, isDark: false)
    public static let nord = Theme("nord", "Nord",
        background: 0x2E3440, text: 0xD8DEE9, accent: 0x88C0D0, surface: 0x3B4252, isDark: true)
    /// Rosé Pine Dawn with its pine accent (its rose is too faint for text on the light base).
    public static let rosePineDawn = Theme("rosePineDawn", "Rosé Pine Dawn",
        background: 0xFAF4ED, text: 0x575279, accent: 0x286983, surface: 0xFFFAF3, isDark: false)
    public static let rosePine = Theme("rosePine", "Rosé Pine",
        background: 0x191724, text: 0xE0DEF4, accent: 0xEBBCBA, surface: 0x1F1D2E, isDark: true)
    public static let gruvboxLight = Theme("gruvboxLight", "Gruvbox Light",
        background: 0xFBF1C7, text: 0x3C3836, accent: 0xAF3A03, surface: 0xFDF8E3, isDark: false)
    public static let gruvboxDark = Theme("gruvboxDark", "Gruvbox Dark",
        background: 0x282828, text: 0xEBDBB2, accent: 0xFE8019, surface: 0x3C3836, isDark: true)
    /// Classic print colors: navy ink on cream paper with a brick red accent.
    public static let navyOnCream = Theme("navyOnCream", "Navy on Cream",
        background: 0xF4EEDF, text: 0x1F2A44, accent: 0xA23B2A, surface: 0xFAF6EE, isDark: false)
    public static let creamOnNavy = Theme("creamOnNavy", "Cream on Navy",
        background: 0x1F2A44, text: 0xF4EEDF, accent: 0xE0A458, surface: 0x2A3756, isDark: true)
    /// Near-black on white with a burnt orange accent.
    public static let paper = Theme("paper", "Paper",
        background: 0xFFFFFF, text: 0x1C1C1E, accent: 0xC2410C, surface: 0xF5F5F5, isDark: false)
    public static let dracula = Theme("dracula", "Dracula",
        background: 0x282A36, text: 0xF8F8F2, accent: 0xBD93F9, surface: 0x44475A, isDark: true)
    /// The four greens of an early handheld game console's LCD (named for the screen, not the
    /// console: product names are trademarks).
    public static let lcd = Theme("lcd", "LCD",
        background: 0x9BBC0F, text: 0x0F380F, accent: 0x306230, surface: 0xADC83F, isDark: false)
    /// A green phosphor CRT monitor.
    public static let phosphor = Theme("phosphor", "Phosphor",
        background: 0x0A140C, text: 0x33FF66, accent: 0xB8FF8A, surface: 0x13241A, isDark: true)
    /// An amber CRT monitor.
    public static let amber = Theme("amber", "Amber",
        background: 0x170E00, text: 0xFFB000, accent: 0xFFD98A, surface: 0x2A1A00, isDark: true)
    /// A neon arcade cabinet: cyan and pink on deep purple.
    public static let arcade = Theme("arcade", "Arcade",
        background: 0x0D0221, text: 0x2DE2E6, accent: 0xFF3864, surface: 0x1B0A3A, isDark: true)
}

extension Theme {
    /// Every theme the Settings window offers, in its order (light and dark of a palette
    /// together, retro looks last).
    public static let all: [Theme] = [
        .solarizedLight, .solarizedDark, .nordLight, .nord, .rosePineDawn, .rosePine,
        .gruvboxLight, .gruvboxDark, .navyOnCream, .creamOnNavy, .paper, .dracula,
        .lcd, .phosphor, .amber, .arcade,
    ]

    /// Used when nothing (or an unknown theme) is saved: `AppSettings.defaultTheme`.
    public static let `default` = named(AppSettings.defaultTheme)!

    /// The theme saved as `id`, or nil if no theme has it.
    public static func named(_ id: String) -> Theme? {
        all.first { $0.id == id }
    }
}

extension Color {
    /// A color from 0xRRGGBB, in sRGB.
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

extension EnvironmentValues {
    /// The theme views draw in. Each window and the widget set it once with `.themed(_:)`;
    /// everything inside reads it, so the Settings choice changes one value.
    @Entry public var theme: Theme = .solarizedLight
}

extension View {
    /// Draws this window's content in `theme`: sets `\.theme` and, so system controls match
    /// it, the window's light or dark appearance.
    public func themed(_ theme: Theme) -> some View {
        environment(\.theme, theme)
            .preferredColorScheme(theme.isDark ? .dark : .light)
    }
}
