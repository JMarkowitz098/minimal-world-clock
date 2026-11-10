import SwiftUI
import WorldClockCore

/// The Clock window: one zone's time. The zone name opens the zone picker.
public struct ClockView: View {
    let model: ClockViewModel

    public init(model: ClockViewModel) {
        self.model = model
    }

    public var body: some View {
        TimeDisplay(time: model.timeText, date: model.dateText, offset: model.offsetText) {
            ZoneButton(zone: model.zone, now: model.now) { model.select($0) }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .frame(minWidth: 320)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}
