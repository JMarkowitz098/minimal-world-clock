import SwiftUI
import WorldClockCore

/// The Clock window: one zone's time. The zone name opens the zone picker.
public struct ClockView: View {
    let model: ClockViewModel
    @State private var picker: ZonePickerViewModel?

    public init(model: ClockViewModel) {
        self.model = model
    }

    public var body: some View {
        TimeDisplay(time: model.timeText, date: model.dateText, offset: model.offsetText) {
            Button {
                picker = ZonePickerViewModel(now: model.now)
            } label: {
                HStack(spacing: 4) {
                    Text(model.cityText)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .font(.title2.weight(.medium))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Time zone")
            .accessibilityValue(model.cityText)
            .accessibilityHint("Choose a different time zone")
            .popover(item: $picker, arrowEdge: .bottom) { picker in
                ZonePicker(model: picker, selected: model.zone) { zone in
                    model.select(zone)
                    self.picker = nil
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .frame(minWidth: 320)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

extension ZonePickerViewModel: Identifiable {}
