import SwiftUI

/// A zone's time: a title (the zone name, or a control showing it), the time in large type,
/// and the date and UTC offset below. Reused by the Clock and Compare windows.
public struct TimeDisplay<Title: View>: View {
    let time: AttributedString
    let date: String
    let offset: String
    let title: Title

    /// - Parameter time: the formatted time with its parts marked (`ZoneDisplay.time`).
    public init(time: AttributedString, date: String, offset: String, @ViewBuilder title: () -> Title) {
        self.time = time
        self.date = date
        self.offset = offset
        self.title = title()
    }

    public var body: some View {
        VStack(spacing: 4) {
            title
            VStack(spacing: 4) {
                Text(TimeStyle.shrinkingDayPeriod(time, timeSize: TimeStyle.windowTimeSize))
                    .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("\(date) · \(offset)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(String(time.characters)), \(date), \(offset)")
        }
    }
}
