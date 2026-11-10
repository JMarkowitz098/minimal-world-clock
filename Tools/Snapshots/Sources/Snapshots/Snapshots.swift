import AppKit
import SwiftUI

/// The repository root, found from this source file's location.
let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// Renders every catalog entry whose name contains the optional filter argument, in light and
/// dark mode (or only light, for `lightOnly` entries), to build/snapshots/<name>-<light|dark>.png
/// at 2× scale.
@main
struct Snapshots {
    @MainActor static func main() throws {
        let filter = CommandLine.arguments.dropFirst().first ?? ""
        let output = root.appending(path: "build/snapshots")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        // Delete renders no catalog entry makes any more (e.g. a removed prototype sheet), so the
        // folder only ever holds current views.
        let current = Set(catalog.flatMap { snapshot in snapshot.schemes.map { snapshot.fileName($0) } })
        for file in try FileManager.default.contentsOfDirectory(at: output, includingPropertiesForKeys: nil)
        where file.pathExtension == "png" && !current.contains(file.lastPathComponent) {
            try FileManager.default.removeItem(at: file)
            print("Removed stale \(file.lastPathComponent)")
        }

        let selected = catalog.filter { filter.isEmpty || $0.name.contains(filter) }
        guard !selected.isEmpty else {
            print("No snapshot matches \"\(filter)\". Names: \(catalog.map(\.name).joined(separator: ", "))")
            exit(1)
        }
        for snapshot in selected {
            for scheme in snapshot.schemes {
                let file = output.appending(path: snapshot.fileName(scheme))
                try render(snapshot, scheme: scheme, to: file)
                print("Wrote \(file.path)")
            }
        }
    }

    /// Draws through an `NSHostingView` rather than `ImageRenderer`, which can't draw
    /// AppKit-backed controls (text fields, lists, sliders) and shows a placeholder instead.
    @MainActor static func render(_ snapshot: Snapshot, scheme: ColorScheme, to file: URL) throws {
        let content = snapshot.view()
            .frame(width: snapshot.size.width, height: snapshot.size.height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, scheme)
        let view = NSHostingView(rootView: content)
        view.frame = CGRect(origin: .zero, size: snapshot.size)
        // AppKit colors (windowBackgroundColor…) and controls follow the view's appearance,
        // not SwiftUI's colorScheme, so set both.
        view.appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)!
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
