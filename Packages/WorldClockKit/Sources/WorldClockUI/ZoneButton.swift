import SwiftUI
import WorldClockCore

/// A button that opens the zone picker in a popover: either the zone's city name with a
/// chevron (Compare: `TimeDisplay`'s title) or the city followed by a globe (Clock: in the
/// window's top strip, beside the close/minimize buttons).
public struct ZoneButton: View {
    public enum Style: Sendable {
        /// "Tokyo ⌄"
        case cityName
        /// "Tokyo 🌐"
        case cityWithGlobe
    }

    let zone: Zone
    let now: Date
    let style: Style
    let accessibilityName: String
    let onSelect: (Zone) -> Void
    @State private var picker: ZonePickerViewModel?

    /// - Parameters:
    ///   - now: the instant the picker's offsets are shown for.
    ///   - accessibilityName: what VoiceOver calls the button, e.g. "Time zone".
    public init(zone: Zone, now: Date, style: Style = .cityName, accessibilityName: String = "Time zone",
                onSelect: @escaping (Zone) -> Void) {
        self.zone = zone
        self.now = now
        self.style = style
        self.accessibilityName = accessibilityName
        self.onSelect = onSelect
    }

    public var body: some View {
        Button {
            picker = ZonePickerViewModel(now: now)
        } label: {
            switch style {
            case .cityName:
                HStack(spacing: 4) {
                    Text(zone.city)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .font(.title2.weight(.medium))
            case .cityWithGlobe:
                HStack(spacing: 6) {
                    Text(zone.city)
                        .font(.headline)
                        .lineLimit(1)
                    Image(systemName: "globe")
                        .font(.callout)
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .help("Choose a time zone")
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
