import Foundation
import WorldClockCore

/// One zone's display strings at an instant, as the Clock and Compare windows show them.
public struct ZoneDisplay: Equatable, Sendable {
    /// "9:00 PM" or "21:00", following the locale's 12/24-hour preference.
    public var timeText: String
    /// `timeText` with its parts marked (`dateField`), so views can draw AM/PM smaller
    /// (`TimeStyle.shrinkingDayPeriod`).
    public var time: AttributedString
    /// "Thursday, January 15", the date in the zone.
    public var dateText: String
    /// "Tokyo"
    public var cityText: String
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

    private var time: Date.FormatStyle
    private let date: DateFormatter

    init(zone: Zone, locale: Locale) {
        self.zone = zone
        time = Date.FormatStyle(locale: locale, timeZone: zone.timeZone).hour().minute()
        date = Self.formatter(template: "EEEEMMMMd", locale: locale, zone: zone)
    }

    func display(at instant: Date) -> ZoneDisplay {
        let time = time.attributedStyle.format(instant)
        return ZoneDisplay(
            timeText: String(time.characters),
            time: time,
            dateText: date.string(from: instant),
            cityText: zone.city
        )
    }

    /// Hours and minutes in `zone` without AM/PM ("9:00", or "21:00" in a 24-hour locale).
    static func hourMinuteFormat(locale: Locale, zone: Zone) -> Date.FormatStyle {
        Date.FormatStyle(locale: locale, timeZone: zone.timeZone).hour(.defaultDigits(amPM: .omitted)).minute()
    }

    private static func formatter(template: String, locale: Locale, zone: Zone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = zone.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}
