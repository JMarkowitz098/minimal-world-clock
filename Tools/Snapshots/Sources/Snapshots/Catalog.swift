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

@MainActor let catalog: [Snapshot] = [
    Snapshot(name: "placeholder", size: CGSize(width: 400, height: 200)) {
        AnyView(PlaceholderView())
    },
]
