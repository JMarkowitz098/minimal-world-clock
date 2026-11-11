import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

// jan15Noon is 7:00 AM Thursday in New York and 9:00 PM Thursday in Tokyo.

@Test @MainActor func liveModeTracksNow() {
    let (model, clock, ticker) = makeCompare()
    model.start()
    #expect(model.isLive)
    #expect(model.a.timeText == "7:00\(nnbsp)AM")
    #expect(model.b.timeText == "9:00\(nnbsp)PM")
    clock.now = utc(2026, 1, 15, 12, 1)
    ticker.fire()
    #expect(model.a.timeText == "7:01\(nnbsp)AM")
    #expect(model.b.timeText == "9:01\(nnbsp)PM")
    #expect(ticker.scheduledDate == utc(2026, 1, 15, 12, 2))
}

@Test @MainActor func displayStringsForBothZones() {
    let (model, _, _) = makeCompare()
    #expect(model.a.cityText == "New York")
    #expect(model.a.dateText == "Thursday, January 15")
    #expect(model.b.cityText == "Tokyo")
    #expect(model.b.dateText == "Thursday, January 15")
    #expect(model.differenceText == "+14 h")
}

@Test @MainActor func scrubbingSetsTheInstantFromZoneAWallTime() {
    let (model, _, _) = makeCompare()
    model.scrub(toMinuteOfDay: 15 * 60)  // 3 PM in New York
    #expect(!model.isLive)
    #expect(model.instant == utc(2026, 1, 15, 20, 0))
    #expect(model.a.timeText == "3:00\(nnbsp)PM")
    #expect(model.scrubberMinuteOfDay == 15 * 60)
}

@Test @MainActor func zoneBFollowsTheScrubbedTime() {
    let (model, _, _) = makeCompare()
    model.scrub(toMinuteOfDay: 15 * 60)
    #expect(model.b.timeText == "5:00\(nnbsp)AM")
    #expect(model.b.dateText == "Friday, January 16")
    #expect(model.dayRelationText == "Next day")
}

@Test @MainActor func scrubberShowsZoneATimeWhenLive() {
    let (model, _, _) = makeCompare(at: utc(2026, 1, 15, 12, 7, 30))
    #expect(model.scrubberMinuteOfDay == 7 * 60 + 7)
}

@Test @MainActor func scrubbedTimeStaysPutAsTimePasses() {
    let (model, clock, ticker) = makeCompare()
    model.start()
    model.scrub(toMinuteOfDay: 15 * 60)
    // Past midnight in New York: the scrub keeps the day it was set on.
    clock.now = utc(2026, 1, 16, 6, 0)
    ticker.fire()
    #expect(model.instant == utc(2026, 1, 15, 20, 0))
    model.scrub(toMinuteOfDay: 16 * 60)
    #expect(model.instant == utc(2026, 1, 15, 21, 0))
}

@Test @MainActor func scrubIntoADSTGapMovesForward() {
    // March 8, 2026: New York skips 2:00–3:00 AM.
    let (model, _, _) = makeCompare(at: utc(2026, 3, 8, 12, 0))
    model.scrub(toMinuteOfDay: 2 * 60 + 30)
    #expect(model.a.timeText == "3:30\(nnbsp)AM")
}

@Test @MainActor func nowReturnsToLive() {
    let (model, clock, _) = makeCompare()
    model.scrub(toMinuteOfDay: 15 * 60)
    clock.now = utc(2026, 1, 15, 13, 0)
    model.returnToNow()
    #expect(model.isLive)
    #expect(model.instant == utc(2026, 1, 15, 13, 0))
    #expect(model.a.timeText == "8:00\(nnbsp)AM")
}

@Test @MainActor func swapExchangesZones() {
    let (model, _, _) = makeCompare()
    model.swap()
    #expect(model.a.cityText == "Tokyo")
    #expect(model.b.cityText == "New York")
    #expect(model.a.timeText == "9:00\(nnbsp)PM")
    #expect(model.differenceText == "\u{2212}14 h")
}

