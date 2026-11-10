import SwiftUI
import WorldClockCore

/// The Compare window (design "H", chosen in M6): two zones side by side at one instant, each
/// with its city + globe (the zone picker), a time you can click to type, and its date; B's date
/// says "next day" etc. when the days differ. Between them: B's difference (`+14 h`) and the swap
/// button. Below: a 24-hour strip that sets a time of day in zone A. While scrubbed, a "Now"
/// pill in the title bar's strip returns to the live time.
///
/// Laid out for a window without a title bar, like `ClockView`: the content respects the top
/// safe area; the background and the top strip extend into it.
public struct CompareView: View {
    let model: CompareViewModel
    let themes: ThemePair
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { themes.theme(for: colorScheme) }
    @State private var isHovered = false

    public init(model: CompareViewModel, themes: ThemePair) {
        self.model = model
        self.themes = themes
    }

    public var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                side(model.a, zone: model.zoneA, date: model.a.dateText, name: "First time zone", select: model.selectA, type: model.typeTimeA)
                difference
                side(model.b, zone: model.zoneB, date: model.zoneBDateText, name: "Second time zone", select: model.selectB, type: model.typeTimeB)
            }
            TimeStrip(
                minuteOfDay: model.scrubberMinuteOfDay, marks: model.scrubberMarks, theme: theme,
                label: "Time in \(model.a.cityText)", value: model.a.timeText
            ) { model.scrub(toMinuteOfDay: $0) }
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(minWidth: 600)
        .foregroundStyle(theme.text)
        .overlay(alignment: .top) { topStrip }
        .background(theme.background.ignoresSafeArea())
        .overlay { HoverEdge(color: theme.accent, isVisible: isHovered) }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
        }
        #if os(macOS)
        // Dragging the background moves the window; the strip, times and buttons keep their own clicks.
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
        #endif
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func side(_ display: ZoneDisplay, zone: Zone, date: String, name: String,
                      select: @escaping (Zone) -> Void, type: @escaping (String) -> Bool) -> some View {
        VStack(spacing: 2) {
            ZoneButton(zone: zone, now: model.instant, accessibilityName: name,
                       theme: theme, onSelect: select)
            EditableTime(time: display.time, label: "Time in \(display.cityText)", theme: theme, onCommit: type)
            Text(date).font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
    }

    /// B's difference from A (accent) above the swap button.
    private var difference: some View {
        VStack(spacing: 6) {
            Text(model.differenceText)
                .font(.title3.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(theme.accent)
            Button {
                model.swap()
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title3)
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
            .help("Swap time zones")
            .accessibilityLabel("Swap time zones")
        }
        .fixedSize()
        .accessibilityElement(children: .contain)
    }

    /// "Now", right-aligned in the title bar's strip, only while scrubbed.
    private var topStrip: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                if !model.isLive { NowButton(theme: theme) { model.returnToNow() } }
            }
            .padding(.trailing, 6)
            .frame(height: proxy.safeAreaInsets.top)
            .offset(y: -proxy.safeAreaInsets.top)
        }
    }
}

/// The accent "↩ Now" pill; a deeper pill on hover.
private struct NowButton: View {
    let theme: Theme
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.uturn.backward").font(.caption.weight(.semibold))
                Text("Now").font(.headline)
            }
            .foregroundStyle(theme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(theme.accent.opacity(isHovered ? 0.25 : 0.15), in: Capsule())
            .contentShape(Capsule())
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
            }
        }
        .buttonStyle(.plain)
        .help("Return to the current time")
        .accessibilityLabel("Return to now")
    }
}
