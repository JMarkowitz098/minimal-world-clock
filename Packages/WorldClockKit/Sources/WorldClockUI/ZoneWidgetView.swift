import SwiftUI

/// The desktop widget's content, in `\.theme`'s colors. Medium
/// has the Clock window's look: the city in the accent at the top right, the live time (AM/PM
/// smaller) and the date centered. Small stacks the city and date at the top left and the time
/// at the bottom left (chosen by the user in M6: "like the Apple Watch"). The widget target adds
/// the container background (`WidgetBackground`); WidgetKit isn't imported here.
public struct ZoneWidgetView: View {
    public enum Size: Sendable {
        case small, medium
    }

    let display: WidgetDisplay
    let size: Size
    let frozenTime: Date?
    @Environment(\.theme) private var theme

    /// - Parameter frozenTime: shows this instant instead of the live time. For snapshots only.
    public init(display: WidgetDisplay, size: Size, frozenTime: Date? = nil) {
        self.display = display
        self.size = size
        self.frozenTime = frozenTime
    }

    public var body: some View {
        Group {
            switch size {
            case .small:
                VStack(alignment: .leading, spacing: 2) {
                    city
                    date
                    Spacer(minLength: 0)
                    time
                        // The time's text box leaves room below the digits for descenders, so it
                        // looked raised; this lines the digits up with the bottom margin as the
                        // city's letters line up with the top (measured on snapshots).
                        .offset(y: 5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            case .medium:
                VStack(spacing: 2) {
                    time
                    date
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) { city }
            }
        }
        .foregroundStyle(theme.text)
        // Read as one line, city first; the time is live text, so VoiceOver reads its current value.
        .accessibilityElement(children: .combine)
    }

    private var city: some View {
        Text(display.cityText)
            .font(.system(size: TimeStyle.widgetCitySize, weight: .semibold))
            .foregroundStyle(theme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .accessibilitySortPriority(1)
    }

    private var date: some View {
        Text(size == .small ? display.shortDateText : display.dateText)
            .font(.system(size: TimeStyle.widgetDateSize))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var timeSize: CGFloat {
        size == .small ? TimeStyle.smallWidgetTimeSize : TimeStyle.mediumWidgetTimeSize
    }

    /// Live hours and minutes, then AM/PM (fixed text, see `WidgetDisplay.dayPeriodText`) at the
    /// windows' smaller size. Two `Text`s rather than one styled string: the system draws the
    /// widget from an archived view and can't use our own format types for live text.
    private var time: some View {
        HStack(alignment: .firstTextBaseline, spacing: (timeSize * 0.12).rounded()) {
            // The fixed text sizes the time; the live time is drawn in exactly that space (on
            // the desktop it would otherwise take all the width it can and push off center).
            Text(display.timeText)
                .hidden()
                .overlay { hoursAndMinutes }
            if let dayPeriod = display.dayPeriodText {
                Text(dayPeriod)
                    .font(.system(size: (timeSize * TimeStyle.dayPeriodScale).rounded()))
            }
        }
        .font(TimeStyle.timeFont(size: timeSize))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        // Text(_:format:) formats in the environment's zone and locale, not the format's.
        .environment(\.timeZone, display.timeZone)
        .environment(\.locale, display.locale)
    }

    @ViewBuilder private var hoursAndMinutes: some View {
        if let frozenTime {
            Text(frozenTime, format: display.hourMinuteFormat)
        } else {
            Text(.currentDate, format: display.hourMinuteFormat)
        }
    }
}
