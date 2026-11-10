import SwiftUI
import WorldClockCore
#if canImport(AppKit)
import AppKit
#endif

/// The Compare window (design "H", chosen in M6): two zones side by side at one instant, each
/// with its city + globe (the zone picker), a time you can click to type, and its date; B's date
/// says "next day" etc. when the days differ. Between them: B's difference (`+14 h`) and the swap
/// button. Below: a 24-hour strip that sets a time of day in zone A. While scrubbed, a "Now"
/// pill in the title bar's strip returns to the live time.
///
/// Laid out for a window without a title bar, like `ClockView`: the content respects the top
/// safe area; the background and the top strip extend into it. Also like `ClockView`, the
/// content scales with the window, and the window keeps the content's proportions.
public struct CompareView: View {
    let model: CompareViewModel
    let themes: ThemePair
    @Environment(\.colorScheme) private var colorScheme
    private var theme: Theme { themes.theme(for: colorScheme) }
    @State private var isHovered = false
    /// The content's size at scale 1, with the widest times (see `measuring`).
    @State private var naturalSize: CGSize = .zero
    /// Height of the hidden title bar's strip (the top safe area).
    @State private var topInset: CGFloat = 0

    public init(model: CompareViewModel, themes: ThemePair) {
        self.model = model
        self.themes = themes
    }

    public var body: some View {
        // An invisible copy at scale 1 gives the window its natural size; the visible copy
        // scales up with the window.
        content(scale: 1, measuring: true)
            .fixedSize()
            .frame(minWidth: 600)
            .hidden()
            .disabled(true)
            .accessibilityHidden(true)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { naturalSize = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GeometryReader { proxy in
                    content(scale: scale(toFill: proxy.size), measuring: false)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .foregroundStyle(theme.text)
            .overlay(alignment: .top) { topStrip }
            .background(theme.background.ignoresSafeArea())
            .overlay { HoverEdge(color: theme.accent, isVisible: isHovered) }
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
            }
            #if os(macOS)
            // Clicking the background ends typing a time (AppKit doesn't take focus from a text
            // field for a click on empty space); `EditableTime` then keeps or drops what was typed.
            .onTapGesture { NSApp.keyWindow?.makeFirstResponder(nil) }
            // Dragging the background moves the window; the strip, times and buttons keep their own clicks.
            .gesture(WindowDragGesture())
            .allowsWindowActivationEvents(true)
            #endif
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
            #if os(macOS)
            .background(WindowAspectRatio(ratio: CGSize(width: naturalSize.width, height: naturalSize.height + topInset)))
            #endif
            .onAppear { model.start() }
            .onDisappear { model.stop() }
    }

    /// How much larger than natural the content can be in `size`, keeping its proportions.
    /// Never smaller than 1.
    private func scale(toFill size: CGSize) -> CGFloat {
        guard naturalSize.width > 0, naturalSize.height > 0 else { return 1 }
        return max(1, min(size.width / naturalSize.width, size.height / naturalSize.height))
    }

    /// - Parameter measuring: lay out the widest the content gets as time passes (two-digit
    ///   hours, B's date with a day relation), so the window's natural size, and with it the
    ///   scale, doesn't change while scrubbing.
    private func content(scale s: CGFloat, measuring: Bool) -> some View {
        VStack(spacing: 18 * s) {
            HStack(alignment: .center, spacing: 12 * s) {
                side(model.a, zone: model.zoneA, date: model.a.dateText, name: "First time zone",
                     scale: s, measuring: measuring, select: model.selectA, type: model.typeTimeA)
                difference(scale: s)
                side(model.b, zone: model.zoneB,
                     date: measuring ? "\(model.b.dateText) · previous day" : model.zoneBDateText,
                     name: "Second time zone", scale: s, measuring: measuring,
                     select: model.selectB, type: model.typeTimeB)
            }
            TimeStrip(
                minuteOfDay: model.scrubberMinuteOfDay, marks: model.scrubberMarks, theme: theme,
                label: "Time in \(model.a.cityText)", value: model.a.timeText, scale: s
            ) { model.scrub(toMinuteOfDay: $0) }
        }
        .padding(.horizontal, 28 * s)
        .padding(.top, 8 * s)
        .padding(.bottom, 16 * s)
    }

    private func side(_ display: ZoneDisplay, zone: Zone, date: String, name: String, scale s: CGFloat,
                      measuring: Bool, select: @escaping (Zone) -> Void,
                      type: @escaping (String) -> Bool) -> some View {
        VStack(spacing: 2 * s) {
            ZoneButton(zone: zone, now: model.instant, accessibilityName: name, theme: theme, scale: s,
                       onSelect: select)
            EditableTime(time: measuring ? TimeStyle.widestTime(display.time) : display.time,
                         label: "Time in \(display.cityText)", theme: theme, scale: s, onCommit: type)
            Text(date).font(.system(size: 12 * s)).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    /// B's difference from A (accent) above the swap button. 15 pt is macOS's title3 size.
    private func difference(scale s: CGFloat) -> some View {
        VStack(spacing: 6 * s) {
            Text(model.differenceText)
                .font(.system(size: 15 * s, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(theme.accent)
            SwapButton(theme: theme, scale: s) { model.swap() }
        }
        .fixedSize()
        .accessibilityElement(children: .contain)
    }

    /// "Now", right-aligned in the title bar's strip, only while scrubbed. Like the Clock's city,
    /// it stays the same size when the window grows.
    private var topStrip: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                if !model.isLive { NowButton(theme: theme) { model.returnToNow() } }
            }
            .padding(.trailing, 12)
            .frame(height: proxy.safeAreaInsets.top)
            // A little below the strip's center (asked for by the user in M6).
            .offset(y: 3 - proxy.safeAreaInsets.top)
        }
    }
}

/// The accent swap arrows; a circle behind them on hover, like the city button's pill. The
/// circle and the click area reach past the arrows without changing the layout.
private struct SwapButton: View {
    let theme: Theme
    let scale: CGFloat
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 15 * scale))
                .foregroundStyle(theme.accent)
                .background(Circle().inset(by: -6 * scale).fill(theme.accent.opacity(isHovered ? 0.15 : 0)))
                .contentShape(Circle().inset(by: -6 * scale))
                .onHover { hovering in
                    withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
                }
        }
        .buttonStyle(.plain)
        .help("Swap time zones")
        .accessibilityLabel("Swap time zones")
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
