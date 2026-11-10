import Foundation

/// A searchable list of zones. `ZoneCatalog.system` holds every zone the system knows.
public struct ZoneCatalog: Sendable {
    public let zones: [Zone]
    /// Search keys for each zone, computed once, in the same order as `zones`.
    private let keys: [Keys]

    private struct Keys: Sendable {
        let city: String
        let region: String
        let identifier: String
    }

    public init(zones: [Zone]) {
        self.zones = zones
        self.keys = zones.map {
            Keys(city: Self.normalize($0.city), region: Self.normalize($0.region), identifier: Self.normalize($0.identifier))
        }
    }

    public static let system = ZoneCatalog(zones: TimeZone.knownTimeZoneIdentifiers.compactMap(Zone.init(identifier:)))

    /// Zones matching `query`, ignoring case and diacritics and treating `_` and space alike.
    /// A zone matches when the query appears in its city, region, or identifier, or equals the
    /// abbreviation in effect at `now` (`PST` in January, `PDT` in July). Cities that start
    /// with the query come first; within each group, zones are in city order.
    /// An empty query returns every zone in city order.
    public func search(_ query: String, at now: Date) -> [Zone] {
        let q = Self.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        var prefixMatches: [Zone] = []
        var otherMatches: [Zone] = []
        for (zone, key) in zip(zones, keys) {
            if q.isEmpty || key.city.hasPrefix(q) {
                prefixMatches.append(zone)
            } else if key.city.contains(q) || key.region.contains(q) || key.identifier.contains(q)
                        || Self.normalize(zone.timeZone.abbreviation(for: now) ?? "") == q {
                otherMatches.append(zone)
            }
        }
        return Self.sortedByCity(prefixMatches) + Self.sortedByCity(otherMatches)
    }

    private static func sortedByCity(_ zones: [Zone]) -> [Zone] {
        zones.sorted {
            switch $0.city.localizedStandardCompare($1.city) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: $0.identifier < $1.identifier
            }
        }
    }

    /// Lowercased, diacritics removed, `_` as space: "São_Paulo" → "sao paulo".
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "_", with: " ")
    }
}
