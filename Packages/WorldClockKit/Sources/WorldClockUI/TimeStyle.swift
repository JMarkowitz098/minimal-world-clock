import SwiftUI

/// The look shared by both windows and the widget: type sizes, and (windows only) the time
/// drawn with its day period (AM/PM) smaller than the digits. The widget can't: see
/// `ZoneWidgetView.time`.
public enum TimeStyle {
    /// The large time in the Clock and Compare windows.
    public static let windowTimeSize: CGFloat = 56
    /// The time in the small and medium widgets.
    static let smallWidgetTimeSize: CGFloat = 36
    static let mediumWidgetTimeSize: CGFloat = 48
    static let timeWeight: Font.Weight = .light
    /// AM/PM as a fraction of the time's size.
    static let dayPeriodScale: CGFloat = 0.4

    /// The large time's font.
    public static func timeFont(size: CGFloat) -> Font {
        .system(size: size, weight: timeWeight)
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
