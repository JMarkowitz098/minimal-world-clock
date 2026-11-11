import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

@Test @MainActor func displayStringsAtFixedInstant() {
    let (model, _, _) = makeClock()
    #expect(model.timeText == "9:00\(nnbsp)PM")
    #expect(model.dateText == "Thursday, January 15")
    #expect(model.cityText == "Tokyo")
}

@Test @MainActor func dateFollowsTheZoneNotUTC() {
    // 05:00 UTC on January 15 is still January 14 in Pago Pago (UTC−11).
    let (model, _, _) = makeClock(at: utc(2026, 1, 15, 5, 0), defaultZone: zone("Pacific/Pago_Pago"))
    #expect(model.timeText == "6:00\(nnbsp)PM")
    #expect(model.dateText == "Wednesday, January 14")
}

@Test @MainActor func twentyFourHourLocaleShowsTwentyFourHourTime() {
    let model = ClockViewModel(
        store: InMemorySettingsStore(), defaultZone: zone("Asia/Tokyo"), locale: Locale(identifier: "en_GB"),
        clock: { jan15Noon }, ticker: FakeTicker()
    )
    #expect(model.timeText == "21:00")
}

@Test @MainActor func nextTickIsAtNextMinuteBoundary() {
    let (model, _, ticker) = makeClock(at: utc(2026, 1, 15, 12, 0, 25))
    model.start()
    #expect(ticker.scheduledDate == utc(2026, 1, 15, 12, 1))
}

@Test @MainActor func tickOnABoundarySchedulesTheFollowingMinute() {
    let (model, clock, ticker) = makeClock()
    model.start()
    clock.now = utc(2026, 1, 15, 12, 1)
    ticker.fire()
    #expect(ticker.scheduledDate == utc(2026, 1, 15, 12, 2))
}

@Test @MainActor func minuteRollsOverOnTick() {
    let (model, clock, ticker) = makeClock(at: utc(2026, 1, 15, 12, 0, 59))
    model.start()
    #expect(model.timeText == "9:00\(nnbsp)PM")
    clock.now = utc(2026, 1, 15, 12, 1)
    ticker.fire()
    #expect(model.timeText == "9:01\(nnbsp)PM")
}

@Test @MainActor func startRefreshesStaleTime() {
    // The window was hidden (ticker stopped) while time moved on.
    let (model, clock, _) = makeClock()
    clock.now = utc(2026, 1, 15, 15, 30)
    model.start()
    #expect(model.timeText == "12:30\(nnbsp)AM")
    #expect(model.dateText == "Friday, January 16")
}

@Test @MainActor func stopCancelsTheTicker() {
    let (model, _, ticker) = makeClock()
    model.start()
    model.stop()
    #expect(ticker.scheduledDate == nil)
}

@Test @MainActor func changingZoneUpdatesDisplay() {
    let (model, _, _) = makeClock()
    model.select(place("America/New_York"))
    #expect(model.zone == zone("America/New_York"))
    #expect(model.timeText == "7:00\(nnbsp)AM")
    #expect(model.cityText == "New York")
}

@Test @MainActor func chosenZonePersistsAcrossLaunches() {
    let store = InMemorySettingsStore()
    let (first, _, _) = makeClock(store: store)
    first.select(place("Europe/London"))
    // A new model over the same store stands in for a relaunch.
    let (second, _, _) = makeClock(store: store)
    #expect(second.zone == zone("Europe/London"))
}

@Test @MainActor func missingSavedZoneUsesDefault() {
    let (model, _, _) = makeClock(store: InMemorySettingsStore(), defaultZone: zone("Europe/Paris"))
    #expect(model.zone == zone("Europe/Paris"))
}

@Test @MainActor func corruptSavedZoneUsesDefault() {
    let store = InMemorySettingsStore()
    store.setData(Data("garbage".utf8), forKey: SettingsKey.clockZone)
    let (model, _, _) = makeClock(store: store, defaultZone: zone("Europe/Paris"))
    #expect(model.zone == zone("Europe/Paris"))
}

// A city picked inside a zone (M9): "San Francisco" stays San Francisco, not Los Angeles.
@Test @MainActor func pickedCityIsShownAndSaved() {
    let store = InMemorySettingsStore()
    let (first, _, _) = makeClock(store: store)
    first.select(Place(zone("America/Los_Angeles"), city: "San Francisco"))
    #expect(first.cityText == "San Francisco")
    #expect(first.spokenText.hasPrefix("San Francisco, "))
    let (second, _, _) = makeClock(store: store)
    #expect(second.cityText == "San Francisco")
    #expect(second.zone == zone("America/Los_Angeles"))
}
