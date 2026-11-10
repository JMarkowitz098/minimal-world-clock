import SwiftUI
import WorldClockCore
import WorldClockUI

// M6 design exploration, round 3 (asked for by the user): the border moved in from the widget's
// edge (macOS draws its own light line along the edge), and layouts with the time at the bottom.
// Not app code: the chosen option moves into `ZoneWidgetView` / `WidgetBackground`, then this
// file is deleted.

struct WidgetLayoutVariant {
    enum Layout {
        /// Today's: city top-right, time and date centered.
        case centered
        /// City and date top-left, time bottom-left.
        case bottomLeading
        /// City top-right; time bottom-left with the date under it.
        case bottomLeadingDateBelow
        /// City top-left; time and date bottom-right.
        case bottomTrailing
        /// City top-right; time centered at the bottom, date above it.
        case bottomCentered
    }

    let caption: String
    var layout: Layout
    /// The border's distance from the widget's edge and its width.
    var inset: CGFloat = 6
    var width: CGFloat = 1.5

    static let round3: [WidgetLayoutVariant] = [
        WidgetLayoutVariant(caption: "A · Today's layout, border 6 pt in", layout: .centered),
        WidgetLayoutVariant(caption: "B · City and date top-left, time bottom-left", layout: .bottomLeading),
        WidgetLayoutVariant(caption: "C · City top-right, time bottom-left with the date under it", layout: .bottomLeadingDateBelow),
        WidgetLayoutVariant(caption: "D · City top-left, time and date bottom-right", layout: .bottomTrailing),
        WidgetLayoutVariant(caption: "E · City top-right, date then time centered at the bottom", layout: .bottomCentered),
        WidgetLayoutVariant(caption: "F · B with the border 4 pt in, 2 pt wide", layout: .bottomLeading, inset: 4, width: 2),
    ]
}

struct WidgetLayoutOption: View {
    let variant: WidgetLayoutVariant
    let display: WidgetDisplay
    let medium: Bool
    @Environment(\.colorScheme) private var scheme
    private var theme: Theme { ThemePair.solarized.theme(for: scheme) }
    private let radius: CGFloat = 22

    var body: some View {
        content
            .foregroundStyle(theme.text)
            .padding(16)
            .frame(width: medium ? 364 : 170, height: 170)
            .background(theme.background, in: RoundedRectangle(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius - variant.inset)
                    .strokeBorder(theme.text, lineWidth: variant.width)
                    .padding(variant.inset)
            }
    }

    private var timeSize: CGFloat { medium ? 56 : 42 }
    private var date: String { medium ? display.dateText : display.shortDateText }

    @ViewBuilder private var content: some View {
        switch variant.layout {
        case .centered:
            VStack(spacing: 2) { time; dateText }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) { city }
        case .bottomLeading:
            VStack(alignment: .leading, spacing: 2) {
                city
                dateText
                Spacer(minLength: 0)
                time
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        case .bottomLeadingDateBelow:
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                time
                dateText
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .overlay(alignment: .topTrailing) { city }
        case .bottomTrailing:
            VStack(alignment: .trailing, spacing: 0) {
                Spacer(minLength: 0)
                time
                dateText
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            .overlay(alignment: .topLeading) { city }
        case .bottomCentered:
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                dateText
                time
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .topTrailing) { city }
        }
    }

    private var city: some View {
        Text(display.cityText)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(theme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var dateText: some View {
        Text(date).font(.system(size: 13)).lineLimit(1).minimumScaleFactor(0.7)
    }

    private var time: some View {
        HStack(alignment: .firstTextBaseline, spacing: (timeSize * 0.12).rounded()) {
            Text(display.timeText)
            if let dayPeriod = display.dayPeriodText {
                Text(dayPeriod).font(.system(size: (timeSize * 0.4).rounded()))
            }
        }
        .font(TimeStyle.timeFont(size: timeSize))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

/// Every option, small beside medium. The small one shows a two-digit hour (10:00 PM).
struct WidgetLayoutSheet: View {
    private let tokyo = Zone(identifier: "Asia/Tokyo")!
    private let tenPM = jan15Noon.addingTimeInterval(3600)

    var body: some View {
        let display = WidgetDisplay(zone: tokyo, at: tenPM, locale: Locale(identifier: "en_US"))
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(WidgetLayoutVariant.round3.enumerated()), id: \.offset) { _, variant in
                VStack(alignment: .leading, spacing: 6) {
                    Text(variant.caption).font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary)
                    HStack(spacing: 18) {
                        WidgetLayoutOption(variant: variant, display: display, medium: false)
                        WidgetLayoutOption(variant: variant, display: display, medium: true)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.6, green: 0.25, blue: 0.15))
    }
}
