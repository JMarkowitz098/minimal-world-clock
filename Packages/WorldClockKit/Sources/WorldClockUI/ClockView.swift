import SwiftUI
import WorldClockCore

/// The Clock window: the time and date centered, scaling with the window, and the city and
/// globe (the zone picker button) top-right in the title bar's strip, level with the
/// close/minimize buttons (no UTC offset: decided in M6). Hovering turns the time the accent
/// color. The window frame (theme, scaling, hover edge, drag to move) is `ScalingWindow`.
public struct ClockView: View {
    let model: ClockViewModel
    @Environment(\.theme) private var theme

    public init(model: ClockViewModel) {
        self.model = model
    }

    public var body: some View {
        ScalingWindow(minWidth: 240) { layout in
            timeAndDate(scale: layout.scale, isHovered: layout.isHovered)
        } strip: {
            // The button's hover pill adds 8 pt on each side.
            ZoneButton(zone: model.zone, now: model.now) { model.select($0) }
                .padding(.trailing, 6)
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func timeAndDate(scale: CGFloat, isHovered: Bool) -> some View {
        VStack(spacing: 2 * scale) {
            Text(TimeStyle.shrinkingDayPeriod(model.time, timeSize: TimeStyle.windowTimeSize * scale))
                .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize * scale))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(isHovered ? theme.accent : theme.text)
            Text(model.dateText)
                .font(.system(size: TimeStyle.dateSize * scale))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(model.timeText), \(model.dateText)")
        .padding(.horizontal, 16 * scale)
        .padding(.top, 2 * scale)
        .padding(.bottom, 20 * scale)
    }
}
