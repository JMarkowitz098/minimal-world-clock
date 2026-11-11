import Foundation

/// A zone as the user picked it: the zone, and the city in it they chose when that isn't the
/// zone's own ("San Francisco" in America/Los_Angeles, found through `CityTable`). The windows,
/// favorites and widget show `name`; all time math uses `zone`.
///
/// Saved as its `id` string: the bare identifier for the zone's own city (so zones saved before
/// M9 read as places), or `identifier#city`.
public struct Place: Hashable, Sendable, Codable {
    public let zone: Zone
    /// Another city in the zone, or nil for the zone's own city.
    public let city: String?

    /// - Parameter city: a city in `zone`; the zone's own city (or nil) means none.
    public init(_ zone: Zone, city: String? = nil) {
        self.zone = zone
        self.city = city == zone.city ? nil : city
    }

    /// What to show: "San Francisco", or the zone's city ("Los Angeles").
    public var name: String { city ?? zone.city }

    /// "America/Los_Angeles#San Francisco", or "Asia/Tokyo".
    public var id: String {
        city.map { "\(zone.identifier)#\($0)" } ?? zone.identifier
    }

    /// Reads an `id`; nil when its zone is unknown.
    public init?(id: String) {
        let parts = id.split(separator: "#", maxSplits: 1).map(String.init)
        guard let first = parts.first, let zone = Zone(identifier: first) else { return nil }
        self.init(zone, city: parts.count > 1 ? parts[1] : nil)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let id = try container.decode(String.self)
        guard let place = Place(id: id) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown place \(id)")
        }
        self = place
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}
