import Foundation

/// A validated IANA time zone, such as `America/New_York`, with display names derived from it.
/// Encodes as its bare identifier string; decoding an unknown identifier throws.
public struct Zone: Hashable, Sendable, Codable {
    /// Identifiers `Zone` accepts: the system's known zones plus `UTC`, which the system
    /// resolves (to `GMT`) but doesn't list. Plain `TimeZone(identifier:)` isn't used to
    /// validate because it also accepts abbreviations like `PST`.
    static let validIdentifiers: Set<String> = Set(TimeZone.knownTimeZoneIdentifiers).union(["UTC"])

    public let identifier: String

    /// Coordinated Universal Time: the fallback when the Mac's zone isn't in the known list.
    public static let utc = Zone(identifier: "UTC")!

    public init?(identifier: String) {
        guard Self.validIdentifiers.contains(identifier) else { return nil }
        self.identifier = identifier
    }

    /// The last component, with underscores as spaces: `America/Argentina/Buenos_Aires` → "Buenos Aires".
    public var city: String {
        let last = identifier.split(separator: "/").last.map(String.init) ?? identifier
        return last.replacingOccurrences(of: "_", with: " ")
    }

    /// The first component when there is more than one (`America`), otherwise "".
    public var region: String {
        let parts = identifier.split(separator: "/")
        return parts.count > 1 ? String(parts[0]) : ""
    }

    /// Always succeeds: the identifier was validated on creation.
    public var timeZone: TimeZone {
        TimeZone(identifier: identifier)!
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identifier = try container.decode(String.self)
        guard let zone = Zone(identifier: identifier) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown time zone identifier \(identifier)")
        }
        self = zone
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(identifier)
    }
}
