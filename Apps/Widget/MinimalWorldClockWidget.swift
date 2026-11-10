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

/// Stores only the zone identifier, as in Apple's sample; everything else derives from `id`.
struct ZoneEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Time Zone"
    static let defaultQuery = ZoneEntityQuery()

    let id: String

    init(zone: Zone) {
        id = zone.identifier
    }

    /// Nil if the system no longer knows the saved identifier.
    var zone: Zone? { Zone(identifier: id) }

    var displayRepresentation: DisplayRepresentation {
        guard let zone, !zone.region.isEmpty else { return DisplayRepresentation(title: "\(zone?.city ?? id)") }
        return DisplayRepresentation(title: "\(zone.city)", subtitle: "\(zone.region)")
    }
}

struct ZoneEntityQuery: EntityStringQuery {
    private var query: ZoneQuery { ZoneQuery(systemZone: .current) }

    func entities(for identifiers: [String]) async throws -> [ZoneEntity] {
        query.zones(withIdentifiers: identifiers).map(ZoneEntity.init)
    }

    func entities(matching string: String) async throws -> [ZoneEntity] {
        query.search(string, at: Date()).map(ZoneEntity.init)
    }

    func suggestedEntities() async throws -> [ZoneEntity] {
        query.suggestedZones.map(ZoneEntity.init)
    }
}

// MARK: - Timeline

struct Entry: TimelineEntry {
    let date: Date
    let zone: Zone
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), zone: ZoneQuery(systemZone: .current).defaultZone)
    }

    func snapshot(for configuration: SelectZoneIntent, in context: Context) async -> Entry {
        Entry(date: Date(), zone: zone(for: configuration))
    }

    /// Hours and minutes update on their own, so entries are only needed when the date, AM/PM,
    /// offset or the time's width changes (`WidgetDisplay.entryDates`): now, then the next
    /// three; WidgetKit asks again after the last.
    func timeline(for configuration: SelectZoneIntent, in context: Context) async -> Timeline<Entry> {
        let zone = zone(for: configuration)
        let now = Date()
        let dates = [now] + WidgetDisplay.entryDates(zone: zone, after: now, locale: .current, count: 3)
        Log.widget.info("Timeline for \(zone.identifier, privacy: .public): \(dates.map { $0.formatted(.iso8601) }.joined(separator: ", "), privacy: .public)")
        return Timeline(entries: dates.map { Entry(date: $0, zone: zone) }, policy: .atEnd)
    }

    /// The configured zone, or the Mac's when none is set yet or the saved one is no longer known.
    private func zone(for configuration: SelectZoneIntent) -> Zone {
        guard let entity = configuration.zone else { return ZoneQuery(systemZone: .current).defaultZone }
        guard let zone = entity.zone else {
            Log.widget.error("Configured zone \(entity.id, privacy: .public) is unknown; showing the Mac's zone.")
            return ZoneQuery(systemZone: .current).defaultZone
        }
        return zone
    }
}

struct EntryView: View {
    let entry: Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.locale) private var locale
    /// The windows' colors (a Settings choice in M7).
    private let themes = ThemePair.solarized

    var body: some View {
        ZoneWidgetView(
            display: WidgetDisplay(zone: entry.zone, at: entry.date, locale: locale),
            size: family == .systemSmall ? .small : .medium
        )
        .themed(themes)
        // Themed on its own: WidgetKit draws the container background apart from the content.
        .containerBackground(for: .widget) { WidgetBackground().themed(themes) }
    }
}