@Test @MainActor func swapKeepsTheScrubbedInstant() {
    let (model, _, _) = makeCompare()
    model.scrub(toMinuteOfDay: 15 * 60)
    model.swap()
    #expect(!model.isLive)
    #expect(model.instant == utc(2026, 1, 15, 20, 0))
    #expect(model.a.timeText == "5:00\(nnbsp)AM")
    #expect(model.scrubberMinuteOfDay == 5 * 60)
    #expect(model.dayRelationText == "Previous day")
}

@Test @MainActor func changingZoneAKeepsTheScrubbedWallTime() {
    let (model, _, _) = makeCompare()
    model.scrub(toMinuteOfDay: 15 * 60)
    model.selectA(place("Europe/London"))
    #expect(model.a.timeText == "3:00\(nnbsp)PM")
    #expect(model.instant == utc(2026, 1, 15, 15, 0))
    #expect(model.b.timeText == "12:00\(nnbsp)AM")
}

@Test @MainActor func changingZoneBKeepsTheInstant() {
    let (model, _, _) = makeCompare()
    model.scrub(toMinuteOfDay: 15 * 60)
    model.selectB(place("Europe/London"))
    #expect(model.instant == utc(2026, 1, 15, 20, 0))
    #expect(model.b.timeText == "8:00\(nnbsp)PM")
    #expect(model.differenceText == "+5 h")
}

@Test @MainActor func dayRelationLabels() {
    let (model, _, _) = makeCompare(a: zone("Europe/London"), b: zone("Europe/Paris"))
    #expect(model.dayRelationText == "Same day")
    model.selectB(place("Pacific/Kiritimati"))  // UTC+14: 2 AM Friday at 12:00 UTC Thursday
    #expect(model.dayRelationText == "Next day")
    model.selectA(place("Pacific/Kiritimati"))
    model.selectB(place("Pacific/Pago_Pago"))  // UTC−11: 1 AM Thursday vs. 2 AM Friday
    #expect(model.dayRelationText == "Previous day")
}

@Test @MainActor func dayRelationTwoDaysApart() {
    // 10:30 UTC: 00:30 Friday in Kiritimati, 23:30 Wednesday in Pago Pago.
    let (model, _, _) = makeCompare(at: utc(2026, 1, 15, 10, 30), a: zone("Pacific/Kiritimati"), b: zone("Pacific/Pago_Pago"))
    #expect(model.dayRelationText == "2 days earlier")
    model.swap()
    #expect(model.dayRelationText == "2 days later")
}

@Test @MainActor func zoneBDateNamesItsDayWhenItDiffers() {
    // 12:00 UTC Thursday: 2 AM Friday in Kiritimati (UTC+14).
    let (model, _, _) = makeCompare(a: zone("Europe/London"), b: zone("Pacific/Kiritimati"))
    #expect(model.zoneBDateText == "Friday, January 16 · next day")
    model.selectB(place("America/New_York"))
    model.selectA(place("Pacific/Kiritimati"))
    #expect(model.zoneBDateText == "Thursday, January 15 · previous day")
}

@Test @MainActor func widestZoneBDateUsesTheLongestDayLabel() {
    // The window sizes itself by this, so it must be at least as wide as any day label B's date
    // can carry: "2 days earlier" is longer than "previous day".
    let (model, _, _) = makeCompare(a: zone("Europe/London"), b: zone("Europe/Paris"))
    #expect(model.widestZoneBDateText == "Thursday, January 15 · 2 days earlier")
}

@Test @MainActor func zoneBDateIsPlainOnTheSameDay() {
    let (model, _, _) = makeCompare(a: zone("Europe/London"), b: zone("Europe/Paris"))
    #expect(model.zoneBDateText == "Thursday, January 15")
}

@Test @MainActor func typingZoneATimeScrubsToIt() {
    let (model, _, _) = makeCompare()  // live: 7:00 AM in New York, 9:00 PM in Tokyo
    #expect(model.typeTimeA("3:15 pm"))
    #expect(!model.isLive)
    #expect(model.a.timeText == "3:15\(nnbsp)PM")
    #expect(model.a.dateText == "Thursday, January 15")
    #expect(model.b.timeText == "5:15\(nnbsp)AM")
}

