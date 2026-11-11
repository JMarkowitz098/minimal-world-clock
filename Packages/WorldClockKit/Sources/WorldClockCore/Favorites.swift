import Foundation

/// The places the user starred in the zone picker, in the order they were added (a zone may be
/// starred under several of its cities). Listed first in the picker and the widget's edit
/// screen (`ZoneCatalog.matches(_:at:favorites:)`).
public struct Favorites: Equatable, Sendable {
    public private(set) var places: [Place]

    public init(_ places: [Place] = []) {
        self.places = places
    }

    public func contains(_ place: Place) -> Bool {
        places.contains(place)
    }

    /// Adds `place` at the end, or removes it if it's already a favorite.
    public mutating func toggle(_ place: Place) {
        if let index = places.firstIndex(of: place) {
            places.remove(at: index)
        } else {
            places.append(place)
        }
    }
}

/// Saved favorites whose zone the system no longer knows (dropped; the others are kept).
struct UnknownFavorites: Error {
    let ids: [String]
}

extension SettingsStore {
    /// Saved as a list of `Place.id`s in the App Group's store, which the widget reads too.
    /// Lenient: a place whose zone the system doesn't know is dropped (and reported) rather than
    /// losing the whole list; unreadable data reads as no favorites (also reported).
    public var favorites: Favorites {
        get {
            guard let ids = load([String].self, forKey: SettingsKey.favoriteZones) else { return Favorites() }
            let places = ids.compactMap(Place.init(id:))
            if places.count < ids.count {
                reportUnreadable(key: SettingsKey.favoriteZones, error: UnknownFavorites(ids: ids.filter { Place(id: $0) == nil }))
            }
            return Favorites(places)
        }
        set { save(newValue.places.map(\.id), forKey: SettingsKey.favoriteZones) }
    }
}
