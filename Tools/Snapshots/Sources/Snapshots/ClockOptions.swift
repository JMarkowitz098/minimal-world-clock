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

// MARK: - Hover options (M6): each tile shows the Clock window while the pointer is over it.

enum TimeHover: String, CaseIterable {
    case seconds = "T1 · Seconds appear and tick"
    case offset = "T2 · UTC offset fades in"
    case difference = "T3 · Difference from your time"
    case lift = "T4 · Time lifts and takes the accent"
    case backgroundDeepens = "W1 · Background deepens a shade"
    case edgeGlow = "W2 · Thin accent edge around the window"
    case tintAndAccent = "W3 · Background tints blue, time takes the accent"
    case accentOnly = "W4 · Time takes the accent (no lift)"
}

enum GlobeHover: String, CaseIterable {
    case pill = "G1 · Pill highlight behind city + globe"
    case underline = "G2 · City underlined, accent deepens"
    case spin = "G3 · Globe turns (filled while hovered)"
    case chevron = "G4 · Chevron slides in"
    case outline = "G5 · Hairline outline, no fill"
    case faintPill = "G6 · Fainter, tighter pill"
    case globeDot = "G7 · Soft circle behind the globe only"
    case colorOnly = "G8 · Blue deepens, nothing else"
}

/// The approved Clock window (layout C, Solarized light) in a hovered state.
struct HoverOption: View {
    let model: ClockViewModel
    var time: TimeHover?
    var globe: GlobeHover?
    private let theme = WorldClockUI.Theme.solarizedLight

    private var timeText: AttributedString {
        guard time == .seconds else { return model.time }
        return Date.FormatStyle(locale: Locale(identifier: "en_US"), timeZone: TimeZone(identifier: "Asia/Tokyo")!)
            .hour().minute().second().attributedStyle.format(jan15Noon.addingTimeInterval(42))
    }

    private var dateLine: String {
        switch time {
        case .offset: "\(model.dateText) · \(model.offsetText)"
        case .difference: "\(model.dateText) · 14 h ahead of you"
        default: model.dateText
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack { Spacer(); globeButton }
                .frame(height: 28)
                .padding(.trailing, 12)
            VStack(spacing: 2) {
                Text(TimeStyle.shrinkingDayPeriod(timeText, timeSize: TimeStyle.windowTimeSize))
                    .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
                    .monospacedDigit()
                    .foregroundStyle([.lift, .tintAndAccent, .accentOnly].contains(time) ? theme.accent : theme.text)
                    .scaleEffect(time == .lift ? 1.04 : 1)
                    .shadow(color: .black.opacity(time == .lift ? 0.12 : 0), radius: 6, y: 3)
                Text(dateLine).font(.system(size: 12))
            }
            .foregroundStyle(theme.text)
            .padding(.horizontal, 16)
            .padding(.top, 2)
            .padding(.bottom, 20)
        }
        .frame(width: 300, height: 150)
        .background(windowBackground)
        .overlay {
            if time == .edgeGlow {
                RoundedRectangle(cornerRadius: 12).strokeBorder(theme.accent.opacity(0.6), lineWidth: 2)
            }
        }
        .overlay(alignment: .topLeading) { TrafficLights().padding(.leading, 12).padding(.top, 8) }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.black.opacity(0.15)))
    }

    private var windowBackground: Color {
        switch time {
        case .backgroundDeepens: Color(hex: 0xEEE8D5)  // Solarized base2
        case .tintAndAccent: Color(hex: 0xEAF1F3)
        default: theme.background
        }
    }

    private var globeButton: some View {
        HStack(spacing: 6) {
            Text(model.cityText).font(.headline)
                .underline(globe == .underline)
            Image(systemName: globe == .spin ? "globe.asia.australia.fill" : "globe").font(.callout)
                .rotationEffect(.degrees(globe == .spin ? -20 : 0))
                .background { if globe == .globeDot { Circle().fill(theme.accent.opacity(0.15)).frame(width: 24, height: 24) } }
            if globe == .chevron {
                Image(systemName: "chevron.down").font(.caption.weight(.bold))
            }
        }
        .foregroundStyle([.underline, .colorOnly].contains(globe) ? Color(hex: 0x1A6091) : theme.accent)
        .padding(.horizontal, [.pill, .outline].contains(globe) ? 8 : globe == .faintPill ? 5 : 0)
        .padding(.vertical, [.pill, .outline].contains(globe) ? 3 : globe == .faintPill ? 1 : 0)
        .background(globe == .pill ? theme.accent.opacity(0.15) : globe == .faintPill ? theme.accent.opacity(0.08) : .clear, in: Capsule())
        .overlay { if globe == .outline { Capsule().strokeBorder(theme.accent.opacity(0.5), lineWidth: 1) } }
    }
}

