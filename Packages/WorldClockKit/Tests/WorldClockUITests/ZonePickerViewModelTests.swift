import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

@MainActor private func makePicker() -> ZonePickerViewModel {
    let catalog = ZoneCatalog(zones: ["America/New_York", "Asia/Tokyo", "Asia/Calcutta", "UTC"].map(zone))
    return ZonePickerViewModel(catalog: catalog, now: jan15Noon)
}

@Test @MainActor func emptyQueryListsEveryZoneByCity() {
    #expect(makePicker().rows.map(\.city) == ["Calcutta", "New York", "Tokyo", "UTC"])
}

@Test @MainActor func rowsShowRegionAndOffset() {
    let rows = makePicker().rows
    #expect(rows[0].detail == "Asia · UTC+5:30")
    #expect(rows[1].detail == "America · UTC\u{2212}5")
    #expect(rows[3].detail == "UTC")
}

@Test @MainActor func queryFiltersRows() {
    let picker = makePicker()
    picker.query = "asia"
    #expect(picker.rows.map(\.zone) == [zone("Asia/Calcutta"), zone("Asia/Tokyo")])
    picker.query = "zzz"
    #expect(picker.rows.isEmpty)
}

// Keyboard (M8): ↓/↑ in the search field move a highlight; Return picks it.

@Test @MainActor func arrowKeysMoveTheHighlight() {
    let picker = makePicker()
    #expect(picker.highlighted == nil)
    picker.moveHighlight(by: 1)
    #expect(picker.highlighted == zone("Asia/Calcutta"))
    picker.moveHighlight(by: 1)
    #expect(picker.highlighted == zone("America/New_York"))
    picker.moveHighlight(by: -1)
    #expect(picker.highlighted == zone("Asia/Calcutta"))
}

@Test @MainActor func highlightStopsAtTheEnds() {
    let picker = makePicker()
    picker.moveHighlight(by: -1)
    #expect(picker.highlighted == zone("Asia/Calcutta"))
    for _ in 0..<10 { picker.moveHighlight(by: 1) }
    #expect(picker.highlighted == zone("UTC"))
}

@Test @MainActor func typingClearsTheHighlight() {
    let picker = makePicker()
    picker.moveHighlight(by: 1)
    picker.query = "new"
    #expect(picker.highlighted == nil)
    picker.query = "zzz"
    picker.moveHighlight(by: 1)
    #expect(picker.highlighted == nil)
}

@Test @MainActor func returnPicksTheHighlightedRowElseTheFirst() {
    let picker = makePicker()
    #expect(picker.choice == zone("Asia/Calcutta"))
    picker.moveHighlight(by: 2)
    #expect(picker.choice == zone("America/New_York"))
    picker.query = "zzz"
    #expect(picker.choice == nil)
}
