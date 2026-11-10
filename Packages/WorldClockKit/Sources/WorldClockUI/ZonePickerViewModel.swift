import Foundation
import Observation
import WorldClockCore

/// Search results for the zone picker: one row per matching zone. Identifiable (by object
/// identity) so a view can present it with `popover(item:)`.
@MainActor @Observable public final class ZonePickerViewModel: Identifiable {
    public struct Row: Identifiable, Hashable {
        public var id: String { zone.identifier }
        public let zone: Zone
        /// "Tokyo"
        public let city: String
        /// "Asia · UTC+9", or just the offset for zones with no region.
        public let detail: String
    }

    public var query = "" {
        didSet { rows = search() }
    }
    public private(set) var rows: [Row] = []

    @ObservationIgnored private let catalog: ZoneCatalog
    @ObservationIgnored private let now: Date

    /// - Parameter now: the instant offsets and abbreviations are shown for.
    public init(catalog: ZoneCatalog = .system, now: Date) {
        self.catalog = catalog
        self.now = now
        rows = search()
    }

    private func search() -> [Row] {
        catalog.search(query, at: now).map { zone in
            let offset = zone.utcOffsetText(at: now)
            return Row(zone: zone, city: zone.city, detail: zone.region.isEmpty ? offset : "\(zone.region) · \(offset)")
        }
    }
}
