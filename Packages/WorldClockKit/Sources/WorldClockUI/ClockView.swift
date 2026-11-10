import SwiftUI
import WorldClockCore

/// The Clock window, laid out for a window without a title bar: the city and globe (the zone
/// picker button) sit top-right in the title bar's strip, level with the close/minimize
/// buttons; the time and date are centered below (no UTC offset: decided in M6). Colors come from `theme`.
///
/// macOS sizes a hidden-title-bar window as content + title bar, with the title bar as a top
/// safe area. So the time and date respect the safe area, and only the background and the
/// top strip extend into it (`ignoresSafeArea`). Snapshots simulate the strip with
/// `safeAreaPadding(.top, 28)`.
public struct ClockView: View {
    let model: ClockViewModel
    let theme: Theme

    public init(model: ClockViewModel, theme: Theme) {
        self.model = model
        self.theme = theme
    }

    /// The window's natural content size (time and date at their normal size).
    @State private var naturalSize: CGSize = .zero
    /// Height of the hidden title bar's strip (the top safe area).
    @State private var topInset: CGFloat = 0

    public var body: some View {
        // An invisible copy at the normal size gives the window its natural size; the visible
        // copy scales up with the window (the text would otherwise stop growing).
        timeAndDate(scale: 1)
            .hidden()
            // Room for the window buttons and the city in the top strip.
            .frame(minWidth: 240)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { naturalSize = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GeometryReader { proxy in
                    timeAndDate(scale: scale(toFill: proxy.size))
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .foregroundStyle(theme.text)
            .overlay(alignment: .top) { topStrip }
            .background(theme.background.ignoresSafeArea())
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
            #if os(macOS)
            // The window keeps the content's proportions, so the time fills it at any size.
            .background(WindowAspectRatio(ratio: CGSize(width: naturalSize.width, height: naturalSize.height + topInset)))
            #endif
            .onAppear { model.start() }
            .onDisappear { model.stop() }
    }

    /// How much larger than natural the time and date can be in `size`, keeping their
    /// proportions (whichever of width or height runs out first). Never smaller than 1.
    private func scale(toFill size: CGSize) -> CGFloat {
        guard naturalSize.width > 0, naturalSize.height > 0 else { return 1 }
        return max(1, min(size.width / naturalSize.width, size.height / naturalSize.height))
    }

    private func timeAndDate(scale: CGFloat) -> some View {
        VStack(spacing: 2 * scale) {
            Text(TimeStyle.shrinkingDayPeriod(model.time, timeSize: TimeStyle.windowTimeSize * scale))
                .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize * scale))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(model.dateText)
                .font(.system(size: 12 * scale))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(model.timeText), \(model.dateText)")
        .padding(.horizontal, 16 * scale)
        .padding(.top, 2 * scale)
        .padding(.bottom, 20 * scale)
    }

    /// The city and globe, right-aligned in the title bar's strip.
    private var topStrip: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                ZoneButton(zone: model.zone, now: model.now, style: .cityWithGlobe) { model.select($0) }
                    .foregroundStyle(theme.accent)
            }
            .padding(.trailing, 14)
            // Fill exactly the strip above the content: the top safe area.
            .frame(height: proxy.safeAreaInsets.top)
            .offset(y: -proxy.safeAreaInsets.top)
        }
    }
}
