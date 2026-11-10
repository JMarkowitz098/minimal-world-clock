import Foundation
import WorldClockCore

extension Locale {
    /// Whether this locale shows 12-hour time (with AM/PM) by default.
    var usesTwelveHourTime: Bool {
        DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: self)?.contains("a") ?? false
    }

    /// This locale with the Settings window's 12/24-hour choice applied (`en_US@hours=h23`).
    /// Every formatter built from the result follows it: the windows' times, Compare's strip
    /// labels and typed times, and the widget. `.system` leaves the locale as it is.
    public func applying(_ format: TimeFormat) -> Locale {
        var components = Locale.Components(locale: self)
        switch format {
        case .system: return self
        case .twelveHour: components.hourCycle = .oneToTwelve
        case .twentyFourHour: components.hourCycle = .zeroToTwentyThree
        }
        return Locale(components: components)
    }
}
