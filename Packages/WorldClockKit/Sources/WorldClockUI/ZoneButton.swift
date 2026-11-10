import SwiftUI
import WorldClockCore

/// A zone's city name with a chevron; clicking it opens the zone picker in a popover.
/// Used as `TimeDisplay`'s title in the Clock and Compare windows.
public struct ZoneButton: View {
    let zone: Zone
    let now: Date
    let accessibilityName: String
    let onSelect: (Zone) -> Void
    @State private var picker: ZonePickerViewModel?

    /// - Parameters:
    ///   - now: the instant the picker's offsets are shown for.
    ///   - accessibilityName: what VoiceOver calls the button, e.g. "Time zone".
    public init(zone: Zone, now: Date, accessibilityName: String = "Time zone", onSelect: @escaping (Zone) -> Void) {
        self.zone = zone
        self.now = now
        self.accessibilityName = accessibilityName
        self.onSelect = onSelect
    }

    public var body: some View {
        Button {
            picker = ZonePickerViewModel(now: now)
        } label: {
            HStack(spacing: 4) {
                Text(zone.city)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .font(.title2.weight(.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(zone.city)
        .accessibilityHint("Choose a different time zone")
        .popover(item: $picker, arrowEdge: .bottom) { picker in
            ZonePicker(model: picker, selected: zone) { zone in
                onSelect(zone)
                self.picker = nil
            }
        }
    }
}
