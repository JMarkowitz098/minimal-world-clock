import Foundation

/// A searchable list of zones. `ZoneCatalog.system` holds every zone the system knows.
public struct ZoneCatalog: Sendable {
    public let zones: [Zone]
    /// Search keys for each zone, computed once, in the same order as `zones`.
    private let keys: [Keys]

    private struct Keys: Sendable {
        let city: String
        let cityIsMajor: Bool
        let region: String
        let identifier: String
        /// Country names and zone names ("japan", "pacific time"): exact or substring matches.
        let names: [String]
        let aliases: [(name: String, key: String, isMajor: Bool)]
    }

    /// - Parameter cities: other cities in each zone, and which cities are major. Country and
    ///   zone names come from `ZoneNames` (English, like the rest of the app for now).
    public init(zones: [Zone], cities: CityTable = .standard) {
        self.zones = zones
        self.keys = zones.map { zone in
            let countryNames = ZoneNames.countryCode(for: zone.identifier).flatMap { cities.countryNames[$0] } ?? []
            return Keys(
                city: Self.normalize(zone.city),
                cityIsMajor: cities.majorZones.contains(zone.identifier),
                region: Self.normalize(zone.region),
                identifier: Self.normalize(zone.identifier),
                names: Array(Set((ZoneNames.names(for: zone.identifier) + countryNames).map(Self.normalize))),
                aliases: (cities.aliases[zone.identifier] ?? []).map { ($0.name, Self.normalize($0.name), $0.isMajor) }
            )
        }
    }

    public static let system = ZoneCatalog(zones: TimeZone.knownTimeZoneIdentifiers.compactMap(Zone.init(identifier:)))

    /// Zones matching `query` (see `matches`).
    public func search(_ query: String, at now: Date, favorites: [Place] = []) -> [Zone] {
        matches(query, at: now, favorites: favorites).map(\.zone)
    }

    /// Zones matching `query`, once each, as places: a zone found through another city in it
    /// (`CityTable`) is named for that city ("San Francisco" for America/Los_Angeles). Ignoring case and diacritics and treating `_` and space
    /// alike. A zone matches when the query appears in its city, another city in it
    /// (`CityTable`), its region, identifier, country name or zone name ("Pacific Time"), or
    /// equals the abbreviation in effect at `now` (`PST` in January, `PDT` in July).
    ///
    /// Order: `favorites` whose zone matches, in their own order (a favorite keeps its city);
    /// then zones whose own city is the query;
    /// then other exact names (a city in the zone, the country, the zone name); then major cities
    /// starting with the query; then other cities starting with it; then everything else. Each
    /// group is in order of the shown name. An empty query returns favorites, then every zone in
    /// city order. A result equal to a favorite (same zone and city) is listed only once.
    public func matches(_ query: String, at now: Date, favorites: [Place] = []) -> [Place] {
        let q = Self.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        var ranked: [(rank: Int, match: Place)] = []
        for (zone, key) in zip(zones, keys) {
            if let found = Self.rank(key, for: q, abbreviation: { zone.timeZone.abbreviation(for: now) }) {
                ranked.append((found.rank, Place(zone, city: found.city)))
            }
        }
        ranked.sort { a, b in
            if a.rank != b.rank { return a.rank < b.rank }
            switch a.match.name.localizedStandardCompare(b.match.name) {
            case .orderedAscending: return true
            case .orderedDescending: return false
            case .orderedSame: return a.match.zone.identifier < b.match.zone.identifier
            }
        }
        let results = ranked.map(\.match)
        let matchedZones = Set(results.map(\.zone))
        let favoriteMatches = favorites.filter { matchedZones.contains($0.zone) }
        let favoriteSet = Set(favorites)
        return favoriteMatches + results.filter { !favoriteSet.contains($0) }
    }

    /// How well `key` matches `q` (lower is better) and the city in the zone that matched, if
    /// the best match was one; nil if it doesn't match. An empty query matches everything alike.
    private static func rank(_ key: Keys, for q: String, abbreviation: () -> String?) -> (rank: Int, city: String?)? {
        if q.isEmpty { return (0, nil) }
        if key.city == q { return (0, nil) }
        if let alias = key.aliases.first(where: { $0.key == q }) { return (1, alias.name) }
        if key.names.contains(q) { return (1, nil) }
        if key.cityIsMajor && key.city.hasPrefix(q) { return (2, nil) }
        if let alias = key.aliases.first(where: { $0.isMajor && $0.key.hasPrefix(q) }) { return (2, alias.name) }
        if key.city.hasPrefix(q) { return (3, nil) }
        if let alias = key.aliases.first(where: { $0.key.hasPrefix(q) }) { return (3, alias.name) }
        if key.city.contains(q) || key.region.contains(q) || key.identifier.contains(q)
            || key.names.contains(where: { $0.contains(q) })
            || normalize(abbreviation() ?? "") == q {
            return (4, nil)
        }
        if let alias = key.aliases.first(where: { $0.key.contains(q) }) { return (4, alias.name) }
        return nil
    }

    /// Lowercased, diacritics removed, `_` as space: "São_Paulo" → "sao paulo".
    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "_", with: " ")
    }
}