@Test @MainActor func typingZoneBTimeKeepsBsDateAndMovesA() {
    let (model, _, _) = makeCompare()
    // Tokyo shows 9 PM Thursday; 9 AM Thursday in Tokyo is 7 PM Wednesday in New York.
    #expect(model.typeTimeB("9 am"))
    #expect(model.b.timeText == "9:00\(nnbsp)AM")
    #expect(model.b.dateText == "Thursday, January 15")
    #expect(model.a.timeText == "7:00\(nnbsp)PM")
    #expect(model.a.dateText == "Wednesday, January 14")
}

@Test @MainActor func typedTimeWithoutDayPeriodKeepsTheShownHalf() {
    let (model, _, _) = makeCompare()  // Tokyo shows 9 PM
    #expect(model.typeTimeB("10"))
    #expect(model.b.timeText == "10:00\(nnbsp)PM")
}

@Test @MainActor func typedTimeInTwentyFourHourLocale() {
    let (model, _, _) = makeCompare(locale: "en_GB")  // Tokyo shows 21:00
    #expect(model.typeTimeB("10"))
    #expect(model.b.timeText == "10:00")
}

@Test @MainActor func invalidTypedTimeChangesNothing() {
    let (model, _, _) = makeCompare()
    #expect(!model.typeTimeA("25:00"))
    #expect(!model.typeTimeB("soon"))
    #expect(model.isLive)
}

@Test @MainActor func sameZoneReadsSameTime() {
    let (model, _, _) = makeCompare(a: zone("Asia/Tokyo"), b: zone("Asia/Tokyo"))
    #expect(model.differenceText == "Same time")
    #expect(model.dayRelationText == "Same day")
}

@Test @MainActor func stopCancelsTheCompareTicker() {
    let (model, _, ticker) = makeCompare()
    model.start()
    model.stop()
    #expect(ticker.scheduledDate == nil)
}

@Test @MainActor func compareZonesPersistAcrossLaunches() {
    let store = InMemorySettingsStore()
    let (first, _, _) = makeCompare(store: store)
    first.selectA(place("Europe/London"))
    first.selectB(place("Australia/Sydney"))
    let (second, _, _) = makeCompare(store: store)
    #expect(second.zoneA == zone("Europe/London"))
    #expect(second.zoneB == zone("Australia/Sydney"))
}

@Test @MainActor func swapPersists() {
    let store = InMemorySettingsStore()
    let (first, _, _) = makeCompare(store: store)
    first.swap()
    let (second, _, _) = makeCompare(store: store)
    #expect(second.zoneA == zone("Asia/Tokyo"))
    #expect(second.zoneB == zone("America/New_York"))
}

@Test @MainActor func missingOrCorruptCompareZonesUseDefaults() {
    let store = InMemorySettingsStore()
    store.setData(Data("garbage".utf8), forKey: SettingsKey.compareZoneA)
    let (model, _, _) = makeCompare(store: store, a: zone("Europe/Paris"), b: zone("UTC"))
    #expect(model.zoneA == zone("Europe/Paris"))
    #expect(model.zoneB == zone("UTC"))
}

// A city picked inside a zone (M9) names that side, in text and for VoiceOver.
@Test @MainActor func compareShowsPickedCities() {
    let store = InMemorySettingsStore()
    let (model, _, _) = makeCompare(store: store)
    model.selectA(Place(zone("America/Los_Angeles"), city: "San Francisco"))
    #expect(model.a.cityText == "San Francisco")
    #expect(model.spokenDifference == "Tokyo is 17 hours ahead of San Francisco")
    model.swap()
    #expect(model.b.cityText == "San Francisco")
    let (relaunched, _, _) = makeCompare(store: store)
    #expect(relaunched.placeB == Place(zone("America/Los_Angeles"), city: "San Francisco"))
}

@Test @MainActor func hiddenCompareWindowStopsTicking() {
    let (model, clock, ticker) = makeCompare()
    model.start()
    model.setVisible(false)
    #expect(ticker.scheduledDate == nil)
    clock.now = utc(2026, 1, 15, 13, 0, 10)
    model.setVisible(true)
    #expect(model.a.timeText == "8:00\(nnbsp)AM")
    #expect(ticker.scheduledDate == utc(2026, 1, 15, 13, 1))
}
