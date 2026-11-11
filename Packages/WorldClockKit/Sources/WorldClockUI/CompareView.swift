import SwiftUI
import WorldClockCore

/// The Compare window (design "H", chosen in M6): two zones side by side at one instant, each
/// with its city + globe (the zone picker), a time you can click to type, and its date; B's date
/// says "next day" etc. when the days differ. Between them: B's difference (`+14 h`) and the swap
/// button. Below: a 24-hour strip that sets a time of day in zone A. While scrubbed, a "Now"
/// pill in the title bar's strip returns to the live time.
///
/// The window frame (no title bar, theme, scaling with the window, hover edge, drag to move) is
/// `ScalingWindow`, shared with the Clock.
public struct CompareView: View {
    let model: CompareViewModel
    @Environment(\.theme) private var theme

    public init(model: CompareViewModel) {
        self.model = model
    }

    public var body: some View {
        ScalingWindow(minWidth: 600, stripNudge: 3, accessibilityName: "Compare") { layout in
            content(scale: layout.scale, measuring: layout.measuring)
        } strip: {
            // "Now" only while scrubbed; like the Clock's city, it keeps its size as the window
            // grows, a little below the strip's center (asked for by the user in M6).
            if !model.isLive {
                NowButton { model.returnToNow() }
                    .padding(.trailing, 12)
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    /// - Parameter measuring: lay out the widest the content gets as time passes (two-digit
    ///   hours, B's date with its longest day label), so the window's natural size, and with
    ///   it the scale, doesn't change while scrubbing.
    private func content(scale s: CGFloat, measuring: Bool) -> some View {
        VStack(spacing: 18 * s) {
            HStack(alignment: .center, spacing: 12 * s) {
                side(model.a, place: model.placeA, date: model.a.dateText, spokenDate: model.a.dateText,
                     name: "First time zone",
                     scale: s, measuring: measuring, select: model.selectA, type: model.typeTimeA)
                difference(scale: s)
                side(model.b, place: model.placeB,
                     date: measuring ? model.widestZoneBDateText : model.zoneBDateText,
                     spokenDate: model.zoneBSpokenDate,
                     name: "Second time zone", scale: s, measuring: measuring,
                     select: model.selectB, type: model.typeTimeB)
            }
            TimeStrip(
                minuteOfDay: model.scrubberMinuteOfDay, marks: model.scrubberMarks,
                label: "Time in \(model.a.cityText)", value: model.scrubberSpokenValue, scale: s
            ) { model.scrub(toMinuteOfDay: $0) }
        }
        .padding(.horizontal, 28 * s)
        .padding(.top, 8 * s)
        .padding(.bottom, 16 * s)
    }

    private func side(_ display: ZoneDisplay, place: Place, date: String, spokenDate: String, name: String, scale s: CGFloat,
                      measuring: Bool, select: @escaping (Place) -> Void,
                      type: @escaping (String) -> Bool) -> some View {
        VStack(spacing: 2 * s) {
            ZoneButton(place: place, now: model.instant, scale: s, onSelect: select)
            EditableTime(time: measuring ? TimeStyle.widestTime(display.time) : display.time,
                         label: "Time in \(display.cityText)", scale: s, onCommit: type)
            Text(date).font(.system(size: TimeStyle.dateSize * s)).lineLimit(1)
                .accessibilityLabel(spokenDate)
        }
        .frame(maxWidth: .infinity)
        // VoiceOver reads one zone at a time (city, time, date), not both cities, then both times.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(name)
    }

    /// B's difference from A (accent) above the swap button.
    private func difference(scale s: CGFloat) -> some View {
        VStack(spacing: 6 * s) {
            Text(model.differenceText)
                .font(.system(size: TimeStyle.differenceSize * s, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(theme.accent)
                .accessibilityLabel(model.spokenDifference)
            SwapButton(scale: s) { model.swap() }
        }
        .fixedSize()
        // Its own group between the zones' (unlabeled, it was folded into the first zone's).
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Difference")
    }
}

/// The accent swap arrows; a circle behind them on hover, like the city button's pill. The
/// circle and the click area reach past the arrows without changing the layout.
private struct SwapButton: View {
    let scale: CGFloat
    let action: () -> Void
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: TimeStyle.differenceSize * scale))
                .foregroundStyle(theme.accent)
                .background(Circle().inset(by: -6 * scale).fill(theme.accent.opacity(isHovered ? Theme.hoverFill : 0)))
                .contentShape(Circle().inset(by: -6 * scale))
                .trackingHover($isHovered)
        }
        .buttonStyle(.plain)
        .help("Swap time zones")
        .accessibilityLabel("Swap time zones")
    }
}

/// "↩ Now" in the background color on a solid accent pill (solid, not tinted, for contrast:
/// M8); a ring around it on hover.
private struct NowButton: View {
    let action: () -> Void
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.uturn.backward").font(.caption.weight(.semibold))
                Text("Now").font(.headline)
            }
            .foregroundStyle(theme.background)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(theme.accent, in: Capsule())
            .padding(2)
            .overlay(Capsule().strokeBorder(isHovered ? theme.ring(0.4) : .clear, lineWidth: 2))
            .contentShape(Capsule())
            .trackingHover($isHovered)
        }
        .buttonStyle(.plain)
        .help("Return to the current time")
        .accessibilityLabel("Return to now")
    }
}
