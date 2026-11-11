import Foundation

/// Cities that don't name a zone, by zone ("San Francisco" → America/Los_Angeles), and which
/// cities are major metros (they rank first in search). `CityTable.standard` is the bundled
/// table (`CityData.swift`); tests parse small ones.
///
/// Text format, one zone per line: `*Asia/Tokyo: *Osaka, Sapporo`. A `*` before the identifier
/// marks the zone's own city as major, one before a name marks that city; lines starting with
/// `//` and blank lines are skipped.
public struct CityTable: Sendable {
    public struct Alias: Hashable, Sendable {
        public let name: String
        public let isMajor: Bool
    }

    /// Cities in each zone, by zone identifier, in table order.
    public let aliases: [String: [Alias]]
    /// Zones whose own city is a major metro.
    public let majorZones: Set<String>
    /// Other names people use for countries ("UK", "Holland"), by ISO 3166 code.
    public let countryNames: [String: [String]]

    public static let standard = CityTable(parsing: CityData.table, countryNames: CityData.countryNames)

    public init(parsing text: String, countryNames: [String: [String]] = [:]) {
        var aliases: [String: [Alias]] = [:]
        var majorZones: Set<String> = []
        for line in text.split(separator: "\n") {
            let line = line.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("//"), let colon = line.firstIndex(of: ":") else { continue }
            let (identifier, zoneIsMajor) = Self.starred(line[..<colon])
            if zoneIsMajor { majorZones.insert(identifier) }
            let names = line[line.index(after: colon)...].split(separator: ",").map { Self.starred($0) }
            aliases[identifier, default: []] += names.filter { !$0.0.isEmpty }.map { Alias(name: $0.0, isMajor: $0.1) }
        }
        self.aliases = aliases
        self.majorZones = majorZones
        self.countryNames = countryNames
    }

    /// "*Osaka" → ("Osaka", true); " Sapporo" → ("Sapporo", false).
    private static func starred(_ text: Substring) -> (String, Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("*") ? (String(trimmed.dropFirst()), true) : (trimmed, false)
    }
}
