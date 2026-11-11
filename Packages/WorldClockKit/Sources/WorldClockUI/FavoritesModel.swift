import Foundation
import Observation
import WorldClockCore

/// The favorite places both windows' zone pickers share, saved as the user stars them. The app
/// passes one through the environment (`.environment(favorites)`); `ZoneButton` hands it to
/// each picker it opens. Saved in the App Group (`live()`), so the widget's edit screen lists
/// them first too.
@MainActor @Observable public final class FavoritesModel {
    public private(set) var favorites: Favorites
    @ObservationIgnored private let store: SettingsStore

    public init(store: SettingsStore) {
        self.store = store
        favorites = store.favorites
    }

    /// Stars `place`, or unstars it if it's already a favorite, and saves.
    public func toggle(_ place: Place) {
        favorites.toggle(place)
        store.favorites = favorites
    }

    public static func live() -> FavoritesModel {
        FavoritesModel(store: AppGroup.settingsStore())
    }
}
