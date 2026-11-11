import Foundation

extension Zone {
    /// The zone for a system-reported time zone (usually `TimeZone.current`), or UTC when the
    /// system reports one missing from its own list (e.g. `Asia/Kolkata` on a system that
    /// lists `Asia/Calcutta`, or a fixed offset like `GMT+0100`).
    public init(systemZone: TimeZone) {
        self = Zone(identifier: systemZone.identifier) ?? .utc
    }
}

/// The lookups behind the widget's zone parameter: resolving saved identifiers, search,
/// the suggestion list, and the default. The widget's App Intents entity query wraps this.
public struct ZoneQuery: Sendable {
    public let catalog: ZoneCatalog
    /// The zone a new widget shows: the Mac's zone, or UTC.
    public let defaultZone: Zone

    public init(catalog: ZoneCatalog = .system, systemZone: TimeZone) {
        self.catalog = catalog
        self.defaultZone = Zone(systemZone: systemZone)
    }

    /// Places for saved IDs (`Place.id`; widgets saved before M9 hold bare identifiers),
    /// skipping any whose zone the system no longer knows.
    public func places(withIDs ids: [String]) -> [Place] {
        ids.compactMap(Place.init(id:))
    }

    /// Same matching, ranking and names as the windows' zone picker, favorites first.
    public func search(_ query: String, at now: Date, favorites: [Place] = []) -> [Place] {
        catalog.matches(query, at: now, favorites: favorites)
    }

    /// The favorites, then every zone in city order.
    public func suggestedPlaces(favorites: [Place] = []) -> [Place] {
        catalog.matches("", at: Date(timeIntervalSince1970: 0), favorites: favorites)
    }
}
