import SwiftUI
import WorldClockCore
import WorldClockUI

// M6 design exploration, round 2: a border for the desktop widget (asked for by the user), drawn
// around the real `ZoneWidgetView`. Not app code: the chosen border moves into the widget, then
// this file is deleted.

struct WidgetBorder {
    let caption: String
    /// Line color from the theme, its opacity, width, and inset from the widget's edge.
    var accent: Bool
    var opacity: Double
    var width: CGFloat
    var inset: CGFloat = 0

    static let round2: [WidgetBorder] = [
        WidgetBorder(caption: "A · No border", accent: false, opacity: 0, width: 0),
        WidgetBorder(caption: "B · Hairline in the text color", accent: false, opacity: 0.25, width: 1),
        WidgetBorder(caption: "C · Thin accent edge (like the windows' hover)", accent: true, opacity: 1, width: 2),
        WidgetBorder(caption: "D · Soft accent edge, wider", accent: true, opacity: 0.35, width: 4),
        WidgetBorder(caption: "E · Inner line, inset 6 pt, text color", accent: false, opacity: 0.3, width: 1, inset: 6),
        WidgetBorder(caption: "F · Inner accent line, inset 6 pt", accent: true, opacity: 0.6, width: 1.5, inset: 6),
    ]
}

struct WidgetBorderOption: View {
    let border: WidgetBorder
    let display: WidgetDisplay
    let instant: Date
    let size: ZoneWidgetView.Size
    @Environment(\.colorScheme) private var scheme
    private var theme: Theme { ThemePair.solarized.theme(for: scheme) }
    private let radius: CGFloat = 22

    var body: some View {
        ZoneWidgetView(display: display, size: size, themes: .solarized, frozenTime: instant)
            .padding(16)
            .frame(width: size == .small ? 170 : 364, height: 170)
            .background(theme.background, in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius - border.inset)
                    .strokeBorder((border.accent ? theme.accent : theme.text).opacity(border.opacity), lineWidth: border.width)
                    .padding(border.inset)
            }
    }
}

/// Every border, small (10 PM, a two-digit hour) beside medium, over a desktop-like backdrop.
struct WidgetBorderSheet: View {
    private let tokyo = Zone(identifier: "Asia/Tokyo")!
    private let tenPM = jan15Noon.addingTimeInterval(3600)

    var body: some View {
        let display = WidgetDisplay(zone: tokyo, at: tenPM, locale: Locale(identifier: "en_US"))
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(WidgetBorder.round2.enumerated()), id: \.offset) { _, border in
                VStack(alignment: .leading, spacing: 6) {
                    Text(border.caption).font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary)
                    HStack(spacing: 18) {
                        WidgetBorderOption(border: border, display: display, instant: tenPM, size: .small)
                        WidgetBorderOption(border: border, display: display, instant: tenPM, size: .medium)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.6, green: 0.25, blue: 0.15))
    }
}
