import SwiftUI
import WorldClockCore

/// "Tokyo 🌐": the zone's city followed by a globe, in the accent color; opens the zone picker
/// in a popover. The Clock window shows it in the top strip; Compare above each time.
public struct ZoneButton: View {
    let zone: Zone
    let now: Date
    let scale: CGFloat
    let onSelect: (Zone) -> Void
    @Environment(\.theme) private var theme
    @State private var picker: ZonePickerViewModel?
    /// Whether the pointer is over the button (shows a pill behind it).
    @State private var isHovered = false

    /// - Parameters:
    ///   - now: the instant the picker's offsets are shown for.
    ///   - scale: size relative to normal (Compare scales with its window).
    public init(zone: Zone, now: Date, scale: CGFloat = 1, onSelect: @escaping (Zone) -> Void) {
        self.scale = scale
        self.zone = zone
        self.now = now
        self.onSelect = onSelect
    }

    public var body: some View {
        Button {
            picker = ZonePickerViewModel(now: now)
        } label: {
            HStack(spacing: 6 * scale) {
                Text(zone.city)
                    .font(.system(size: TimeStyle.citySize * scale, weight: .bold))
                    .lineLimit(1)
                Image(systemName: "globe")
                    .font(.system(size: TimeStyle.globeSize * scale))
            }
            // Colored here, not by the caller: a foreground style set on the button would
            // also color the popover's contents.
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 8 * scale)
            .padding(.vertical, 3 * scale)
            .background(theme.accent.opacity(isHovered ? Theme.hoverFill : 0), in: Capsule())
            .contentShape(Capsule())
            .trackingHover($isHovered)
        }
        .buttonStyle(.plain)
        .help("Choose a time zone")
        .accessibilityLabel("Time zone")
        .accessibilityValue(zone.city)
        .accessibilityHint("Choose a different time zone")
        .popover(item: $picker, arrowEdge: .bottom) { picker in
            ZonePicker(model: picker, selected: zone) { zone in
                onSelect(zone)
                self.picker = nil
            }
            // Passed on explicitly: a popover is a separate window.
            .environment(\.theme, theme)
            .presentationBackground(theme.surface)
        }
    }
}
