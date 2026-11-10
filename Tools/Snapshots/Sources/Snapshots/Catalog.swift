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

@MainActor let catalog: [Snapshot] = [
    Snapshot(name: "clock", size: CGSize(width: 320, height: 170)) {
        AnyView(ClockView(model: clockModel("Asia/Tokyo")))
    },
    // Longest city name in the catalog, to check it fits.
    Snapshot(name: "clock-long-name", size: CGSize(width: 320, height: 170)) {
        AnyView(ClockView(model: clockModel("America/Bahia_Banderas")))
    },
    Snapshot(name: "compare", size: CGSize(width: 640, height: 260)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo")))
    },
    // Scrubbed to 3 PM in New York: Tokyo is on the next day, and Now is enabled.
    Snapshot(name: "compare-scrubbed", size: CGSize(width: 640, height: 260)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo", scrubTo: 15 * 60)))
    },
    // Longest city name on both sides, with a half-hour difference.
    Snapshot(name: "compare-long-names", size: CGSize(width: 640, height: 260)) {
        AnyView(CompareView(model: compareModel("America/Bahia_Banderas", "America/St_Johns")))
    },
    Snapshot(name: "zone-picker", size: CGSize(width: 300, height: 380)) {
        AnyView(ZonePicker(model: ZonePickerViewModel(now: jan15Noon), selected: Zone(identifier: "Africa/Accra")) { _ in })
    },
    Snapshot(name: "zone-picker-search", size: CGSize(width: 300, height: 380)) {
        AnyView(ZonePicker(model: pickerModel(query: "new"), selected: nil) { _ in })
    },
    Snapshot(name: "zone-picker-empty", size: CGSize(width: 300, height: 380)) {
        AnyView(ZonePicker(model: pickerModel(query: "zzz"), selected: nil) { _ in })
    },
]
