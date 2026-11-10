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
                difference
                side(model.b) {
                    ZoneButton(zone: model.zoneB, now: model.instant, accessibilityName: "Second time zone") { model.selectB($0) }
                }
            }
            scrubber
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 24)
        .frame(minWidth: 600)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func side<Title: View>(_ display: ZoneDisplay, @ViewBuilder title: () -> Title) -> some View {
        TimeDisplay(time: display.time, date: display.dateText, offset: display.offsetText, title: title)
            .frame(maxWidth: .infinity)
    }

    /// B's difference from A, the swap button, and B's day relative to A's.
    private var difference: some View {
        VStack(spacing: 6) {
            Text(model.differenceText)
                .font(.headline)
                .monospacedDigit()
            Button {
                model.swap()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
            }
            .buttonStyle(.borderless)
            .help("Swap time zones")
            .accessibilityLabel("Swap time zones")
            Text(model.dayRelationText)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .fixedSize()
        .accessibilityElement(children: .contain)
    }

    private var scrubber: some View {
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
            .overlay(alignment: .top) { scrubberMarks }
            .padding(.bottom, 18)
            Button("Now") { model.returnToNow() }
                .disabled(model.isLive)
                .help("Return to the current time")
                .padding(.bottom, 18)
        }
    }

    /// Hour labels under the slider's track, every six hours. Decoration: the slider's value
    /// already tells VoiceOver the time.
    private var scrubberMarks: some View {
        GeometryReader { proxy in
            // The thumb's center travels from `inset` to `width - inset`.
            let inset: CGFloat = 10
            let track = proxy.size.width - 2 * inset
            ForEach(model.scrubberMarks, id: \.minuteOfDay) { mark in
                Text(mark.label)
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .position(
                        x: inset + track * CGFloat(mark.minuteOfDay) / CGFloat(24 * 60 - 15),
                        y: proxy.size.height + 10
                    )
            }
        }
        .accessibilityHidden(true)
    }
}
