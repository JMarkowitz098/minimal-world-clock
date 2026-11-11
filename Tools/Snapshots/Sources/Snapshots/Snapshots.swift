import AppKit
import SwiftUI

/// The repository root, found from this source file's location.
let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// Renders every catalog entry whose name contains the optional filter argument, in light and
/// dark mode (or only light, for `lightOnly` entries), to build/snapshots/<name>-<light|dark>.png
/// at 2× scale. Design prototypes (`prototypes`, temporary option sheets) go to
/// build/prototypes/ instead, so they never mix with the views the app ships.
@main
struct Snapshots {
    @MainActor static func main() throws {
        let filter = CommandLine.arguments.dropFirst().first ?? ""
        let folders = [(catalog, root.appending(path: "build/snapshots")),
                       (prototypes, root.appending(path: "build/prototypes"))]
        // Delete renders no entry makes any more (e.g. a removed prototype sheet), so each
        // folder only ever holds current views.
        for (entries, folder) in folders {
            try removeStale(in: folder, keeping: entries)
        }

        let selected = folders.flatMap { entries, folder in
            entries.filter { filter.isEmpty || $0.name.contains(filter) }.map { ($0, folder) }
        }
        guard !selected.isEmpty else {
            print("No snapshot matches \"\(filter)\". Names: \((catalog + prototypes).map(\.name).joined(separator: ", "))")
            exit(1)
        }
        for (snapshot, folder) in selected {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            for variant in snapshot.variants {
                let file = folder.appending(path: snapshot.fileName(variant))
                try render(snapshot, variant: variant, to: file)
                print("Wrote \(file.path)")
            }
        }
    }

    @MainActor static func removeStale(in folder: URL, keeping entries: [Snapshot]) throws {
        guard FileManager.default.fileExists(atPath: folder.path) else { return }
        let current = Set(entries.flatMap { snapshot in snapshot.variants.map { snapshot.fileName($0) } })
        for file in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        where file.pathExtension == "png" && !current.contains(file.lastPathComponent) {
            try FileManager.default.removeItem(at: file)
            print("Removed stale \(file.lastPathComponent)")
        }
    }

    /// Draws through an `NSHostingView` rather than `ImageRenderer`, which can't draw
    /// AppKit-backed controls (text fields, lists, sliders) and shows a placeholder instead.
    @MainActor static func render(_ snapshot: Snapshot, variant: Snapshot.Variant, to file: URL) throws {
        let scheme = variant.scheme
        let content = snapshot.view()
            .frame(width: snapshot.size.width, height: snapshot.size.height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, scheme)
            // The appearance below alone doesn't reach SwiftUI's `colorSchemeContrast` in an
            // offscreen view; this is the setter Xcode previews use.
            .environment(\._colorSchemeContrast, variant.increasedContrast ? .increased : .standard)
        let view = NSHostingView(rootView: content)
        view.frame = CGRect(origin: .zero, size: snapshot.size)
        // AppKit colors (windowBackgroundColor…) and controls follow the view's appearance,
        // not SwiftUI's colorScheme, so set both.
        // The high-contrast appearances are what Increase Contrast gives a window; SwiftUI's
        // `colorSchemeContrast` follows them.
        let appearance: NSAppearance.Name = switch (scheme, variant.increasedContrast) {
        case (.dark, false): .darkAqua
        case (.dark, true): .accessibilityHighContrastDarkAqua
        case (_, false): .aqua
        case (_, true): .accessibilityHighContrastAqua
        }
        view.appearance = NSAppearance(named: appearance)!
        // An offscreen window gives the view a real view hierarchy to lay out and draw in.
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = view
        view.layoutSubtreeIfNeeded()

        let scale = 2
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(snapshot.size.width) * scale, pixelsHigh: Int(snapshot.size.height) * scale,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { throw CocoaError(.fileWriteUnknown) }
        rep.size = snapshot.size
        view.cacheDisplay(in: view.bounds, to: rep)
        guard let png = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
        try png.write(to: file)
    }
}
