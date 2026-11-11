import Foundation
import Testing
@testable import WorldClockCore

// A place (M9): a zone with the city the user picked in it ("San Francisco" in Los Angeles's
// zone), so the windows and favorites show that city.

@Test func placeNamesItsCityOrTheZones() {
    #expect(Place(zone("America/Los_Angeles"), city: "San Francisco").name == "San Francisco")
    #expect(Place(zone("America/Los_Angeles")).name == "Los Angeles")
    // The zone's own city is no extra city.
    #expect(Place(zone("America/Los_Angeles"), city: "Los Angeles") == Place(zone("America/Los_Angeles")))
}

@Test func placeIDRoundTrips() {
    let sf = Place(zone("America/Los_Angeles"), city: "San Francisco")
    #expect(sf.id == "America/Los_Angeles#San Francisco")
    #expect(Place(id: sf.id) == sf)
    #expect(Place(id: "Asia/Tokyo") == Place(zone("Asia/Tokyo")))
    #expect(Place(id: "Nowhere/Zone#City") == nil)
}

@Test func placeDecodesASavedZone() throws {
    // Saved before M9: a bare identifier.
    let old = try JSONDecoder().decode(Place.self, from: Data(#""Asia/Tokyo""#.utf8))
    #expect(old == Place(zone("Asia/Tokyo")))
    let sf = Place(zone("America/Los_Angeles"), city: "San Francisco")
    #expect(try JSONDecoder().decode(Place.self, from: JSONEncoder().encode(sf)) == sf)
    #expect(try JSONEncoder().encode(Place(zone("Asia/Tokyo"))) == Data(#""Asia\/Tokyo""#.utf8))
}
