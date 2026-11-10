import SwiftUI

/// The Compare window's scrubber: a 24-hour track drawn in the theme's colors (the system slider
/// ignores the tint on macOS), with a tick per hour, labels every six hours, and an accent fill
/// and thumb. Dragging or clicking snaps to quarter hours; arrow keys and VoiceOver's adjust
/// step by 15 minutes. Hovering darkens and thickens the track (gray and accent parts), rings the
/// thumb (the keyboard focus ring), and marks the quarter hour a click would jump to.
struct TimeStrip: View {
    /// The thumb's position, in minutes since midnight.
    let minuteOfDay: Int
    let marks: [CompareViewModel.ScrubberMark]
    /// What VoiceOver calls it and reads as its value: "Time in New York", "3:00 PM".
    let label: String
    let value: String
    /// Size relative to normal (Compare scales with its window).
    var scale: CGFloat = 1
    let onChange: (Int) -> Void

    private static let lastMinute = 24 * 60 - 15
    private static let step = 15
    /// Room at each end for half the thumb.
    private var inset: CGFloat { 7 * scale }
    private var trackY: CGFloat { 12 * scale }
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var isHovered = false
    /// The quarter hour under the pointer (where a click moves the thumb), while hovering.
    @State private var hoverMinute: Int?
    private var trackHeight: CGFloat { (isHovered ? 5 : 3) * scale }

    var body: some View {
        GeometryReader { proxy in
            let track = proxy.size.width - 2 * inset
            let x = { (minute: Int) in inset + track * CGFloat(minute) / CGFloat(24 * 60) }
            ZStack(alignment: .topLeading) {
                Capsule().fill(theme.text.opacity(isHovered ? 0.35 : 0.15))
                    .frame(width: track, height: trackHeight)
                    .position(x: inset + track / 2, y: trackY)
                // Over the gray track (the hover thickens it), under the accent fill.
                ForEach(0..<25) { hour in
                    let major = hour % 6 == 0
                    Rectangle().fill(theme.text.opacity(major ? 0.5 : 0.25))
                        .frame(width: 1, height: (major ? 10 : 6) * scale)
                        .position(x: x(hour * 60), y: trackY)
                }
                Capsule().fill(theme.accent)
                    .frame(width: x(minuteOfDay) - inset, height: trackHeight)
                    .position(x: (inset + x(minuteOfDay)) / 2, y: trackY)
                if let hoverMinute, hoverMinute != minuteOfDay {
                    // Text color: it shows on the gray track and on the accent fill.
                    Capsule().fill(theme.text.opacity(0.8))
                        .frame(width: 2 * scale, height: 16 * scale)
                        .position(x: x(hoverMinute), y: trackY)
                }
                Circle().fill(theme.accent)
                    .frame(width: 14 * scale, height: 14 * scale)
                    // Keyboard focus and hover: a soft ring around the thumb (instead of the
                    // system's focus rectangle, which ignores the theme and covers the labels).
                    .padding(4 * scale)
                    .overlay(Circle().strokeBorder(theme.accent.opacity(isFocused || isHovered ? 0.4 : 0), lineWidth: 3 * scale))
                    .position(x: x(minuteOfDay), y: trackY)
                ForEach(marks, id: \.minuteOfDay) { mark in
                    Text(mark.label)
                        .font(.system(size: TimeStyle.stripLabelSize * scale))
                        .monospacedDigit()
                        .opacity(0.75)
                        .fixedSize()
                        .position(x: x(mark.minuteOfDay), y: trackY + 18 * scale)
                }
            }
            .contentShape(Rectangle())
            .onContinuousHover { phase in
                switch phase {
                case .active(let point):
                    hoverMinute = Self.snapped(Double(point.x - inset) / Double(track) * Double(24 * 60))
                    if !isHovered { withAnimation(reduceMotion ? nil : .hover) { isHovered = true } }
                case .ended:
                    hoverMinute = nil
                    withAnimation(reduceMotion ? nil : .hover) { isHovered = false }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    let minutes = Double(drag.location.x - inset) / Double(track) * Double(24 * 60)
                    onChange(Self.snapped(minutes))
                }
            )
        }
        .frame(height: 40 * scale)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(.leftArrow) { nudge(-1); return .handled }
        .onKeyPress(.rightArrow) { nudge(1); return .handled }
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: nudge(1)
            case .decrement: nudge(-1)
            @unknown default: break
            }
        }
    }

    private func nudge(_ steps: Int) {
        onChange(Self.snapped(Double(minuteOfDay + steps * Self.step)))
    }

    private static func snapped(_ minutes: Double) -> Int {
        min(max(Int((minutes / Double(step)).rounded()) * step, 0), lastMinute)
    }
}
