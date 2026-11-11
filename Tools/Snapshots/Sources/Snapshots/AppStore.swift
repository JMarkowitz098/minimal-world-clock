import AppKit
import SwiftUI
import WorldClockCore
import WorldClockUI

/// App Store screenshots (M11): a headline over the real views, drawn with fixed instants and
/// zones like the catalog. `Snapshots --app-store` writes them to docs/app-store/screenshots/
/// at 2880×1800 (1440×900 points at 2×, an accepted Mac size). The listing text is in
/// docs/app-store/listing.md.
struct AppStoreShot {
    let name: String
    let headline: String
    let subheadline: String
    /// The windows and widgets below the headline. Windows arrive as images (see `window`).
    let content: @MainActor () throws -> AnyView
}

@MainActor let appStoreShots: [AppStoreShot] = [
    AppStoreShot(name: "1-clock",
                 headline: "The time anywhere, at a glance",
                 subheadline: "A calm clock window for any city, with a widget on your desktop.") {
        let clock = try window(ClockView(model: clockModel("Asia/Tokyo")), size: CGSize(width: 640, height: 346), theme: .solarizedLight)
        let london = try shotWidget("Europe/London", theme: .solarizedDark)
        let newYork = try shotWidget("America/New_York", theme: .nord)
        return AnyView(HStack(alignment: .center, spacing: 56) {
            clock
            VStack(spacing: 28) { london; newYork }
        })
    },
    AppStoreShot(name: "2-compare",
                 headline: "Compare two time zones",
                 subheadline: "Drag across the day, or type a time, to find one that works in both places.") {
        let compare = compareModel("America/New_York", "Asia/Tokyo", scrubTo: 19 * 60)
        return AnyView(try window(CompareView(model: compare), size: CGSize(width: 1040, height: 374), theme: .solarizedLight))
    },
    AppStoreShot(name: "3-search",
                 headline: "Find any city",
                 subheadline: "Search by city, country or time zone name, and star the ones you use most.") {
        let clock = clockModel("America/Los_Angeles")
        clock.select(Place(id: "America/Los_Angeles#San Francisco")!)
        let picker = ZonePicker(model: pickerModel(query: "san", favorites: ["Europe/London", "Asia/Tokyo"]),
                                selected: Place(id: "America/Los_Angeles#San Francisco")) { _ in }
        let clockWindow = try window(ClockView(model: clock), size: CGSize(width: 640, height: 346), theme: .solarizedLight)
        let pickerPopover = try popover(picker, size: CGSize(width: 300, height: 380), theme: .solarizedLight)
        // Hanging below the city button at the window's top right, as the real popover does.
        return AnyView(ZStack(alignment: .topLeading) {
            clockWindow
            pickerPopover.padding(.leading, 640 - 230).padding(.top, 36)
        })
    },
    AppStoreShot(name: "4-themes",
                 headline: "Sixteen themes",
                 subheadline: "Pick the colors for the windows and widgets, from Solarized to an amber CRT.") {
        let themes: [Theme] = [.solarizedLight, .nord, .rosePineDawn, .amber,
                               .creamOnNavy, .paper, .dracula, .lcd]
        let zones = ["Asia/Tokyo", "Europe/London", "America/New_York", "Australia/Sydney",
                     "Europe/Paris", "America/Los_Angeles", "Asia/Singapore", "America/Sao_Paulo"]
        let widgets = try zip(zones, themes).map { try shotWidget($0, theme: $1) }
        return AnyView(Grid(horizontalSpacing: 28, verticalSpacing: 28) {
            ForEach(0..<2) { row in
                GridRow {
                    ForEach(0..<4) { column in widgets[row * 4 + column] }
                }
            }
        })
    },
]

/// The marketing background: the app icon's navy and Solarized cream.
private let shotBackground = Color(red: 0x1B / 255, green: 0x2A / 255, blue: 0x4A / 255)
private let shotText = Color(red: 0xFD / 255, green: 0xF6 / 255, blue: 0xE3 / 255)

struct AppStoreShotView: View {
    let shot: AppStoreShot
    let content: AnyView

