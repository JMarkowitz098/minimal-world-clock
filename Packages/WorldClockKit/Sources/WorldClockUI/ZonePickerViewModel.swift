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
        /// What VoiceOver reads: "Tokyo, Asia, UTC+9" (no "·"); just "UTC" when the city is the offset.
        public var spokenLabel: String {
            city == detail ? city : "\(city), \(detail)".replacingOccurrences(of: " · ", with: ", ")
        }
    }

    public var query = "" {
        didSet {
            rows = search()
            highlighted = nil
        }
    }
    public private(set) var rows: [Row] = []
    /// The row the arrow keys moved to (shown like a hovered row); nil until they're used and
    /// again after typing.
    public private(set) var highlighted: Zone?

    /// What Return picks: the highlighted row, else the first.
    public var choice: Zone? { highlighted ?? rows.first?.zone }

    /// Moves the highlight `steps` rows down (negative: up), stopping at the ends. With no
    /// highlight yet it starts just above the first row, so ↓ lands on the first.
    public func moveHighlight(by steps: Int) {
        guard !rows.isEmpty else { return }
        let current = rows.firstIndex { $0.zone == highlighted } ?? -1
        highlighted = rows[min(max(current + steps, 0), rows.count - 1)].zone
    }

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
