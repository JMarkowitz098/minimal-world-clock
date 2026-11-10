import Foundation
import Testing
@testable import WorldClockCore

@Test func cityAndRegionComeFromIdentifier() {
    let z = zone("America/New_York")
    #expect(z.city == "New York")
    #expect(z.region == "America")
}

@Test func nestedIdentifierUsesLastComponentAsCity() {
    let z = zone("America/Argentina/Buenos_Aires")
    #expect(z.city == "Buenos Aires")
    #expect(z.region == "America")
}

@Test func singleComponentIdentifierHasNoRegion() {
    let z = zone("UTC")
    #expect(z.city == "UTC")
    #expect(z.region == "")
}

@Test func rejectsUnknownIdentifier() {
    #expect(Zone(identifier: "Mars/Olympus_Mons") == nil)
}

@Test func zoneIsCodableRoundTrip() throws {
    let original = zone("Asia/Tokyo")
    let decoded = try JSONDecoder().decode(Zone.self, from: JSONEncoder().encode(original))
    #expect(decoded == original)
}

@Test func decodingUnknownIdentifierFails() {
    let json = Data(#""Mars/Olympus_Mons""#.utf8)
    #expect(throws: (any Error).self) { try JSONDecoder().decode(Zone.self, from: json) }
}

@Test func rejectsAbbreviationAsIdentifier() {
    // TimeZone(identifier: "PST") succeeds, but a Zone must be a real IANA name.
    #expect(Zone(identifier: "PST") == nil)
}