/// Like `optionSheet`, for hover tiles: two per row.
@MainActor func hoverSheet(_ options: [(caption: String, view: HoverOption)]) -> AnyView {
    AnyView(
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(stride(from: 0, to: options.count, by: 2)), id: \.self) { r in
                HStack(alignment: .top, spacing: 24) {
                    ForEach(r..<min(r + 2, options.count), id: \.self) { i in
                        VStack(alignment: .leading, spacing: 8) {
                            options[i].view
                            Text(options[i].caption).font(.callout.weight(.medium))
                        }
                    }
                }
            }
        }
        .padding(24)
    )
}

@MainActor let hoverOptionSnapshots: [Snapshot] = [
    Snapshot(name: "clock-hover-time", size: CGSize(width: 672, height: 840)) {
        hoverSheet(TimeHover.allCases.map { ($0.rawValue, HoverOption(model: clockModel("Asia/Tokyo"), time: $0)) })
    },
    Snapshot(name: "clock-hover-globe", size: CGSize(width: 672, height: 840)) {
        hoverSheet(GlobeHover.allCases.map { ($0.rawValue, HoverOption(model: clockModel("Asia/Tokyo"), globe: $0)) })
    },
]

// MARK: - Zone picker theming options (M6). Mock popovers: Accra selected, Adak hovered.

enum PickerTheming: String, CaseIterable {
    case current = "P0 · Current: full theme background"
    case accentOnly = "P1 · Accent only on the system background"
    case creamHeader = "P2 · Cream search header, neutral list"
    case lightTint = "P3 · Theme background at half strength"
}

struct PickerOption: View {
    let theming: PickerTheming
    private let theme = WorldClockUI.Theme.solarizedLight
    private let neutral = Color(nsColor: .controlBackgroundColor)
    private let rows = Array(ZonePickerViewModel(now: jan15Noon).rows.prefix(7))

    private var listBackground: Color {
        switch theming {
        case .current: theme.background
        case .lightTint: theme.background.mix(with: .white, by: 0.5)
        case .accentOnly, .creamHeader: neutral
        }
    }

    private var headerBackground: Color {
        theming == .creamHeader ? theme.background : listBackground
    }

    private var textColor: Color { theming == .accentOnly || theming == .creamHeader ? .primary : theme.text }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").opacity(0.6)
                Text("City, region, or abbreviation").opacity(0.5)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(fieldBackground, in: RoundedRectangle(cornerRadius: 7))
            .overlay {
                if theming == .accentOnly {
                    RoundedRectangle(cornerRadius: 7).strokeBorder(theme.accent.opacity(0.7), lineWidth: 2)
                }
            }
            .padding(10)
            .background(headerBackground)
            Rectangle().fill(textColor.opacity(0.12)).frame(height: 1)
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(row.city)
                            Text(row.detail).font(.caption).opacity(0.7)
                        }
                        Spacer()
                        if row.city == "Accra" {
                            Image(systemName: "checkmark").foregroundStyle(theme.accent)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(theme.accent.opacity(row.city == "Adak" ? 0.15 : 0), in: RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 4)
            .background(listBackground)
        }
        .foregroundStyle(textColor)
        .frame(width: 260, height: 330)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.black.opacity(0.12)))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
    }

    private var fieldBackground: Color {
        switch theming {
        case .accentOnly: Color(nsColor: .textBackgroundColor)
        default: textColor.opacity(0.07)
        }
    }
}

@MainActor let pickerOptionSnapshots: [Snapshot] = [
    Snapshot(name: "picker-theming", size: CGSize(width: 620, height: 820)) {
        let options = PickerTheming.allCases
        return AnyView(
            VStack(alignment: .leading, spacing: 24) {
                ForEach([0, 2], id: \.self) { r in
                    HStack(alignment: .top, spacing: 40) {
                        ForEach(r..<r + 2, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 10) {
                                PickerOption(theming: options[i])
                                Text(options[i].rawValue).font(.callout.weight(.medium))
                            }
                        }
                    }
                }
            }
            .padding(30)
        )
    },
]
