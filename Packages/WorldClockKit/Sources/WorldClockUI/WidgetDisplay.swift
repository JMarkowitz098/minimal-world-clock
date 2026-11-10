import Foundation
import WorldClockCore

/// What the desktop widget shows for one zone at a timeline entry's date. The date and offset
/// are fixed strings (the timeline refreshes when they change, see `Zone.nextDisplayChange`);
/// the time is live, drawn by the system from `timeFormat`.
public struct WidgetDisplay: Equatable, Sendable {
    /// "Tokyo"
    public var cityText: String
    /// "Thursday, January 15" (medium widget)
    public var dateText: String
    /// "Thu, Jan 15" (small widget)
    public var shortDateText: String
    /// "UTC+9"
    public var offsetText: String
    /// Hours and minutes in the zone, following the locale's 12/24-hour preference.
    public var timeFormat: Date.FormatStyle
    /// The zone's time zone. SwiftUI's `Text(_:format:)` replaces the format's time zone with
    /// the environment's, so the view must also set `\.timeZone` to this.
    public var timeZone: TimeZone

    public init(zone: Zone, at instant: Date, locale: Locale) {
        let display = ZoneFormatter(zone: zone, locale: locale).display(at: instant)
        let shortDate = DateFormatter()
        shortDate.locale = locale
        shortDate.timeZone = zone.timeZone
        shortDate.setLocalizedDateFormatFromTemplate("EEEMMMd")
        cityText = display.cityText
        dateText = display.dateText
        shortDateText = shortDate.string(from: instant)
        offsetText = display.offsetText
        timeFormat = Date.FormatStyle(locale: locale, timeZone: zone.timeZone).hour().minute()
        timeZone = zone.timeZone
    }
}
