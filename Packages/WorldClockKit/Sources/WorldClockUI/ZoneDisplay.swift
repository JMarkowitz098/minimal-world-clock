import Foundation
import WorldClockCore

/// One zone's display strings at an instant, as the Clock and Compare windows show them.
public struct ZoneDisplay: Equatable, Sendable {
    /// "9:00 PM" or "21:00", following the locale's 12/24-hour preference.
    public var timeText: String
    /// "Thursday, January 15", the date in the zone.
    public var dateText: String
    /// "Tokyo"
    public var cityText: String
    /// "UTC+9"
    public var offsetText: String
}

/// Builds `ZoneDisplay`s for one zone at a time. Keeps its formatters, since creating a
/// `DateFormatter` is costly.
final class ZoneFormatter {
    var zone: Zone {
        didSet {
            time.timeZone = zone.timeZone
            date.timeZone = zone.timeZone
        }
    }

    private let time: DateFormatter
    private let date: DateFormatter

    init(zone: Zone, locale: Locale) {
        self.zone = zone
        time = Self.formatter(template: "jmm", locale: locale, zone: zone)
        date = Self.formatter(template: "EEEEMMMMd", locale: locale, zone: zone)
    }

    func display(at instant: Date) -> ZoneDisplay {
        ZoneDisplay(
            timeText: time.string(from: instant),
            dateText: date.string(from: instant),
            cityText: zone.city,
            offsetText: zone.utcOffsetText(at: instant)
        )
    }

    private static func formatter(template: String, locale: Locale, zone: Zone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = zone.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}
