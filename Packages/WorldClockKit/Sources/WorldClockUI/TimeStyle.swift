import SwiftUI

/// The look shared by both windows and the widget: type sizes, and the time drawn with its day
/// period (AM/PM) smaller than the digits (the widget draws it as two texts instead: see
/// `ZoneWidgetView.time`).
public enum TimeStyle {
    /// The large time in the Clock and Compare windows.
    public static let windowTimeSize: CGFloat = 56
    /// The time in the small and medium widgets.
    static let smallWidgetTimeSize: CGFloat = 42
    static let mediumWidgetTimeSize: CGFloat = 56
    static let timeWeight: Font.Weight = .light
    /// AM/PM as a fraction of the time's size.
    static let dayPeriodScale: CGFloat = 0.4

    /// The large time's font.
    public static func timeFont(size: CGFloat) -> Font {
        .system(size: size, weight: timeWeight)
    }

    /// `time` with a one-digit hour widened to two ("7:00 AM" → "87:00 AM"). Digits are
    /// monospaced, so this is as wide as the time ever gets; the Compare window sizes itself by
    /// it, so its scale doesn't change while scrubbing from 9:45 to 10:00.
    public static func widestTime(_ time: AttributedString) -> AttributedString {
        let text = String(time.characters)
        guard let separator = text.firstIndex(where: { !$0.isNumber }),
              text.distance(from: text.startIndex, to: separator) == 1 else { return time }
        var wide = time
        wide.insert(AttributedString("8"), at: wide.startIndex)
        return wide
    }

    /// `time` (a formatted time with `dateField` attributes) with its day period set in a
    /// smaller font; every other run keeps the font of the `Text` it's drawn in.
    public static func shrinkingDayPeriod(_ time: AttributedString, timeSize: CGFloat) -> AttributedString {
        var styled = time
        for run in styled.runs where run.foundation.dateField == .amPM {
            styled[run.range].swiftUI.font = .system(size: (timeSize * dayPeriodScale).rounded(), weight: .regular)
        }
        return styled
    }
}
