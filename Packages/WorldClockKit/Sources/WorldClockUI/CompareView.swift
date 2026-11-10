import SwiftUI
import WorldClockCore

/// The Compare window: two zones side by side at one instant, their difference, and a
/// scrubber that sets a time of day in the first zone ("Now" returns to the live time).
public struct CompareView: View {
    let model: CompareViewModel

    public init(model: CompareViewModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                side(model.a) {
                    ZoneButton(zone: model.zoneA, now: model.instant, accessibilityName: "First time zone") { model.selectA($0) }
                }
                Button {
                    model.swap()
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Swap time zones")
                .accessibilityLabel("Swap time zones")
                side(model.b) {
                    ZoneButton(zone: model.zoneB, now: model.instant, accessibilityName: "Second time zone") { model.selectB($0) }
                }
            }
            Text("\(model.b.cityText) \(model.differenceText) · \(model.dayRelationText)")
                .font(.headline)
            scrubber
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(minWidth: 600)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func side<Title: View>(_ display: ZoneDisplay, @ViewBuilder title: () -> Title) -> some View {
        TimeDisplay(time: display.timeText, date: display.dateText, offset: display.offsetText, title: title)
            .frame(maxWidth: .infinity)
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Slider(
                    value: Binding(
                        get: { Double(model.scrubberMinuteOfDay) },
                        // Snaps to quarter hours. Rounding here instead of passing `step`
                        // avoids drawing 95 tick marks.
                        set: { model.scrub(toMinuteOfDay: Int(($0 / 15).rounded()) * 15) }
                    ),
                    in: 0...Double(24 * 60 - 15)
                ) {
                    Text("Time in \(model.a.cityText)")
                }
                .labelsHidden()
                .accessibilityValue("\(model.a.timeText) in \(model.a.cityText)")
                Button("Now") { model.returnToNow() }
                    .disabled(model.isLive)
                    .help("Return to the current time")
            }
            Text("Drag to choose a time in \(model.a.cityText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
