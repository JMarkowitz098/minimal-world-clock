import Foundation
import Observation
import WorldClockCore

/// Search results for the zone picker: one row per matching zone (named for the city that
/// matched, see `ZoneCatalog.matches`), favorites first. Identifiable
/// (by object identity) so a view can present it with `popover(item:)`.
@MainActor @Observable public final class ZonePickerViewModel: Identifiable {
    public struct Row: Identifiable, Hashable {
        public var id: String { place.id }
        /// What picking the row chooses: the zone, named for the row's city.
        public let place: Place
        public var zone: Zone { place.zone }
        /// "Tokyo", or the city the search matched in the zone ("San Francisco").
        public let city: String
        /// "Asia · UTC+9"; just the offset for zones with no region; for a matched city, the
        /// zone's own city instead of the region ("Los Angeles · UTC−8").
        public let detail: String
        /// Starred: listed first, with a filled star.
        public var isFavorite: Bool
        /// What VoiceOver reads: "Tokyo, Asia, UTC+9" (no "·"); just "UTC" when the city is the
        /// offset; ", favorite" at the end for a starred zone (the star is only drawn).
        public var spokenLabel: String {
            let label = city == detail ? city : "\(city), \(detail)".replacingOccurrences(of: " · ", with: ", ")
            return isFavorite ? "\(label), favorite" : label
        }
    }

    public var query = "" {
        didSet {
            search()
            highlighted = nil
        }
    }
    public private(set) var rows: [Row] = []
    /// How many rows at the top were favorites when the search ran (the picker's first section).
    /// Starring doesn't change it, so a row stays in its section until the next search.
    public private(set) var favoriteCount = 0
    /// The row the arrow keys moved to (shown like a hovered row); nil until they're used and
    /// again after typing.
    public private(set) var highlighted: Place?

    /// What Return picks: the highlighted row, else the first.
    public var choice: Place? { highlighted ?? rows.first?.place }

    /// Whether rows can be starred (the picker was given the favorites).
    public var canFavorite: Bool { favorites != nil }

    /// Moves the highlight `steps` rows down (negative: up), stopping at the ends. With no
    /// highlight yet it starts just above the first row, so ↓ lands on the first.
    public func moveHighlight(by steps: Int) {
        guard !rows.isEmpty else { return }
        let current = rows.firstIndex { $0.place == highlighted } ?? -1
        highlighted = rows[min(max(current + steps, 0), rows.count - 1)].place
    }

    /// Stars or unstars `place` (zone and city) and saves. The row stays where it is (a row jumping away from
    /// under the pointer is disorienting); the next search or opening lists it with the favorites.
    public func toggleFavorite(_ place: Place) {
        guard let favorites else { return }
        favorites.toggle(place)
        let isFavorite = favorites.favorites.contains(place)
        if let index = rows.firstIndex(where: { $0.place == place }) {
            rows[index].isFavorite = isFavorite
        }
    }

    @ObservationIgnored private let catalog: ZoneCatalog
    @ObservationIgnored private let now: Date
    @ObservationIgnored private let favorites: FavoritesModel?

    /// - Parameters:
    ///   - now: the instant offsets and abbreviations are shown for.
    ///   - favorites: listed first and changed by starring; nil hides the stars.
    public init(catalog: ZoneCatalog = .system, now: Date, favorites: FavoritesModel? = nil) {
        self.catalog = catalog
        self.now = now
        self.favorites = favorites
        search()
    }

    private func search() {
        let favoriteZones = favorites?.favorites ?? Favorites()
        rows = catalog.matches(query, at: now, favorites: favoriteZones.places).map { place in
            let zone = place.zone
            let offset = zone.utcOffsetText(at: now)
            let area = place.city != nil ? zone.city : zone.region
            return Row(place: place, city: place.name, detail: area.isEmpty ? offset : "\(area) · \(offset)",
                       isFavorite: favoriteZones.contains(place))
        }
        favoriteCount = rows.prefix { $0.isFavorite }.count
    }
}
