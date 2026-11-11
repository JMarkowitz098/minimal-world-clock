import SwiftUI
import WorldClockCore
import WorldClockUI

/// One view to render. Add an entry whenever a milestone adds or changes a view, using
/// fixed instants and zones (never the real clock) so renders are repeatable.
struct Snapshot {
    let name: String
    let size: CGSize
    /// Render only the light appearance: for views whose colors don't depend on it (a dark
    /// render would be the same picture).
    var lightOnly = false
    /// Also render with Increase Contrast on (`<name>-<light|dark>-contrast.png`).
    var increasedContrast = false
    let view: @MainActor () -> AnyView

    /// One render: an appearance, with or without Increase Contrast.
    struct Variant {
        let scheme: ColorScheme
        let increasedContrast: Bool
    }

    var variants: [Variant] {
        let schemes: [ColorScheme] = lightOnly ? [.light] : [.light, .dark]
        return schemes.flatMap { scheme in
            [Variant(scheme: scheme, increasedContrast: false)]
                + (increasedContrast ? [Variant(scheme: scheme, increasedContrast: true)] : [])
        }
    }

    func fileName(_ variant: Variant) -> String {
        "\(name)-\(variant.scheme == .light ? "light" : "dark")\(variant.increasedContrast ? "-contrast" : "").png"
    }
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

@MainActor func pickerModel(query: String, highlight: Int = 0) -> ZonePickerViewModel {
    let model = ZonePickerViewModel(now: jan15Noon)
    model.query = query
    if highlight > 0 { model.moveHighlight(by: highlight) }
    return model
}

/// The zone picker as the windows show it: Solarized light or dark to match the render, on the
/// theme's `surface` (the popover's background in the app).
struct ThemedPicker: View {
    var query = ""
    var selected: Zone? = nil
    /// Rows to move down with ↓ (0: no highlight).
    var highlight = 0

    var body: some View {
        ZonePicker(model: pickerModel(query: query, highlight: highlight), selected: selected) { _ in }
            .renderTheme()
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
    /// A fixed theme; nil uses Solarized light or dark to match the render.
    var theme: Theme? = nil

    var body: some View {
        let widget = ZoneWidgetView(display: display, size: size, frozenTime: now)
            .padding(16)
            .background(WidgetBackground())
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .containerShape(RoundedRectangle(cornerRadius: 20))
        Group {
            if let theme {
                widget.environment(\.theme, theme)
            } else {
                widget.renderTheme()
            }
        }
        .padding(12)
    }
}

extension View {
    /// Solarized light in the light render and Solarized dark in the dark one, so each render
    /// shows a light and a dark theme (the app's theme no longer follows the appearance).
    func renderTheme() -> some View {
        modifier(RenderTheme())
    }
}

private struct RenderTheme: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        // `themed` (as the app does), so Increase Contrast renders apply.
        content.themed(scheme == .dark ? .solarizedDark : .solarizedLight)
    }
}

/// A login item that does nothing, for the Settings snapshot.
@MainActor final class StillLoginItem: LoginItem {
    var isEnabled = false
    func setEnabled(_ enabled: Bool) throws {}
}

@MainActor func settingsModel() -> SettingsViewModel {
    SettingsViewModel(store: InMemorySettingsStore(), loginItem: StillLoginItem(), baseLocale: Locale(identifier: "en_US"))
}

/// Every theme as a small widget, four per row.
struct ThemeGallery: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(194), spacing: 0), count: 4), spacing: 0) {
            ForEach(Theme.all) { theme in
                WidgetMock(display: WidgetDisplay(zone: Zone(identifier: "Asia/Tokyo")!, at: jan15Noon, locale: Locale(identifier: "en_US")),
                           size: .small, now: jan15Noon, theme: theme)
            }
        }
    }
}

@MainActor let catalog: [Snapshot] = [
    Snapshot(name: "clock", size: CGSize(width: 300, height: 162), increasedContrast: true) {
        AnyView(ClockView(model: clockModel("Asia/Tokyo")).renderTheme().safeAreaPadding(.top, 28))
    },
    // Longest city name in the catalog, to check it fits.
    Snapshot(name: "clock-long-name", size: CGSize(width: 300, height: 162)) {
        AnyView(ClockView(model: clockModel("America/Bahia_Banderas")).renderTheme().safeAreaPadding(.top, 28))
    },
    // Resized larger than natural: the time and date scale up with the window.
    Snapshot(name: "clock-resized", size: CGSize(width: 560, height: 300)) {
        AnyView(ClockView(model: clockModel("Asia/Tokyo")).renderTheme().safeAreaPadding(.top, 28))
    },
    Snapshot(name: "compare", size: CGSize(width: 640, height: 230)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo")).renderTheme().safeAreaPadding(.top, 28))
    },
    // Scrubbed to 3 PM in New York: Tokyo is on the next day, and Now is enabled.
    Snapshot(name: "compare-scrubbed", size: CGSize(width: 640, height: 230), increasedContrast: true) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo", scrubTo: 15 * 60)).renderTheme().safeAreaPadding(.top, 28))
    },
    // Resized larger than natural: everything but the title bar strip scales up.
    Snapshot(name: "compare-resized", size: CGSize(width: 960, height: 345)) {
        AnyView(CompareView(model: compareModel("America/New_York", "Asia/Tokyo", scrubTo: 15 * 60)).renderTheme().safeAreaPadding(.top, 28))
    },
    // Longest city name on both sides, with a half-hour difference.
    Snapshot(name: "compare-long-names", size: CGSize(width: 640, height: 230)) {
        AnyView(CompareView(model: compareModel("America/Bahia_Banderas", "America/St_Johns")).renderTheme().safeAreaPadding(.top, 28))
    },
    // Accra selected (checkmark).
    Snapshot(name: "zone-picker", size: CGSize(width: 300, height: 380), increasedContrast: true) {
        AnyView(ThemedPicker(selected: Zone(identifier: "Africa/Accra")))
    },
    Snapshot(name: "zone-picker-search", size: CGSize(width: 300, height: 380)) {
        AnyView(ThemedPicker(query: "new"))
    },
    // The third row reached with ↓ (keyboard), drawn like a hovered row.
    Snapshot(name: "zone-picker-highlighted", size: CGSize(width: 300, height: 380)) {
        AnyView(ThemedPicker(highlight: 3))
    },
    Snapshot(name: "zone-picker-empty", size: CGSize(width: 300, height: 380)) {
        AnyView(ThemedPicker(query: "zzz"))
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
    Snapshot(name: "settings", size: CGSize(width: 480, height: 640)) {
        AnyView(SettingsView(model: settingsModel()))
    },
    // Every theme on the small widget, to compare them (and check contrast in M8). Light only:
    // each theme has fixed colors, so a dark render would be the same.
    Snapshot(name: "themes", size: CGSize(width: 776, height: 776), lightOnly: true) {
        AnyView(ThemeGallery())
    },
]
