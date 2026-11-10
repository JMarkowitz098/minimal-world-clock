import SwiftUI
import WorldClockCore
import WorldClockUI

// M6 design exploration for the Clock window: prototypes drawn side by side on one sheet so
// the user can compare and pick. Not app code; the chosen option moves into WorldClockUI.
// Chosen so far: layout C (city + globe top-right, beside the window buttons).

/// A fixed color theme (the same in light and dark mode): background, text, and an accent
/// for the city and globe. Several come from well-known open palettes; in-app names TBD.
struct Theme {
    let name: String
    let background: Color
    let text: Color
    let accent: Color

    init(_ name: String, _ background: UInt32, _ text: UInt32, _ accent: UInt32) {
        self.name = name
        self.background = Color(hex: background)
        self.text = Color(hex: text)
        self.accent = Color(hex: accent)
    }

    static let all: [Theme] = [
        Theme("Navy & cream", 0x1B2A4A, 0xF4EBD9, 0xE8B86D),
        Theme("Forest & cream", 0x1F3A2E, 0xEDE6D6, 0xC9A66B),
        Theme("Paper & ink", 0xF4EBD9, 0x2B2B2B, 0xB5452F),
        Theme("Solarized dark", 0x002B36, 0xEEE8D5, 0xB58900),
        Theme("Solarized light", 0xFDF6E3, 0x586E75, 0x268BD2),
        Theme("Nord", 0x2E3440, 0xECEFF4, 0x88C0D0),
        Theme("Rosé Pine Dawn", 0xFAF4ED, 0x575279, 0xD7827E),
        Theme("Dracula", 0x282A36, 0xF8F8F2, 0xFF79C6),
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// The close, minimize and zoom buttons, as a window without a title bar shows them.
struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34))
            Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18))
            Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25))
        }
        .frame(width: 52, height: 12)
    }
}

/// Layout C: the city and globe top-right, level with the window buttons; the time and date
/// centered below. A mock 300 pt window without a title bar.
struct ClockOption: View {
    let model: ClockViewModel
    let theme: Theme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Spacer()
                Text(model.cityText).font(.headline)
                Image(systemName: "globe").font(.callout)
            }
            .foregroundStyle(theme.accent)
            .frame(height: 12)
            .padding(.top, 12)
            .padding(.trailing, 14)
            Spacer()
            Text(TimeStyle.shrinkingDayPeriod(model.time, timeSize: TimeStyle.windowTimeSize))
                .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
                .monospacedDigit()
                .lineLimit(1)
            Text("\(model.dateText) · \(model.offsetText)").font(.callout).opacity(0.7)
            Spacer()
        }
        .foregroundStyle(theme.text)
        .frame(width: 300, height: 180)
        .background(theme.background)
        .overlay(alignment: .topLeading) { TrafficLights().padding(.leading, 12).padding(.top, 12) }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.black.opacity(0.15)))
    }
}

/// Options in a 2×2 grid, each with its caption.
@MainActor func optionSheet(_ options: [(caption: String, view: ClockOption)]) -> AnyView {
    let rows = stride(from: 0, to: options.count, by: 2).map { Array(options[$0..<min($0 + 2, options.count)]) }
    return AnyView(
        VStack(alignment: .leading, spacing: 20) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(alignment: .top, spacing: 24) {
                    ForEach(rows[r].indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 8) {
                            rows[r][i].view
                            Text(rows[r][i].caption).font(.callout.weight(.medium))
                        }
                    }
                }
            }
        }
        .padding(24)
    )
}

@MainActor let clockOptionSnapshots: [Snapshot] = [
    Snapshot(name: "clock-themes", size: CGSize(width: 672, height: 900)) {
        optionSheet(Theme.all.enumerated().map { i, theme in
            ("\(i + 1) · \(theme.name)", ClockOption(model: clockModel("Asia/Tokyo"), theme: theme))
        })
    },
]
