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
                .font(.system(size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(theme.text)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Text(display.cityText)
                .font(.system(size: 13, weight: .semibold))
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

    /// Hours and minutes, then AM/PM at the windows' smaller size. Two `Text`s with system
    /// formats rather than one styled string: the system draws the widget from an archived
    /// view and can't use our own format types (see `WidgetDisplay.dayPeriodFormat`).
    private var time: some View {
        HStack(alignment: .firstTextBaseline, spacing: (timeSize * 0.12).rounded()) {
            // On the desktop, live text takes more width than it shows and draws at its
            // leading edge; aligning the digits right and AM/PM left keeps them together.
            liveText(display.hourMinuteFormat)
                .multilineTextAlignment(display.dayPeriodFormat == nil ? .center : .trailing)
            if let dayPeriod = display.dayPeriodFormat {
                liveText(dayPeriod)
                    .font(.system(size: (timeSize * TimeStyle.dayPeriodScale).rounded()))
                    .multilineTextAlignment(.leading)
            }
        }
        .font(TimeStyle.timeFont(size: timeSize))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        // Text(_:format:) formats in the environment's zone, not the format's.
        .environment(\.timeZone, display.timeZone)
    }

    @ViewBuilder private func liveText<F: DiscreteFormatStyle>(_ format: F) -> some View
    where F.FormatInput == Date, F.FormatOutput == String {
        if let frozenTime {
            Text(frozenTime, format: format)
        } else {
            Text(.currentDate, format: format)
        }
    }
}
