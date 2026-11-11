import Foundation
import Testing
@testable import WorldClockCore

// Favorite zones (M9): listed first in the zone picker and the widget's edit screen.

private let tokyo = place("Asia/Tokyo")
private let paris = place("Europe/Paris")
private let adelaide = place("Australia/Adelaide")

@Test func favoritesListFirst() {
    let all = ZoneCatalog.system.matches("", at: jan15Noon, favorites: [tokyo, paris])
    #expect(Array(all.prefix(2)) == [tokyo, paris])
    #expect(all.count == ZoneCatalog.system.zones.count)
    // Searching keeps the favorites that match on top and leaves the others out.
    let par = ZoneCatalog.system.matches("par", at: jan15Noon, favorites: [tokyo, paris])
    #expect(par.first == paris)
    #expect(!par.contains(tokyo))
}

@Test func favoritesKeepTheirOrder() {
    let results = ZoneCatalog.system.matches("", at: jan15Noon, favorites: [paris, tokyo, adelaide])
    #expect(Array(results.prefix(3)) == [paris, tokyo, adelaide])
    // Not listed a second time below.
    #expect(results.count == Set(results).count)
}

@Test func togglingFavoriteAddsAndRemoves() {
    var favorites = Favorites()
    favorites.toggle(paris)
    favorites.toggle(tokyo)
    #expect(favorites.places == [paris, tokyo])
    #expect(favorites.contains(paris))
    favorites.toggle(paris)
    #expect(favorites.places == [tokyo])
    #expect(!favorites.contains(paris))
}

@Test func favoritesRoundTripThroughStore() {
    let store = InMemorySettingsStore()
    #expect(store.favorites == Favorites())
    store.favorites = Favorites([adelaide, tokyo])
    #expect(store.favorites.places == [adelaide, tokyo])
}

@Test func unknownFavoriteIsDroppedOnDecode() {
    let store = ReportingStore()
    store.setData(Data(#"["Asia/Tokyo","Nowhere/Zone","Europe/Paris"]"#.utf8), forKey: SettingsKey.favoriteZones)
    #expect(store.favorites.places == [tokyo, paris])
    #expect(store.reported == [SettingsKey.favoriteZones])
}

@Test func corruptFavoritesReadAsNone() {
    let store = ReportingStore()
    store.setData(Data("not json".utf8), forKey: SettingsKey.favoriteZones)
    #expect(store.favorites == Favorites())
    #expect(store.reported == [SettingsKey.favoriteZones])
}

@Test func zoneQuerySuggestsFavoritesFirst() {
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    let suggested = query.suggestedPlaces(favorites: [tokyo, adelaide])
    #expect(Array(suggested.prefix(2)) == [tokyo, adelaide])
    #expect(suggested.count == ZoneCatalog.system.zones.count)
    #expect(query.search("tok", at: jan15Noon, favorites: [paris, tokyo]).first == tokyo)
}

/// Records which keys it was told it couldn't read.
private final class ReportingStore: SettingsStore {
    private var storage: [String: Data] = [:]
    private(set) var reported: [String] = []
    func data(forKey key: String) -> Data? { storage[key] }
    func setData(_ data: Data?, forKey key: String) { storage[key] = data }
    func reportUnreadable(key: String, error: any Error) { reported.append(key) }
}

@Test func favoriteKeepsTheCityItWasStarredAs() {
    let sanFrancisco = Place(zone("America/Los_Angeles"), city: "San Francisco")
    let all = ZoneCatalog.system.matches("", at: jan15Noon, favorites: [sanFrancisco])
    #expect(all.first == sanFrancisco)
    // Los Angeles itself is still listed, below.
    #expect(all.contains(place("America/Los_Angeles")))
    // Searching for it doesn't list it twice.
    let san = ZoneCatalog.system.matches("San Francisco", at: jan15Noon, favorites: [sanFrancisco])
    #expect(san.filter { $0 == sanFrancisco }.count == 1)
    #expect(san.first == sanFrancisco)
}