    var body: some View {
        VStack(spacing: 14) {
            Text(shot.headline)
                .font(.system(size: 60, weight: .semibold))
            Text(shot.subheadline)
                .font(.system(size: 26))
                .opacity(0.85)
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .foregroundStyle(shotText)
        .multilineTextAlignment(.center)
        .padding(.top, 96)
        .padding(.bottom, 64)
        .frame(width: 1440, height: 900)
        .background(shotBackground)
    }
}

/// Draws a Clock or Compare view as a window at `size` (title bar strip included): rendered on
/// its own (those views reshape their window, see `Snapshots.bitmap`), with the window buttons,
/// rounded corners and a shadow. Larger than natural shows the content scaled up, as when the
/// user resizes the window.
@MainActor func window(_ view: some View, size: CGSize, theme: Theme) throws -> some View {
    let windowView = view
        .themed(theme)
        .safeAreaPadding(.top, 28)
        .overlay(alignment: .topLeading) { WindowButtons().padding(.leading, 14).padding(.top, 8) }
    let image = try Snapshots.bitmap(of: AnyView(windowView), size: size)
    return framed(image, cornerRadius: 16)
}

/// The zone picker as the popover shows it, on the theme's surface.
@MainActor func popover(_ view: some View, size: CGSize, theme: Theme) throws -> some View {
    let image = try Snapshots.bitmap(of: AnyView(view.themed(theme)), size: size)
    return framed(image, cornerRadius: 12)
}

private func framed(_ rep: NSBitmapImageRep, cornerRadius: CGFloat) -> some View {
    let image = NSImage(size: rep.size)
    image.addRepresentation(rep)
    let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    return Image(nsImage: image)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.black.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.45), radius: 30, y: 16)
}

/// The red, yellow and green window buttons (drawn: the real ones belong to the window).
private struct WindowButtons: View {
    var body: some View {
        HStack(spacing: 8) {
            ForEach([Color(red: 1, green: 0.37, blue: 0.34), Color(red: 1, green: 0.74, blue: 0.18),
                     Color(red: 0.16, green: 0.78, blue: 0.25)], id: \.self) { color in
                Circle().fill(color).frame(width: 12, height: 12)
            }
        }
    }
}

/// A small desktop widget at 1.25× (macOS's is about 158 points; a bit larger reads better next
/// to a scaled-up window), drawn at that size so it stays sharp.
@MainActor private func shotWidget(_ identifier: String, theme: Theme) throws -> some View {
    let display = WidgetDisplay(zone: Zone(identifier: identifier)!, at: jan15Noon, locale: Locale(identifier: "en_US"))
    let size: CGFloat = 170
    let widget = ZoneWidgetView(display: display, size: .small, frozenTime: jan15Noon)
        .padding(16)
        .frame(width: size, height: size)
        .background(WidgetBackground())
        .containerShape(RoundedRectangle(cornerRadius: 20))
        .environment(\.theme, theme)
    let zoom: CGFloat = 1.25
    let rep = try Snapshots.bitmap(of: AnyView(widget), size: CGSize(width: size, height: size), scale: 2 * zoom)
    let image = NSImage(size: rep.size)
    image.addRepresentation(rep)
    let shape = RoundedRectangle(cornerRadius: 20 * zoom, style: .continuous)
    return Image(nsImage: image)
        .resizable()
        .frame(width: size * zoom, height: size * zoom)
        .clipShape(shape)
        .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
}

extension Snapshots {
    /// Renders every App Store screenshot into docs/app-store/screenshots/.
    @MainActor static func renderAppStoreShots() throws {
        let folder = root.appending(path: "docs/app-store/screenshots")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for shot in appStoreShots {
            let view = AppStoreShotView(shot: shot, content: try shot.content())
            let rep = try bitmap(of: AnyView(view), size: CGSize(width: 1440, height: 900))
            let file = folder.appending(path: "\(shot.name).png")
            try write(rep, to: file)
            print("Wrote \(file.path) (\(rep.pixelsWide)×\(rep.pixelsHigh))")
        }
    }
}
