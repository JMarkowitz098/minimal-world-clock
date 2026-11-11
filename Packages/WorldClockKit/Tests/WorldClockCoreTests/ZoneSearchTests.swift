import Foundation
import Testing
@testable import WorldClockCore

// Wider search (M9): countries, zone names ("Pacific Time") and cities that don't name a zone
// ("San Francisco" → Los Angeles), with major cities ranked first.

@Test func searchMatchesCountryName() {
    #expect(ZoneCatalog.system.search("Japan", at: jan15Noon).first == zone("Asia/Tokyo"))
    // India's zone is listed under its old name, Asia/Calcutta.
    #expect(ZoneCatalog.system.search("India", at: jan15Noon).first == zone("Asia/Calcutta"))
}

@Test func searchMatchesCommonCountryNames() {
    #expect(ZoneCatalog.system.search("UK", at: jan15Noon).first == zone("Europe/London"))
    #expect(ZoneCatalog.system.search("USA", at: jan15Noon).contains(zone("America/New_York")))
}

@Test func countryWithSeveralZonesListsEach() {
    let results = ZoneCatalog.system.search("United States", at: jan15Noon)
    for id in ["America/New_York", "America/Chicago", "America/Denver", "America/Phoenix",
               "America/Los_Angeles", "America/Anchorage", "Pacific/Honolulu"] {
        #expect(results.contains(zone(id)), "\(id)")
    }
}

@Test func searchMatchesGenericZoneName() {
    #expect(ZoneCatalog.system.search("Pacific Time", at: jan15Noon).first == zone("America/Los_Angeles"))
    #expect(ZoneCatalog.system.search("eastern", at: jan15Noon).contains(zone("America/New_York")))
    let centralEuropean = ZoneCatalog.system.search("Central European", at: jan15Noon)
    #expect(centralEuropean.contains(zone("Europe/Paris")))
    #expect(centralEuropean.contains(zone("Europe/Berlin")))
}

@Test func searchMatchesCityAlias() {
    #expect(ZoneCatalog.system.search("San Francisco", at: jan15Noon).first == zone("America/Los_Angeles"))
    #expect(ZoneCatalog.system.search("Boston", at: jan15Noon).first == zone("America/New_York"))
    #expect(ZoneCatalog.system.search("Osaka", at: jan15Noon).first == zone("Asia/Tokyo"))
    // Today's names for zones listed under old ones.
    #expect(ZoneCatalog.system.search("Kolkata", at: jan15Noon).first == zone("Asia/Calcutta"))
}

@Test func aliasResultNamesTheMatchedCity() {
    let match = ZoneCatalog.system.matches("San Francisco", at: jan15Noon).first
    #expect(match?.zone == zone("America/Los_Angeles"))
    #expect(match?.city == "San Francisco")
    #expect(match?.name == "San Francisco")
    // A zone found by its own city shows that city.
    let own = ZoneCatalog.system.matches("Los Angeles", at: jan15Noon).first
    #expect(own?.zone == zone("America/Los_Angeles"))
    #expect(own?.city == nil)
    #expect(own?.name == "Los Angeles")
}

@Test func eachZoneIsListedOnce() {
    // San Francisco, San Diego and San Jose all point to Los Angeles: one row, the best name.
    let zones = ZoneCatalog.system.search("san", at: jan15Noon)
    #expect(zones.count == Set(zones).count)
}

@Test func exactCityRanksBeforeAlias() {
    // London, Ontario is in Toronto's zone; the city named London ranks first.
    let cities = CityTable(parsing: "America/Toronto: London")
    let catalog = ZoneCatalog(zones: [zone("America/Toronto"), zone("Europe/London")], cities: cities)
    let matches = catalog.matches("London", at: jan15Noon)
    #expect(matches.map(\.zone) == [zone("Europe/London"), zone("America/Toronto")])
    #expect(matches.map(\.name) == ["London", "London"])
}

@Test func aliasSearchIgnoresCaseAndDiacritics() {
    #expect(ZoneCatalog.system.search("SAN FRANCISCO", at: jan15Noon).first == zone("America/Los_Angeles"))
    #expect(ZoneCatalog.system.matches("malmo", at: jan15Noon).first?.name == "Malmö")
}

@Test func majorCitiesRankBeforeOtherPrefixMatches() {
    let cities = CityTable(parsing: """
        *America/Los_Angeles: *San Francisco, Santa Barbara
        Europe/San_Marino:
        """)
    let catalog = ZoneCatalog(zones: [zone("Europe/San_Marino"), zone("America/Los_Angeles")], cities: cities)
    // San Francisco (major) before San Marino (alphabetically first, not major).
    #expect(catalog.matches("san", at: jan15Noon).map(\.name) == ["San Francisco", "San Marino"])
    // The zone's own city counts as major when its identifier is starred.
    #expect(catalog.matches("", at: jan15Noon).map(\.name) == ["Los Angeles", "San Marino"])
}

@Test func cityTableParsesMajorMarksAndNames() {
    let table = CityTable(parsing: """
        // A comment
        *Asia/Tokyo: *Osaka, Sapporo
        America/Denver: Boulder
        """)
    #expect(table.majorZones == ["Asia/Tokyo"])
    #expect(table.aliases["Asia/Tokyo"] == [.init(name: "Osaka", isMajor: true), .init(name: "Sapporo", isMajor: false)])
    #expect(table.aliases["America/Denver"] == [.init(name: "Boulder", isMajor: false)])
}

@Test func everyCityPointsToAKnownZone() {
    let table = CityTable.standard
    for identifier in Set(table.aliases.keys).union(table.majorZones) {
        #expect(Zone(identifier: identifier) != nil, "\(identifier)")
    }
    // Plenty of cities, and none repeating its own zone's city or listed twice for one zone.
    #expect(table.aliases.values.map(\.count).reduce(0, +) >= 900)
    for (identifier, aliases) in table.aliases {
        let city = ZoneCatalog.normalize(Zone(identifier: identifier)?.city ?? "")
        let names = aliases.map { ZoneCatalog.normalize($0.name) }
        #expect(!names.contains(city), "\(identifier) lists its own city")
        #expect(names.count == Set(names).count, "\(identifier) lists a city twice")
    }
}

@Test func everyListedZoneHasACountry() {
    // All but the plain UTC/GMT zones and a few Etc-style ones belong to a country.
    let missing = ZoneCatalog.system.zones.filter { ZoneNames.countryCode(for: $0.identifier) == nil }.map(\.identifier)
    #expect(missing.allSatisfy { !$0.contains("/") || $0.hasPrefix("Etc/") }, "\(missing)")
    #expect(ZoneNames.countryCode(for: "Asia/Calcutta") == "IN")
    #expect(ZoneNames.countryCode(for: "Europe/Kiev") == "UA")
}
