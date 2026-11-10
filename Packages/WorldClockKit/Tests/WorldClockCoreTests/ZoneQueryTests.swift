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
    #expect(query.zones(withIdentifiers: ["Asia/Tokyo", "Nowhere/Zone", "UTC"]) == [zone("Asia/Tokyo"), zone("UTC")])
}

@Test func zoneQuerySearchMatchesCatalogSearch() {
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    #expect(query.search("new", at: jan15Noon) == ZoneCatalog.system.search("new", at: jan15Noon))
    #expect(query.search("PST", at: jan15Noon).contains(zone("America/Los_Angeles")))
}

@Test func zoneQuerySuggestsEveryZoneByCity() {
    let query = ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!)
    #expect(query.suggestedZones == ZoneCatalog.system.search("", at: jan15Noon))
}

@Test func zoneQueryDefaultIsTheMacZone() {
    #expect(ZoneQuery(systemZone: TimeZone(identifier: "Europe/Paris")!).defaultZone == zone("Europe/Paris"))
    #expect(ZoneQuery(systemZone: TimeZone(secondsFromGMT: 3600)!).defaultZone == zone("UTC"))
}
