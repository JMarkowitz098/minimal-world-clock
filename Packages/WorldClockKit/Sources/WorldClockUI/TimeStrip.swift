import SwiftUI

/// The Compare window's scrubber: a 24-hour track drawn in the theme's colors (the system slider
/// ignores the tint on macOS), with a tick per hour, labels every six hours, and an accent fill
/// and thumb. Dragging or clicking snaps to quarter hours; arrow keys and VoiceOver's adjust
/// step by 15 minutes.
struct TimeStrip: View {
    /// The thumb's position, in minutes since midnight.
    let minuteOfDay: Int
    let marks: [CompareViewModel.ScrubberMark]
    let theme: Theme
    /// What VoiceOver calls it and reads as its value: "Time in New York", "3:00 PM".
    let label: String
    let value: String
    let onChange: (Int) -> Void

    private static let lastMinute = 24 * 60 - 15
    private static let step = 15
    /// Room at each end for half the thumb.
    private let inset: CGFloat = 7
    private let trackY: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let track = proxy.size.width - 2 * inset
            let x = { (minute: Int) in inset + track * CGFloat(minute) / CGFloat(24 * 60) }
            ZStack(alignment: .topLeading) {
                ForEach(0..<25) { hour in
                    let major = hour % 6 == 0
                    Rectangle().fill(theme.text.opacity(major ? 0.5 : 0.25))
                        .frame(width: 1, height: major ? 10 : 6)
                        .position(x: x(hour * 60), y: trackY)
                }
                Capsule().fill(theme.text.opacity(0.15))
                    .frame(width: track, height: 3)
                    .position(x: inset + track / 2, y: trackY)
                Capsule().fill(theme.accent)
                    .frame(width: x(minuteOfDay) - inset, height: 3)
                    .position(x: (inset + x(minuteOfDay)) / 2, y: trackY)
                Circle().fill(theme.accent)
                    .frame(width: 14, height: 14)
                    .position(x: x(minuteOfDay), y: trackY)
                ForEach(marks, id: \.minuteOfDay) { mark in
                    Text(mark.label)
                        .font(.caption)
                        .monospacedDigit()
                        .opacity(0.75)
                        .fixedSize()
                        .position(x: x(mark.minuteOfDay), y: trackY + 18)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    let minutes = Double(drag.location.x - inset) / Double(track) * Double(24 * 60)
                    onChange(Self.snapped(minutes))
                }
            )
        }
        .frame(height: 40)
        .focusable()
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
