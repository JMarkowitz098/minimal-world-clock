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
