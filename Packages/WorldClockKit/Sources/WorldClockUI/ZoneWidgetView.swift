import SwiftUI

/// The desktop widget's content, in the Clock window's look: the city in the accent at the top
/// right, the live time (AM/PM smaller) and the date centered, colors from `themes` (light or
/// dark to match the Mac). The widget target adds the container background
/// (`themes.theme(for:).background`); WidgetKit isn't imported here.
public struct ZoneWidgetView: View {
    public enum Size: Sendable {
        case small, medium
    }

    let display: WidgetDisplay
    let size: Size
    let themes: ThemePair
    let frozenTime: Date?
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { themes.theme(for: colorScheme) }

    /// - Parameter frozenTime: shows this instant instead of the live time. For snapshots only.
    public init(display: WidgetDisplay, size: Size, themes: ThemePair, frozenTime: Date? = nil) {
        self.display = display
        self.size = size
        self.themes = themes
        self.frozenTime = frozenTime
    }

    public var body: some View {
        VStack(spacing: 2) {
            time
            Text(size == .small ? display.shortDateText : display.dateText)
                .font(.system(size: 13))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(theme.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Text(display.cityText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilitySortPriority(1)
        }
        // Read as one line, city first; the time is live text, so VoiceOver reads its current value.
        .accessibilityElement(children: .combine)
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
        // Text(_:format:) formats in the environment's zone, not the format's.
        .environment(\.timeZone, display.timeZone)
    }

    @ViewBuilder private var hoursAndMinutes: some View {
        if let frozenTime {
            Text(frozenTime, format: display.hourMinuteFormat)
        } else {
            Text(.currentDate, format: display.hourMinuteFormat)
        }
    }
}
