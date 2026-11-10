import SwiftUI

/// A thin accent line along a window's edge, following its rounded corners, shown while the
/// pointer is over the window (Clock and Compare). Ignores the safe area so it reaches the top.
struct HoverEdge: View {
    let isVisible: Bool
    @Environment(\.theme) private var theme
    private var color: Color { theme.accent }

    var body: some View {
        Group {
            if #available(macOS 26, iOS 26, *) {
                // Centered on the edge; the window clips the outer half, leaving 2 pt.
                ConcentricRectangle().stroke(color.opacity(0.6), lineWidth: 4)
            } else {
                RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.6), lineWidth: 2)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
