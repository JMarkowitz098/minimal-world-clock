import SwiftUI
import Testing
@testable import WorldClockUI

// WCAG 2 AA contrast for every theme (M8): 4.5:1 for text (everything we draw is under WCAG's
// "large" sizes except the big times), 3:1 for non-text marks (checkmark, rings, the strip's thumb).

/// WCAG contrast ratio of two opaque colors.
private func contrast(_ a: Color, _ b: Color) -> Double {
    func luminance(_ color: Color) -> Double {
        let c = color.resolve(in: EnvironmentValues())
        return 0.2126 * Double(c.linearRed) + 0.7152 * Double(c.linearGreen) + 0.0722 * Double(c.linearBlue)
    }
    let (la, lb) = (luminance(a), luminance(b))
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
}

/// `color` at `opacity` over the opaque `background`, as drawn: macOS composites the
/// gamma-encoded sRGB values, not linear light (blending linear light would read darker fills
/// on dark themes).
private func blend(_ color: Color, _ opacity: Double, over background: Color) -> Color {
    let (f, b) = (color.resolve(in: EnvironmentValues()), background.resolve(in: EnvironmentValues()))
    func mix(_ x: Float, _ y: Float) -> Float { x * Float(opacity) + y * Float(1 - opacity) }
    return Color(Color.Resolved(colorSpace: .sRGB, red: mix(f.red, b.red),
                                green: mix(f.green, b.green), blue: mix(f.blue, b.blue)))
}

@Test func contrastRatioMatchesWCAG() {
    #expect(abs(contrast(.black, .white) - 21) < 0.01)
    #expect(abs(contrast(Color(hex: 0x767676), .white) - 4.54) < 0.01)
}

@Test func everyThemesTextMeetsAA() {
    for theme in Theme.all {
        #expect(contrast(theme.text, theme.background) >= 4.5, "\(theme.name) text on background")
        #expect(contrast(theme.text, theme.surface) >= 4.5, "\(theme.name) text on the picker")
    }
}

@Test func everyThemesAccentMeetsAA() {
    for theme in Theme.all {
        // The city, Compare's difference, the widget's city.
        #expect(contrast(theme.accent, theme.background) >= 4.5, "\(theme.name) accent text")
        // The picker's checkmark and focus ring.
        #expect(contrast(theme.accent, theme.surface) >= 3, "\(theme.name) accent marks on the picker")
    }
}

@Test func hoveredTextMeetsAA() {
    for theme in Theme.all {
        let row = blend(theme.accent, Theme.hoverFill, over: theme.surface)
        #expect(contrast(theme.text, row) >= 4.5, "\(theme.name) hovered picker row")
        let pill = blend(theme.accent, Theme.hoverFill, over: theme.background)
        #expect(contrast(theme.accent, pill) >= 4.5, "\(theme.name) hovered city button")
    }
}

@Test func nowButtonMeetsAA() {
    for theme in Theme.all {
        #expect(contrast(theme.background, theme.accent) >= 4.5, "\(theme.name) Now")
    }
}

@Test func increasedContrastStrengthensLinesAndRings() {
    func opacity(_ color: Color) -> Float { color.resolve(in: EnvironmentValues()).opacity }
    let normal = Theme.solarizedLight
    let strong = normal.withIncreasedContrast(true)
    #expect(abs(opacity(normal.line(0.15)) - 0.15) < 0.001)
    #expect(abs(opacity(strong.line(0.15)) - 0.45) < 0.001)
    #expect(opacity(strong.line(0.5)) == 1)
    #expect(abs(opacity(normal.ring(0.4)) - 0.4) < 0.001)
    #expect(opacity(strong.ring(0.4)) == 1)
}
