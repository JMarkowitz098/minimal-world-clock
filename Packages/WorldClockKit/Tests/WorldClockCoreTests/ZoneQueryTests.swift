import Foundation
import Testing
@testable import WorldClockCore

// The lookups behind the widget's zone parameter (its App Intents entity query).

@Test func systemZoneUsesItsIdentifier() {
    #expect(Zone(systemZone: TimeZone(identifier: "Europe/Paris")!) == zone("Europe/Paris"))
}

@Test func unlistedSystemZoneFallsBackToUTC() {
    // A fixed-offset zone ("GMT+0100") isn't in the known list.
    #expect(Zone(systemZone: TimeZone(secondsFromGMT: 3600)!) == zone("UTC"))
}

@Test func zoneQueryResolvesIdentifiers() {
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    #expect(query.places(withIDs: ["Asia/Tokyo", "Nowhere/Zone", "UTC", "America/Los_Angeles#San Francisco"])
            == [place("Asia/Tokyo"), place("UTC"), Place(zone("America/Los_Angeles"), city: "San Francisco")])
}

@Test func zoneQuerySearchMatchesCatalogSearch() {
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    #expect(query.search("new", at: jan15Noon) == ZoneCatalog.system.matches("new", at: jan15Noon))
    #expect(query.search("PST", at: jan15Noon).contains(place("America/Los_Angeles")))
}

@Test func zoneQuerySuggestsEveryZoneByCity() {
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    #expect(query.suggestedPlaces().map(\.zone) == ZoneCatalog.system.search("", at: jan15Noon))
}

@Test func zoneQuerySearchUsesAliases() {
    // The widget's edit screen finds what the windows' picker finds (M9).
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    #expect(query.search("San Francisco", at: jan15Noon).first == Place(zone("America/Los_Angeles"), city: "San Francisco"))
    #expect(query.search("Japan", at: jan15Noon).first == place("Asia/Tokyo"))
    #expect(query.search("Pacific Time", at: jan15Noon).first == place("America/Los_Angeles"))
}

@Test func zoneQueryDefaultIsTheMacZone() {
    #expect(ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!).defaultZone == zone("Europe/Paris"))
    #expect(ZoneQuery(systemZone: TimeZone(secondsFromGMT: 3600)!).defaultZone == zone("UTC"))
}
