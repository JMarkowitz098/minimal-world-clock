import SwiftUI
import WorldClockCore
import WorldClockUI

// M6 design exploration for the Compare window, in the approved Clock window's look (no title
// bar, Solarized colors, accent city + globe buttons). Mock windows, scrubbed to 3 PM in New
// York (5 AM next day in Tokyo; live time is 7 AM in New York) so every element shows. Not app
// code: the chosen variant moves into WorldClockUI. Round 1 kept B, D and G (dropped: a
// chevron-city port of M4's layout, split halves, both cities' hours on the strip, stacked rows).

/// One Compare design: how the middle, the scrubber and "Now" are drawn.
struct CompareVariant {
    enum Middle {
        /// "+14 h" / swap / "Next day" stacked.
        case stacked
        /// Only "+14 h" (accent) and swap; "next day" joins B's date.
        case inlineDay
    }

    enum Scrubber {
        /// The system slider (ignores the theme's tint on macOS).
        case system
        /// A drawn 24-hour track with accent fill and thumb.
        case strip(hourTicks: Bool, nowMarker: Bool, ringThumb: Bool)
    }

    enum NowPlacement {
        /// A pill in the top strip, right side, only while scrubbed.
        case topStrip
        /// Text at the scrubber's right end, only while scrubbed.
        case scrubberEnd
    }

    let caption: String
    var middle: Middle
    var scrubber: Scrubber
    var now: NowPlacement = .topStrip
}

extension CompareVariant {
    static let round2: [CompareVariant] = [
        CompareVariant(caption: "B · Stacked middle, system slider", middle: .stacked, scrubber: .system),
        CompareVariant(caption: "D · Stacked middle, 24-hour strip", middle: .stacked,
                       scrubber: .strip(hourTicks: true, nowMarker: false, ringThumb: false)),
        CompareVariant(caption: "G · Day in Tokyo's date, system slider", middle: .inlineDay, scrubber: .system),
        CompareVariant(caption: "H · G + D's strip", middle: .inlineDay,
                       scrubber: .strip(hourTicks: true, nowMarker: false, ringThumb: false)),
        CompareVariant(caption: "I · H, ticks every 6 h only, marker at the live time (7 AM)", middle: .inlineDay,
                       scrubber: .strip(hourTicks: false, nowMarker: true, ringThumb: false)),
        CompareVariant(caption: "J · I with a ringed thumb; Now at the strip's end", middle: .inlineDay,
                       scrubber: .strip(hourTicks: false, nowMarker: true, ringThumb: true), now: .scrubberEnd),
    ]
}

/// The close, minimize and zoom buttons, as a window without a title bar shows them.
struct TrafficLights: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34))
            Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18))
            Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25))
        }
        .frame(width: 52, height: 12)
    }
}

