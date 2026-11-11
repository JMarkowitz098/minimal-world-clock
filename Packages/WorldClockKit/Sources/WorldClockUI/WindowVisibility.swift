import SwiftUI

extension View {
    /// Calls `action` with whether this view's window can be seen, now and whenever that changes.
    /// It can't be seen when minimized, fully covered, on another Space, in a hidden app, or on
    /// a sleeping display (`NSWindow.occlusionState`, which Apple's Energy Efficiency Guide for
    /// Mac Apps recommends for stopping work nobody sees). SwiftUI's `scenePhase` doesn't report
    /// a minimized window on macOS. Does nothing on other platforms.
    public func onWindowVisibilityChange(_ action: @escaping @MainActor (Bool) -> Void) -> some View {
        #if os(macOS)
        background(WindowVisibility(action: action))
        #else
        self
        #endif
    }
}

#if os(macOS)
import AppKit

private struct WindowVisibility: NSViewRepresentable {
    let action: @MainActor (Bool) -> Void

    func makeNSView(context: Context) -> VisibilityView {
        let view = VisibilityView()
        view.action = action
        return view
    }

    func updateNSView(_ view: VisibilityView, context: Context) {
        view.action = action
    }

    /// Watches the occlusion state of whichever window it's in. (A selector observer: the
    /// notification center drops it when the view goes away, so there's no `deinit`.)
    final class VisibilityView: NSView {
        var action: (@MainActor (Bool) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let center = NotificationCenter.default
            center.removeObserver(self, name: NSWindow.didChangeOcclusionStateNotification, object: nil)
            guard let window else { return }
            center.addObserver(self, selector: #selector(occlusionChanged),
                               name: NSWindow.didChangeOcclusionStateNotification, object: window)
            occlusionChanged()
        }

        @objc private func occlusionChanged() {
            guard let window else { return }
            action?(window.occlusionState.contains(.visible))
        }
    }
}
#endif
