import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

// The widget's text at a timeline entry's date. The time itself is live (formatted by the
// system from `hourMinuteFormat` and `dayPeriodFormat`), so the tests check the formats against
// fixed instants.

@Test func widgetDisplayStringsAtFixedInstant() {
    let display = WidgetDisplay(zone: zone("Asia/Tokyo"), at: jan15Noon, locale: Locale(identifier: "en_US"))
    #expect(display.cityText == "Tokyo")
    #expect(display.dateText == "Thursday, January 15")
    #expect(display.shortDateText == "Thu, Jan 15")
    #expect(display.offsetText == "UTC+9")
    #expect(display.hourMinuteFormat.format(jan15Noon) == "9:00")
    #expect(display.dayPeriodFormat?.format(jan15Noon) == "PM")
}

@Test func widgetTimeFollowsTwentyFourHourLocale() {
    let display = WidgetDisplay(zone: zone("Asia/Tokyo"), at: jan15Noon, locale: Locale(identifier: "en_GB"))
    #expect(display.hourMinuteFormat.format(jan15Noon) == "21:00")
    #expect(display.dayPeriodFormat == nil)
}

@Test func widgetDateFollowsTheZone() {
    // 02:00 UTC on January 16 is still 9 PM on the 15th in New York.
    let display = WidgetDisplay(zone: zone("America/New_York"), at: utc(2026, 1, 16, 2, 0), locale: Locale(identifier: "en_US"))
    #expect(display.dateText == "Thursday, January 15")
    #expect(display.hourMinuteFormat.format(utc(2026, 1, 16, 2, 0)) == "9:00")
    #expect(display.dayPeriodFormat?.format(utc(2026, 1, 16, 2, 0)) == "PM")
    #expect(display.timeZone.identifier == "America/New_York")
}

@Test func widgetOffsetAtTransitionIsTheNewOffset() {
    // The timeline's entry at a DST transition shows the offset that starts then.
    let display = WidgetDisplay(zone: zone("America/New_York"), at: utc(2026, 3, 8, 7, 0), locale: Locale(identifier: "en_US"))
    #expect(display.offsetText == "UTC\u{2212}4")
}

@Test func widgetDayPeriodFollowsTheZone() {
    // Noon UTC is 7 AM in New York, 9 PM in Tokyo.
    let display = WidgetDisplay(zone: zone("America/New_York"), at: jan15Noon, locale: Locale(identifier: "en_US"))
    #expect(display.hourMinuteFormat.format(jan15Noon) == "7:00")
    #expect(display.dayPeriodFormat?.format(jan15Noon) == "AM")
}
