import SwiftUI

extension Animation {
    /// How hover effects fade in and out (pills, edges, the strip's track).
    static let hover = Animation.easeOut(duration: 0.15)
}

extension View {
    /// Keeps `isHovered` in step with the pointer, fading the change (`Animation.hover`), or
    /// switching instantly when Reduce Motion is on. Every faded hover effect goes through this
    /// (the zone picker's rows switch instantly anyway).
    func trackingHover(_ isHovered: Binding<Bool>) -> some View {
        modifier(TrackingHover(isHovered: isHovered))
    }
}

private struct TrackingHover: ViewModifier {
    @Binding var isHovered: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.onHover { hovering in
            withAnimation(reduceMotion ? nil : .hover) { isHovered = hovering }
        }
    }
}
