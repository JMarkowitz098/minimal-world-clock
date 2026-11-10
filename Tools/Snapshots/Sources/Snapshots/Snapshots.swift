import AppKit
import SwiftUI

/// The repository root, found from this source file's location.
let root = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

/// Renders every catalog entry whose name contains the optional filter argument, in light and
/// dark mode, to build/snapshots/<name>-<light|dark>.png at 2× scale.
@main
struct Snapshots {
    @MainActor static func main() throws {
        let filter = CommandLine.arguments.dropFirst().first ?? ""
        let output = root.appending(path: "build/snapshots")
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        let selected = catalog.filter { filter.isEmpty || $0.name.contains(filter) }
        guard !selected.isEmpty else {
            print("No snapshot matches \"\(filter)\". Names: \(catalog.map(\.name).joined(separator: ", "))")
            exit(1)
        }
        for snapshot in selected {
            for scheme in [ColorScheme.light, .dark] {
                let file = output.appending(path: "\(snapshot.name)-\(scheme == .light ? "light" : "dark").png")
                try render(snapshot, scheme: scheme, to: file)
                print("Wrote \(file.path)")
            }
        }
    }

    @MainActor static func render(_ snapshot: Snapshot, scheme: ColorScheme, to file: URL) throws {
        let content = snapshot.view()
            .frame(width: snapshot.size.width, height: snapshot.size.height)
            .background(Color(nsColor: .windowBackgroundColor))
            .environment(\.colorScheme, scheme)
        // AppKit colors (windowBackgroundColor…) resolve against the current drawing
        // appearance, not SwiftUI's colorScheme, so set both.
        let appearance = NSAppearance(named: scheme == .light ? .aqua : .darkAqua)!
        var png: Data?
        appearance.performAsCurrentDrawingAppearance {
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            if let image = renderer.cgImage {
                png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
            }
        }
        guard let png else { throw CocoaError(.fileWriteUnknown) }
        try png.write(to: file)
    }
}
