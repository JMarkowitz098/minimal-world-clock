import SwiftUI

/// A zone's time: a title (the zone name, or a control showing it), the time in large type,
/// and the date and UTC offset below. Reused by the Clock and Compare windows.
public struct TimeDisplay<Title: View>: View {
    let time: String
    let date: String
    let offset: String
    let title: Title

    public init(time: String, date: String, offset: String, @ViewBuilder title: () -> Title) {
        self.time = time
        self.date = date
        self.offset = offset
        self.title = title()
    }

    public var body: some View {
        VStack(spacing: 4) {
            title
            VStack(spacing: 4) {
                Text(time)
                    .font(.system(size: 56, weight: .light))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text("\(date) · \(offset)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(time), \(date), \(offset)")
        }
    }
}
