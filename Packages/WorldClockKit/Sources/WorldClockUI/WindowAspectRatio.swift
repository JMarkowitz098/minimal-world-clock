#if os(macOS)
import AppKit
import SwiftUI

/// Keeps the window this view is in at `ratio` (width : height of the whole window content,
/// title bar strip included) while the user resizes it. Place it in a `.background`.
struct WindowAspectRatio: NSViewRepresentable {
    let ratio: CGSize

    func makeNSView(context: Context) -> AspectRatioView {
        AspectRatioView()
    }

    func updateNSView(_ view: AspectRatioView, context: Context) {
        view.ratio = ratio
    }

    /// Applies the ratio once it has a window, and again whenever the ratio changes.
    final class AspectRatioView: NSView {
        var ratio: CGSize = .zero {
            didSet { apply() }
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            apply()
        }

        /// Sets the ratio for resizing, and fits the current size to it (AppKit only enforces
        /// the ratio while the user drags, not on a restored frame): the height follows the
        /// width, and the top-left corner stays put.
        private func apply() {
            guard ratio.width > 0, ratio.height > 0, let window else { return }
            window.contentAspectRatio = ratio
            let content = window.contentLayoutRect.size == .zero
                ? window.frame.size : window.contentRect(forFrameRect: window.frame).size
            let height = (content.width * ratio.height / ratio.width).rounded()
            guard abs(height - content.height) > 1 else { return }
            var frame = window.frame
            let newFrame = window.frameRect(forContentRect: NSRect(origin: .zero, size: CGSize(width: content.width, height: height)))
            frame.origin.y += frame.height - newFrame.height
            frame.size = newFrame.size
            window.setFrame(frame, display: true)
        }
    }
}
#endif
