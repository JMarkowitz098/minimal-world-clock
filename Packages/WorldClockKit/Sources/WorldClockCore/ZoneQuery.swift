import Foundation

extension Zone {
    /// The zone for a system-reported time zone (usually `TimeZone.current`), or UTC when the
    /// system reports one missing from its own list (e.g. `Asia/Kolkata` on a system that
    /// lists `Asia/Calcutta`, or a fixed offset like `GMT+0100`).
    public init(systemZone: TimeZone) {
        self = Zone(identifier: systemZone.identifier) ?? Zone(identifier: "UTC")!
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

    /// Zones for saved identifiers, skipping any the system no longer knows.
    public func zones(withIdentifiers identifiers: [String]) -> [Zone] {
        identifiers.compactMap(Zone.init(identifier:))
    }

    /// Same matching and ranking as the windows' zone picker.
    public func search(_ query: String, at now: Date) -> [Zone] {
        catalog.search(query, at: now)
    }

    /// Every zone, in city order.
    public var suggestedZones: [Zone] {
        catalog.search("", at: Date(timeIntervalSince1970: 0))
    }
}
