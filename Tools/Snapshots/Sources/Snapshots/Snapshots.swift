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
        if filter == "--app-store" {
            try renderAppStoreShots()
            return
        }
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

    @MainActor static func render(_ snapshot: Snapshot, variant: Snapshot.Variant, to file: URL) throws {
        let rep = try bitmap(of: snapshot.view(), size: snapshot.size, variant: variant)
        try write(rep, to: file)
    }

    @MainActor static func write(_ rep: NSBitmapImageRep, to file: URL) throws {
        guard let png = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
        try png.write(to: file)
    }

    /// Draws `view` at `size` points, 2× scale unless `scale` says otherwise. Through an `NSHostingView` rather than
    /// `ImageRenderer`, which can't draw AppKit-backed controls (text fields, lists, sliders)
    /// and shows a placeholder instead. Each call gets its own offscreen window, which the
    /// Clock and Compare views reshape to their aspect ratio (so App Store screenshots draw
    /// each window on its own, then place the images).
    @MainActor static func bitmap(of view: AnyView, size: CGSize,
                                  variant: Snapshot.Variant = .init(scheme: .light, increasedContrast: false),
                                  scale: CGFloat = 2) throws -> NSBitmapImageRep {
        let scheme = variant.scheme
        let content = view
            .frame(width: size.width, height: size.height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, scheme)
            // The appearance below alone doesn't reach SwiftUI's `colorSchemeContrast` in an
            // offscreen view; this is the setter Xcode previews use.
            .environment(\._colorSchemeContrast, variant.increasedContrast ? .increased : .standard)
        let view = NSHostingView(rootView: content)
        view.frame = CGRect(origin: .zero, size: size)
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

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ) else { throw CocoaError(.fileWriteUnknown) }
        rep.size = size
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep
    }
}
