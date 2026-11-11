import AppIntents
import SwiftUI
import WidgetKit
import WorldClockCore
import WorldClockUI

/// The desktop widget: one zone's live time, chosen in the widget's edit screen. Logic lives
/// in WorldClockKit (`ZoneQuery`, `Zone.displayChanges`, `WidgetDisplay`, `ZoneWidgetView`);
/// this file only adapts it to WidgetKit and App Intents.
@main
struct MinimalWorldClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "MinimalWorldClockWidget", intent: SelectZoneIntent.self, provider: Provider()) { entry in
            EntryView(entry: entry)
        }
        .configurationDisplayName("Minimal World Clock")
        .description("The time in one time zone.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Configuration

struct SelectZoneIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Time Zone"
    static let description = IntentDescription("Choose the time zone to show.")

    /// Optional: Xcode requires widget configuration parameters to be. Empty until the user
    /// picks a zone; the provider then shows the Mac's zone.
    @Parameter(title: "Time Zone")
    var zone: ZoneEntity?
}

/// Stores only the place's `id`, as in Apple's sample; everything else derives from it. Widgets
/// configured before M9 saved a bare zone identifier, which reads as the zone's own city.
struct ZoneEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Time Zone"
    static let defaultQuery = ZoneEntityQuery()

    let id: String

    init(place: Place) {
        id = place.id
    }

    /// Nil if the system no longer knows the saved zone.
    var place: Place? { Place(id: id) }

    /// "Tokyo" over "Asia"; a city picked in a zone over the zone's city ("San Francisco" over
    /// "Los Angeles"), as in the app's picker.
    var displayRepresentation: DisplayRepresentation {
        guard let place else { return DisplayRepresentation(title: "\(id)") }
        let detail = place.city != nil ? place.zone.city : place.zone.region
        guard !detail.isEmpty else { return DisplayRepresentation(title: "\(place.name)") }
        return DisplayRepresentation(title: "\(place.name)", subtitle: "\(detail)")
    }
}

/// Lists the favorites starred in the app's zone picker first (read from the App Group).
struct ZoneEntityQuery: EntityStringQuery {
    private var query: ZoneQuery { ZoneQuery(systemZone: .current) }
    private var favorites: [Place] { AppGroup.settingsStore().favorites.places }

    func entities(for identifiers: [String]) async throws -> [ZoneEntity] {
        query.places(withIDs: identifiers).map(ZoneEntity.init)
    }

    func entities(matching string: String) async throws -> [ZoneEntity] {
        query.search(string, at: Date(), favorites: favorites).map(ZoneEntity.init)
    }

    func suggestedEntities() async throws -> [ZoneEntity] {
        query.suggestedPlaces(favorites: favorites).map(ZoneEntity.init)
    }
}

// MARK: - Timeline

struct Entry: TimelineEntry {
    let date: Date
    let place: Place
    /// The Settings window's choices, read from the App Group (the app reloads the widget's
    /// timelines when they change).
    let theme: Theme
    let locale: Locale
}

/// The theme and locale (12/24-hour applied) the app's Settings chose.
private func sharedSettings() -> (theme: Theme, locale: Locale) {
    let settings = AppGroup.settingsStore().appSettings
    return (Theme.named(settings.theme) ?? .default, Locale.current.applying(settings.timeFormat))
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        let (theme, locale) = sharedSettings()
        return Entry(date: Date(), place: Place(ZoneQuery(systemZone: .current).defaultZone), theme: theme, locale: locale)
    }

    func snapshot(for configuration: SelectZoneIntent, in context: Context) async -> Entry {
        let (theme, locale) = sharedSettings()
        return Entry(date: Date(), place: place(for: configuration), theme: theme, locale: locale)
    }

    /// Hours and minutes update on their own, so entries are only needed when the date, AM/PM,
    /// offset or the time's width changes (`WidgetDisplay.entryDates`): now, then the next
    /// three; WidgetKit asks again after the last.
    func timeline(for configuration: SelectZoneIntent, in context: Context) async -> Timeline<Entry> {
        let place = place(for: configuration)
        let zone = place.zone
        let (theme, locale) = sharedSettings()
        let now = Date()
        let dates = [now] + WidgetDisplay.entryDates(zone: zone, after: now, locale: locale, count: 3)
        Log.widget.info("Timeline for \(place.id, privacy: .public) in \(theme.id, privacy: .public), \(locale.identifier, privacy: .public): \(dates.map { $0.formatted(.iso8601) }.joined(separator: ", "), privacy: .public)")
        return Timeline(entries: dates.map { Entry(date: $0, place: place, theme: theme, locale: locale) }, policy: .atEnd)
    }

    /// The configured place, or the Mac's zone when none is set yet or the saved one is no
    /// longer known.
    private func place(for configuration: SelectZoneIntent) -> Place {
        let macZone = Place(ZoneQuery(systemZone: .current).defaultZone)
        guard let entity = configuration.zone else { return macZone }
        guard let place = entity.place else {
            Log.widget.error("Configured zone \(entity.id, privacy: .public) is unknown; showing the Mac's zone.")
            return macZone
        }
        return place
    }
}

struct EntryView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZoneWidgetView(
            display: WidgetDisplay(zone: entry.place.zone, city: entry.place.city, at: entry.date, locale: entry.locale),
            size: family == .systemSmall ? .small : .medium
        )
        .themed(entry.theme)
        // Themed on its own: WidgetKit draws the container background apart from the content.
        .containerBackground(for: .widget) { WidgetBackground().themed(entry.theme) }
    }
}
