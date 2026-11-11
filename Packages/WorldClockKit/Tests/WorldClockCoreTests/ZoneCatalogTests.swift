import Foundation
import Testing
@testable import WorldClockCore

@Test func catalogListsEveryKnownZone() {
    let catalog = ZoneCatalog.system
    #expect(catalog.zones.count == TimeZone.knownTimeZoneIdentifiers.count)
    #expect(catalog.zones.contains(zone("Europe/London")))
}

@Test func emptyQueryReturnsAllZonesSortedByCity() {
    let results = ZoneCatalog.system.search("", at: jan15Noon)
    #expect(results.count == ZoneCatalog.system.zones.count)
    let cities = results.map(\.city)
    #expect(cities == cities.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
}

@Test func searchMatchesCityIgnoringCase() {
    let results = ZoneCatalog.system.search("tokyo", at: jan15Noon)
    #expect(results.first == zone("Asia/Tokyo"))
}

@Test func searchIgnoresDiacritics() {
    let results = ZoneCatalog.system.search("sao paulo", at: jan15Noon)
    #expect(results.contains(zone("America/Sao_Paulo")))
}

@Test func searchTreatsUnderscoreAndSpaceAlike() {
    #expect(ZoneCatalog.system.search("new york", at: jan15Noon).first == zone("America/New_York"))
    #expect(ZoneCatalog.system.search("New_York", at: jan15Noon).first == zone("America/New_York"))
}

@Test func searchMatchesRegion() {
    let results = ZoneCatalog.system.search("australia", at: jan15Noon)
    #expect(results.contains(zone("Australia/Sydney")))
    // Plus two Antarctic zones on Australian time (country and zone-name search, M9).
    let antarctic = [zone("Antarctica/Macquarie"), zone("Antarctica/Casey")]
    #expect(results.allSatisfy { $0.region == "Australia" || antarctic.contains($0) })
}

@Test func searchMatchesFullIdentifier() {
    #expect(ZoneCatalog.system.search("Europe/Paris", at: jan15Noon) == [zone("Europe/Paris")])
}

@Test func cityPrefixMatchesRankBeforeOtherMatches() {
    // "lo" starts London, Los Angeles, Lome… and appears inside Colombo. Since M9 a result's
    // name may be another city in the zone ("Long Beach" for Los Angeles), so check names.
    let results = ZoneCatalog.system.matches("lo", at: jan15Noon)
    let startsWith = results.map { $0.name.lowercased().hasPrefix("lo") }
    let firstOther = startsWith.firstIndex(of: false) ?? startsWith.count
    #expect(startsWith[..<firstOther].allSatisfy { $0 })
    #expect(startsWith[firstOther...].allSatisfy { !$0 })
    #expect(results.map(\.zone).contains(zone("Asia/Colombo")))
}

@Test func searchMatchesAbbreviationForThatDate() {
    let catalog = ZoneCatalog(zones: [zone("America/Los_Angeles"), zone("Asia/Tokyo")])
    #expect(catalog.search("PST", at: jan15Noon) == [zone("America/Los_Angeles")])
    #expect(catalog.search("PDT", at: jul15Noon) == [zone("America/Los_Angeles")])
}

@Test func searchWithNoMatchIsEmpty() {
    #expect(ZoneCatalog.system.search("zzzz", at: jan15Noon).isEmpty)
}

@Test func abbreviationMustMatchExactly() {
    // Many abbreviations are "GMT+9"-style text; substring matches would flood results.
    let catalog = ZoneCatalog(zones: [zone("America/Los_Angeles")])
    #expect(catalog.search("PS", at: jan15Noon).isEmpty)
}
