import SwiftUI
import WorldClockCore
import WorldClockUI

/// One view to render. Add an entry whenever a milestone adds or changes a view, using
/// fixed instants and zones (never the real clock) so renders are repeatable.
struct Snapshot {
    let name: String
    let size: CGSize
    let view: @MainActor () -> AnyView
}

/// January 15, 2026, 12:00 UTC.
let jan15Noon = Date(timeIntervalSince1970: 1_768_478_400)

/// A ticker that never fires: snapshots show one fixed instant.
@MainActor final class StillTicker: Ticker {
    func schedule(at date: Date, _ action: @escaping @MainActor () -> Void) {}
    func cancel() {}
}

@MainActor func clockModel(_ identifier: String, at now: Date = jan15Noon) -> ClockViewModel {
    ClockViewModel(
        store: InMemorySettingsStore(), defaultZone: Zone(identifier: identifier)!,
        locale: Locale(identifier: "en_US"), clock: { now }, ticker: StillTicker()
    )
}

@MainActor func compareModel(_ a: String, _ b: String, at now: Date = jan15Noon, scrubTo minutes: Int? = nil) -> CompareViewModel {
    let model = CompareViewModel(
        store: InMemorySettingsStore(), defaultZones: (Zone(identifier: a)!, Zone(identifier: b)!),
        locale: Locale(identifier: "en_US"), clock: { now }, ticker: StillTicker()
    )
    if let minutes { model.scrub(toMinuteOfDay: minutes) }
    return model
}

@MainActor func pickerModel(query: String) -> ZonePickerViewModel {
    let model = ZonePickerViewModel(now: jan15Noon)
    model.query = query
    return model
}

/// The zone picker as the Clock window shows it: Solarized light or dark to match the render.
struct ThemedPicker: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZonePicker(model: ZonePickerViewModel(now: jan15Noon), selected: Zone(identifier: "Africa/Accra"),
                   theme: ThemePair.solarized.theme(for: scheme)) { _ in }
    }
}

/// The widget at a fixed instant, on its background with the widget's rounded corners (the real
/// container comes from WidgetKit). Sizes are macOS's small and medium widgets.
@MainActor func widget(_ identifier: String, _ size: ZoneWidgetView.Size, at now: Date = jan15Noon) -> AnyView {
    let display = WidgetDisplay(zone: Zone(identifier: identifier)!, at: now, locale: Locale(identifier: "en_US"))
    return AnyView(WidgetMock(display: display, size: size, now: now))
}

struct WidgetMock: View {
    let display: WidgetDisplay
    let size: ZoneWidgetView.Size
    let now: Date

    var body: some View {
        ZoneWidgetView(display: display, size: size, themes: .solarized, frozenTime: now)
            .padding(16)
            .background(WidgetBackground(themes: .solarized))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .containerShape(RoundedRectangle(cornerRadius: 20))
            .padding(12)
    }
}

@MainActor let catalog: [Snapshot] = [
    Snapshot(name: "clock", size: CGSize(width: 300, height: 162)) {
        AnyView(ClockView(model: clockModel("Asia/Tokyo"), themes: .solarized).safeAreaPadding(.top, 28))
    },
    // Longest city name in the catalog, to check it fits.
    Snapshot(name: "clock-long-name", size: CGSize(width: 300, height: 162)) {
        AnyView(ClockView(model: clockModel("America/Bahia_Banderas"), themes: .solarized).safeAreaPadding(.top, 28))
    },
    // Resized larger than natural: the time and date scale up with the window.
    Snapshot(name: "clock-resized", size: CGSize(width: 560, height: 300)) {
        AnyView(ClockView(model: clockModel("Asia/Tokyo"), themes: .solarized).safeAreaPadding(.top, 28))
    },
    Snapshot(name: "compare", size: CGSize(width: 640, height: 230)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo"), themes: .solarized).safeAreaPadding(.top, 28))
    },
    // Scrubbed to 3 PM in New York: Tokyo is on the next day, and Now is enabled.
    Snapshot(name: "compare-scrubbed", size: CGSize(width: 640, height: 230)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo", scrubTo: 15 * 60), themes: .solarized).safeAreaPadding(.top, 28))
    },
    // Resized larger than natural: everything but the title bar strip scales up.
    Snapshot(name: "compare-resized", size: CGSize(width: 960, height: 345)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo", scrubTo: 15 * 60), themes: .solarized).safeAreaPadding(.top, 28))
    },
    // Longest city name on both sides, with a half-hour difference.
    Snapshot(name: "compare-long-names", size: CGSize(width: 640, height: 230)) {
        AnyView(CompareView(model: compareModel("America/Bahia_Banderas", "America/St_Johns"), themes: .solarized).safeAreaPadding(.top, 28))
    },
    Snapshot(name: "zone-picker", size: CGSize(width: 300, height: 380)) {
        AnyView(ZonePicker(model: ZonePickerViewModel(now: jan15Noon), selected: Zone(identifier: "Africa/Accra")) { _ in })
    },
    // Themed, as the Clock window shows it (Accra selected).
    Snapshot(name: "zone-picker-themed", size: CGSize(width: 300, height: 380)) {
        AnyView(ThemedPicker())
    },
    Snapshot(name: "zone-picker-search", size: CGSize(width: 300, height: 380)) {
        AnyView(ZonePicker(model: pickerModel(query: "new"), selected: nil) { _ in })
    },
    Snapshot(name: "zone-picker-empty", size: CGSize(width: 300, height: 380)) {
        AnyView(ZonePicker(model: pickerModel(query: "zzz"), selected: nil) { _ in })
    },
    Snapshot(name: "widget-small", size: CGSize(width: 194, height: 194)) {
        widget("Asia/Tokyo", .small)
    },
    Snapshot(name: "widget-medium", size: CGSize(width: 388, height: 194)) {
        widget("Asia/Tokyo", .medium)
    },
    // Longest city name, and the longest date ("Wednesday, September 30") with a half-hour offset.
    Snapshot(name: "widget-small-long", size: CGSize(width: 194, height: 194)) {
        widget("America/Bahia_Banderas", .small)
    },
    Snapshot(name: "widget-medium-long", size: CGSize(width: 388, height: 194)) {
        widget("America/St_Johns", .medium, at: Date(timeIntervalSince1970: 1_790_784_000))
    },
]
