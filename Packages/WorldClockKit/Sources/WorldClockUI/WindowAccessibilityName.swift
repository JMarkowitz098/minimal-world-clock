#if os(macOS)
import AppKit
import SwiftUI

/// Names the window's content view (SwiftUI's hosting view) for VoiceOver: unnamed, Accessibility
/// Inspector's audit flags it ("Element has no description"), and SwiftUI's `.accessibilityLabel`
/// only names a group inside it. Place it in a `.background`.
struct WindowAccessibilityName: NSViewRepresentable {
    let name: String

    func makeNSView(context: Context) -> NameView {
        NameView()
    }

    func updateNSView(_ view: NameView, context: Context) {
        view.name = name
    }

    final class NameView: NSView {
        var name = "" {
            didSet { apply() }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            apply()
        }

        private func apply() {
            window?.contentView?.setAccessibilityLabel(name)
        }
    }
}
#endif
