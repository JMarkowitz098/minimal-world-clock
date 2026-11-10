import SwiftUI

/// The desktop widget's content: city, live time, and date (plus the UTC offset when there's
/// room). The widget target adds the container background; WidgetKit isn't imported here.
public struct ZoneWidgetView: View {
    public enum Size: Sendable {
        case small, medium
    }

    let display: WidgetDisplay
    let size: Size
    let frozenTime: Date?

    /// - Parameter frozenTime: shows this instant instead of the live time. For snapshots only.
    public init(display: WidgetDisplay, size: Size, frozenTime: Date? = nil) {
        self.display = display
        self.size = size
        self.frozenTime = frozenTime
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(display.cityText)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            time
                .font(.system(size: size == .small ? 34 : 48, weight: .light))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                // Text(_:format:) formats in the environment's zone, not the format's.
                .environment(\.timeZone, display.timeZone)
            Text(size == .small ? display.shortDateText : "\(display.dateText) · \(display.offsetText)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Read as one line; the time is live text, so VoiceOver reads its current value.
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var time: some View {
        if let frozenTime {
            Text(frozenTime, format: display.timeFormat)
        } else {
            Text(.currentDate, format: display.timeFormat)
        }
    }
}
