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
    #expect(picker.highlighted == place("Asia/Calcutta"))
    picker.moveHighlight(by: 1)
    #expect(picker.highlighted == place("America/New_York"))
    picker.moveHighlight(by: -1)
    #expect(picker.highlighted == place("Asia/Calcutta"))
}

@Test @MainActor func highlightStopsAtTheEnds() {
    let picker = makePicker()
    picker.moveHighlight(by: -1)
    #expect(picker.highlighted == place("Asia/Calcutta"))
    for _ in 0..<10 { picker.moveHighlight(by: 1) }
    #expect(picker.highlighted == place("UTC"))
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
    #expect(picker.choice == place("Asia/Calcutta"))
    picker.moveHighlight(by: 2)
    #expect(picker.choice == place("America/New_York"))
    picker.query = "zzz"
    #expect(picker.choice == nil)
}

// Favorites and wider search (M9).

@MainActor private func makePicker(favorites: [Zone], store: SettingsStore = InMemorySettingsStore()) -> ZonePickerViewModel {
    store.favorites = Favorites(favorites.map { Place($0) })
    let catalog = ZoneCatalog(zones: ["America/New_York", "Asia/Tokyo", "Asia/Calcutta", "UTC"].map(zone))
    return ZonePickerViewModel(catalog: catalog, now: jan15Noon, favorites: FavoritesModel(store: store))
}

@Test @MainActor func pickerListsFavoritesFirst() {
    let picker = makePicker(favorites: [zone("UTC"), zone("Asia/Tokyo")])
    #expect(picker.rows.map(\.city) == ["UTC", "Tokyo", "Calcutta", "New York"])
    #expect(picker.rows.map(\.isFavorite) == [true, true, false, false])
    #expect(picker.favoriteCount == 2)
    picker.query = "a"  // Calcutta, Tokyo (Asia), New York (America)
    #expect(picker.rows.first?.city == "Tokyo")
}

@Test @MainActor func starringARowSavesItAndKeepsTheRowInPlace() {
    let store = InMemorySettingsStore()
    let picker = makePicker(favorites: [], store: store)
    picker.toggleFavorite(place("UTC"))
    #expect(store.favorites.places == [place("UTC")])
    // The star fills where the row is; the list reorders on the next search (or opening).
    #expect(picker.rows.map(\.city) == ["Calcutta", "New York", "Tokyo", "UTC"])
    #expect(picker.rows.last?.isFavorite == true)
    #expect(picker.favoriteCount == 0)
    picker.query = ""
    #expect(picker.rows.first?.city == "UTC")
    #expect(picker.favoriteCount == 1)
    picker.toggleFavorite(place("UTC"))
    #expect(store.favorites.places.isEmpty)
    #expect(picker.rows.first?.isFavorite == false)
}

@Test @MainActor func arrowKeysMoveFromFavoritesIntoResults() {
    let picker = makePicker(favorites: [zone("UTC")])
    picker.moveHighlight(by: 1)
    #expect(picker.highlighted == place("UTC"))
    picker.moveHighlight(by: 1)
    #expect(picker.highlighted == place("Asia/Calcutta"))
}

@Test @MainActor func pickerWithoutFavoritesCantStar() {
    #expect(!makePicker().canFavorite)
    #expect(makePicker(favorites: []).canFavorite)
}

@Test @MainActor func aliasRowShowsTheZoneCity() {
    let cities = CityTable(parsing: "America/Los_Angeles: San Francisco")
    let catalog = ZoneCatalog(zones: [zone("America/Los_Angeles")], cities: cities)
    let picker = ZonePickerViewModel(catalog: catalog, now: jan15Noon)
    picker.query = "san fran"
    let row = picker.rows.first
    #expect(row?.city == "San Francisco")
    #expect(row?.detail == "Los Angeles · UTC\u{2212}8")
    #expect(row?.spokenLabel == "San Francisco, Los Angeles, UTC\u{2212}8")
    picker.query = ""
    #expect(picker.rows.first?.detail == "America · UTC\u{2212}8")
}

@Test @MainActor func favoriteRowSpokenLabelSaysFavorite() {
    let picker = makePicker(favorites: [zone("Asia/Tokyo")])
    #expect(picker.rows.first?.spokenLabel == "Tokyo, Asia, UTC+9, favorite")
}

@Test @MainActor func pickingAnAliasRowChoosesThatCity() {
    let cities = CityTable(parsing: "America/Los_Angeles: San Francisco")
    let store = InMemorySettingsStore()
    let picker = ZonePickerViewModel(catalog: ZoneCatalog(zones: [zone("America/Los_Angeles")], cities: cities),
                                     now: jan15Noon, favorites: FavoritesModel(store: store))
    picker.query = "san fran"
    let sanFrancisco = Place(zone("America/Los_Angeles"), city: "San Francisco")
    #expect(picker.choice == sanFrancisco)
    // Starred as San Francisco: listed (and named) so with an empty search.
    picker.toggleFavorite(sanFrancisco)
    picker.query = ""
    #expect(picker.rows.map(\.city) == ["San Francisco", "Los Angeles"])
    #expect(picker.rows.first?.detail == "Los Angeles · UTC\u{2212}8")
}
