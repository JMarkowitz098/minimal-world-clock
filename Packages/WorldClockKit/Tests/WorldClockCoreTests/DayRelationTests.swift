import Foundation
import Testing
@testable import WorldClockCore

@Test func sameZoneIsToday() {
    let tokyo = zone("Asia/Tokyo")
    #expect(tokyo.dayRelation(from: tokyo, at: jan15Noon) == .today)
}

@Test func dayRelationChangesAtMidnight() {
    let newYork = zone("America/New_York"), tokyo = zone("Asia/Tokyo")
    // 12:00 UTC: Tokyo 21:00 and New York 07:00, both on January 15.
    #expect(tokyo.dayRelation(from: newYork, at: jan15Noon) == .today)
    // 16:00 UTC: Tokyo 01:00 on the 16th, New York 11:00 on the 15th.
    let later = utc(2026, 1, 15, 16, 0)
    #expect(tokyo.dayRelation(from: newYork, at: later) == .tomorrow)
    #expect(newYork.dayRelation(from: tokyo, at: later) == .yesterday)
}

@Test func kiribatiIsTomorrowFromAmericanSamoa() {
    // Kiritimati is UTC+14 and Pago Pago UTC−11: 25 hours apart across the date line.
    let kiritimati = zone("Pacific/Kiritimati"), pagoPago = zone("Pacific/Pago_Pago")
    #expect(kiritimati.dayRelation(from: pagoPago, at: jan15Noon) == .tomorrow)
    #expect(pagoPago.dayRelation(from: kiritimati, at: jan15Noon) == .yesterday)
    #expect(kiritimati.offsetText(from: pagoPago, at: jan15Noon) == "+25 h")
}

@Test func samoaAndAmericanSamoaShareClockTimeButNotDate() {
    // Apia (UTC+13) and Pago Pago (UTC−11) show the same time, a day apart.
    let apia = zone("Pacific/Apia"), pagoPago = zone("Pacific/Pago_Pago")
    #expect(apia.wallTime(at: jan15Noon).hour == pagoPago.wallTime(at: jan15Noon).hour)
    #expect(apia.dayRelation(from: pagoPago, at: jan15Noon) == .tomorrow)
    #expect(apia.offsetText(from: pagoPago, at: jan15Noon) == "+24 h")
}

@Test func extremeZonesCanBeTwoDaysApart() {
    // Kiritimati (UTC+14) and Pago Pago (UTC−11) are 25 hours apart. At 10:30 UTC on January 15
    // it is 00:30 on the 16th in Kiritimati and 23:30 on the 14th in Pago Pago.
    let kiritimati = zone("Pacific/Kiritimati"), pagoPago = zone("Pacific/Pago_Pago")
    let instant = utc(2026, 1, 15, 10, 30)
    #expect(kiritimati.dayRelation(from: pagoPago, at: instant) == .days(2))
    #expect(pagoPago.dayRelation(from: kiritimati, at: instant) == .days(-2))
}
