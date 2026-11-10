import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

// The widget's text at a timeline entry's date. Hours and minutes are live (formatted by the
// system from `hourMinuteFormat`), so the tests check the format against fixed instants; AM/PM
// is `dayPeriodText`, fixed per entry (the timeline refreshes at noon and midnight).

@Test func widgetDisplayStringsAtFixedInstant() {
    let display = WidgetDisplay(zone: zone("Asia/Tokyo"), at: jan15Noon, locale: Locale(identifier: "en_US"))
    #expect(display.cityText == "Tokyo")
    #expect(display.dateText == "Thursday, January 15")
    #expect(display.shortDateText == "Thu, Jan 15")
    #expect(display.hourMinuteFormat.format(jan15Noon) == "9:00")
    #expect(display.dayPeriodText == "PM")
}

@Test func widgetTimeFollowsTwentyFourHourLocale() {
    let display = WidgetDisplay(zone: zone("Asia/Tokyo"), at: jan15Noon, locale: Locale(identifier: "en_GB"))
    #expect(display.hourMinuteFormat.format(jan15Noon) == "21:00")
    #expect(display.dayPeriodText == nil)
}

@Test func widgetDateFollowsTheZone() {
    // 02:00 UTC on January 16 is still 9 PM on the 15th in New York.
    let display = WidgetDisplay(zone: zone("America/New_York"), at: utc(2026, 1, 16, 2, 0), locale: Locale(identifier: "en_US"))
    #expect(display.dateText == "Thursday, January 15")
    #expect(display.hourMinuteFormat.format(utc(2026, 1, 16, 2, 0)) == "9:00")
    #expect(display.dayPeriodText == "PM")
    #expect(display.timeZone.identifier == "America/New_York")
}

@Test func widgetDayPeriodFollowsTheZone() {
    // Noon UTC is 7 AM in New York, 9 PM in Tokyo.
    let display = WidgetDisplay(zone: zone("America/New_York"), at: jan15Noon, locale: Locale(identifier: "en_US"))
    #expect(display.hourMinuteFormat.format(jan15Noon) == "7:00")
    #expect(display.dayPeriodText == "AM")
}

@Test func widgetTimeTextIsTheEntrysHoursAndMinutes() {
    // Fixed text the live time is laid over, so the widget sizes to what's shown.
    let display = WidgetDisplay(zone: zone("Asia/Tokyo"), at: jan15Noon, locale: Locale(identifier: "en_US"))
    #expect(display.timeText == "9:00")
}

@Test func widgetEntriesIncludeChangesInTheTimesWidth() {
    // 9 PM in Tokyo: 10 PM (two-digit hour), midnight (date), 1 AM (one digit), 10 AM.
    let dates = WidgetDisplay.entryDates(zone: zone("Asia/Tokyo"), after: jan15Noon, locale: Locale(identifier: "en_US"), count: 4)
    #expect(dates == [utc(2026, 1, 15, 13, 0), utc(2026, 1, 15, 15, 0), utc(2026, 1, 15, 16, 0), utc(2026, 1, 16, 1, 0)])
}

@Test func zeroPaddedTwentyFourHourTimeAddsNoEntries() {
    // en_GB writes 09:00, so the width never changes: only midnight and noon.
    let dates = WidgetDisplay.entryDates(zone: zone("Asia/Tokyo"), after: jan15Noon, locale: Locale(identifier: "en_GB"), count: 2)
    #expect(dates == [utc(2026, 1, 15, 15, 0), utc(2026, 1, 16, 3, 0)])
}
