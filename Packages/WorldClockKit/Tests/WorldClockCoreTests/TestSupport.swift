import Foundation
@testable import WorldClockCore

/// Fixed instants for tests. Times are UTC.
/// January: northern winter (no DST in New York or London; DST in Sydney).
let jan15Noon = utc(2026, 1, 15, 12, 0)
/// July: northern summer (DST in New York and London; none in Sydney).
let jul15Noon = utc(2026, 7, 15, 12, 0)

func utc(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
}

func zone(_ identifier: String) -> Zone {
    Zone(identifier: identifier)!
}

/// March 15, 2026: New York is on daylight time (from March 8) but London isn't yet (from March 29),
/// so they differ by 4 hours instead of 5.
let mar15Noon = utc(2026, 3, 15, 12, 0)
/// October 28, 2026: London is back on standard time (from October 25) but New York isn't yet
/// (until November 1), so they differ by 4 hours.
let oct28Noon = utc(2026, 10, 28, 12, 0)

func wall(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> WallTime {
    WallTime(year: year, month: month, day: day, hour: hour, minute: minute)
}