struct CompareOption: View {
    let variant: CompareVariant
    let model = compareModel("America/New_York", "Asia/Tokyo", scrubTo: 15 * 60)
    @Environment(\.colorScheme) private var scheme
    private var theme: Theme { ThemePair.solarized.theme(for: scheme) }
    private let span = CGFloat(24 * 60 - 15)
    private var fraction: CGFloat { CGFloat(model.scrubberMinuteOfDay) / span }
    /// The live time (jan15Noon) on New York's clock: 7 AM.
    private var liveFraction: CGFloat { 7 * 60 / span }

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                side(model.a, date: model.a.dateText)
                middle
                side(model.b, date: variant.middle == .inlineDay
                     ? "\(model.b.dateText) · \(model.dayRelationText.lowercased())" : model.b.dateText)
            }
            HStack(spacing: 12) {
                scrubber
                if variant.now == .scrubberEnd { nowText }
            }
        }
        .padding(.horizontal, 28).padding(.top, 28)
        .foregroundStyle(theme.text)
        .frame(width: 620, height: 250)
        .background(theme.background)
        .overlay(alignment: .topLeading) { TrafficLights().padding(.leading, 12).padding(.top, 8) }
        .overlay(alignment: .topTrailing) {
            if variant.now == .topStrip { nowPill.padding(.trailing, 12).padding(.top, 4) }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.black.opacity(0.15)))
    }

    private func side(_ d: ZoneDisplay, date: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Text(d.cityText).font(.headline)
                Image(systemName: "globe").font(.callout)
            }
            .foregroundStyle(theme.accent)
            Text(TimeStyle.shrinkingDayPeriod(d.time, timeSize: TimeStyle.windowTimeSize))
                .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
                .monospacedDigit().lineLimit(1)
            Text(date).font(.system(size: 12))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var middle: some View {
        let swap = Image(systemName: "arrow.left.arrow.right").font(.title3).foregroundStyle(theme.accent)
        switch variant.middle {
        case .stacked:
            VStack(spacing: 6) {
                Text(model.differenceText).font(.headline).monospacedDigit()
                swap
                Text(model.dayRelationText).font(.callout).opacity(0.8)
            }
            .fixedSize()
        case .inlineDay:
            VStack(spacing: 6) {
                Text(model.differenceText).font(.title3.weight(.medium)).monospacedDigit().foregroundStyle(theme.accent)
                swap
            }
            .fixedSize()
        }
    }

    private var nowPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.uturn.backward").font(.caption.weight(.semibold))
            Text("Now").font(.headline)
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(theme.accent.opacity(0.15), in: Capsule())
    }

    private var nowText: some View {
        Text("Now").font(.callout.weight(.semibold)).foregroundStyle(theme.accent)
            .padding(.horizontal, 8).padding(.vertical, 2)
            .background(theme.accent.opacity(0.15), in: Capsule())
            .padding(.bottom, 18)
    }

    @ViewBuilder private var scrubber: some View {
        switch variant.scrubber {
        case .system:
            Slider(value: .constant(Double(model.scrubberMinuteOfDay)), in: 0...Double(span))
                .tint(theme.accent)
                .overlay(alignment: .top) { systemMarks }
                .padding(.bottom, 18)
        case let .strip(hourTicks, nowMarker, ringThumb):
            strip(hourTicks: hourTicks, nowMarker: nowMarker, ringThumb: ringThumb)
        }
    }

    private var systemMarks: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 10
            let track = proxy.size.width - 2 * inset
            ForEach(model.scrubberMarks, id: \.minuteOfDay) { mark in
                Text(mark.label).font(.caption).monospacedDigit().opacity(0.75).fixedSize()
                    .position(x: inset + track * CGFloat(mark.minuteOfDay) / span, y: 30)
            }
        }
    }

    private func strip(hourTicks: Bool, nowMarker: Bool, ringThumb: Bool) -> some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let y: CGFloat = 12
            ZStack(alignment: .topLeading) {
                ForEach(0..<25) { h in
                    if hourTicks || h % 6 == 0 {
                        Rectangle().fill(theme.text.opacity(h % 6 == 0 ? 0.5 : 0.25))
                            .frame(width: 1, height: h % 6 == 0 ? 10 : 6)
                            .position(x: w * CGFloat(h) / 24, y: y)
                    }
                }
                Capsule().fill(theme.text.opacity(0.15)).frame(width: w, height: 3).position(x: w / 2, y: y)
                Capsule().fill(theme.accent).frame(width: w * fraction, height: 3).position(x: w * fraction / 2, y: y)
                if nowMarker {
                    Circle().strokeBorder(theme.accent, lineWidth: 1.5)
                        .background(Circle().fill(theme.background))
                        .frame(width: 8, height: 8)
                        .position(x: w * liveFraction, y: y)
                }
                if ringThumb {
                    Circle().fill(theme.accent).frame(width: 12, height: 12)
                        .padding(3).background(Circle().fill(theme.background))
                        .overlay(Circle().strokeBorder(theme.accent.opacity(0.4)))
                        .position(x: w * fraction, y: y)
                } else {
                    Circle().fill(theme.accent).frame(width: 14, height: 14).position(x: w * fraction, y: y)
                }
                ForEach(Array(model.scrubberMarks.enumerated()), id: \.offset) { i, mark in
                    Text(mark.label).font(.caption).monospacedDigit().opacity(0.75).fixedSize()
                        .position(x: w * CGFloat(i) / 4, y: y + 18)
                }
            }
        }
        .frame(height: 40)
    }
}

@MainActor let compareOptionSnapshots: [Snapshot] = [
    Snapshot(name: "compare-options", size: CGSize(width: 1312, height: 940)) {
        let variants = CompareVariant.round2
        return AnyView(
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(stride(from: 0, to: variants.count, by: 2)), id: \.self) { r in
                    HStack(alignment: .top, spacing: 24) {
                        ForEach(r..<min(r + 2, variants.count), id: \.self) { i in
                            VStack(alignment: .leading, spacing: 8) {
                                CompareOption(variant: variants[i])
                                Text(variants[i].caption).font(.callout.weight(.medium))
                            }
                        }
                    }
                }
            }
            .padding(24)
        )
    },
]
