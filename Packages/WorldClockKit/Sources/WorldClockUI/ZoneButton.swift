import SwiftUI
import WorldClockCore

/// "Tokyo 🌐": the zone's city followed by a globe, in the accent color; opens the zone picker
/// in a popover. The Clock window shows it in the top strip; Compare above each time.
public struct ZoneButton: View {
    let zone: Zone
    let now: Date
    let accessibilityName: String
    let theme: Theme?
    let onSelect: (Zone) -> Void
    @State private var picker: ZonePickerViewModel?
    /// Whether the pointer is over the button (shows a pill behind it).
    @State private var isHovered = false

    /// - Parameters:
    ///   - now: the instant the picker's offsets are shown for.
    ///   - accessibilityName: what VoiceOver calls the button, e.g. "Time zone".
    ///   - theme: colors for the button (accent) and the picker popover (surface); `nil` uses the system's.
    public init(zone: Zone, now: Date, accessibilityName: String = "Time zone",
                theme: Theme? = nil, onSelect: @escaping (Zone) -> Void) {
        self.zone = zone
        self.now = now
        self.accessibilityName = accessibilityName
        self.theme = theme
        self.onSelect = onSelect
    }

    public var body: some View {
        Button {
            picker = ZonePickerViewModel(now: now)
        } label: {
            HStack(spacing: 6) {
                Text(zone.city)
                    .font(.headline)
                    .lineLimit(1)
                Image(systemName: "globe")
                    .font(.callout)
            }
            // Colored here, not by the caller: a foreground style set on the button would
            // also color the popover's contents.
            .foregroundStyle(theme?.accent ?? Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((theme?.accent ?? Color.accentColor).opacity(isHovered ? 0.15 : 0), in: Capsule())
            .contentShape(Capsule())
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
            }
        }
        .buttonStyle(.plain)
        .help("Choose a time zone")
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(zone.city)
        .accessibilityHint("Choose a different time zone")
        .popover(item: $picker, arrowEdge: .bottom) { picker in
            ZonePicker(model: picker, selected: zone, theme: theme) { zone in
                onSelect(zone)
                self.picker = nil
            }
            .presentationBackground(theme?.surface ?? Color.clear)
        }
    }
}
