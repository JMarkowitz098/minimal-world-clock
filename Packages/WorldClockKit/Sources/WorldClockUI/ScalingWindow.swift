import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// How a window's content is being drawn.
struct WindowLayout {
    /// Size relative to natural (1 at the window's natural size, larger as it grows).
    let scale: CGFloat
    /// Whether this is the invisible copy that measures the natural size. Content that changes
    /// width over time (Compare's times and dates) lays out its widest form here, so the
    /// natural size, and with it the scale, stays put.
    let measuring: Bool
    /// Whether the pointer is over the window.
    let isHovered: Bool

    /// How much larger than `natural` content can be drawn in `size`, keeping its proportions
    /// (whichever of width or height runs out first). Never below 1, and 1 until measured.
    static func scale(fitting natural: CGSize, in size: CGSize) -> CGFloat {
        guard natural.width > 0, natural.height > 0 else { return 1 }
        return max(1, min(size.width / natural.width, size.height / natural.height))
    }
}

/// The frame shared by the Clock and Compare windows: no title bar, theme colors (from
/// `\.theme`), content that scales with the window while the window keeps its proportions,
/// a thin accent edge while hovered, dragging the background to move the window, and a top
/// strip (beside the window buttons) for controls that keep their size.
///
/// macOS sizes a hidden-title-bar window as content + title bar, with the title bar as a top
/// safe area. So the content respects the safe area; only the background and the strip extend
/// into it. Snapshots simulate the strip with `safeAreaPadding(.top, 28)`.
struct ScalingWindow<Content: View, Strip: View>: View {
    /// The narrowest the natural size may be (room for the strip's controls).
    let minWidth: CGFloat
    /// Moves the strip's controls down from the strip's center.
    var stripNudge: CGFloat = 0
    /// What VoiceOver calls the window's content ("Clock"); the audit flags it unnamed.
    let accessibilityName: String
    @ViewBuilder let content: (WindowLayout) -> Content
    /// Right-aligned in the top strip.
    @ViewBuilder let strip: () -> Strip

    @Environment(\.theme) private var theme
    /// The content's size at scale 1.
    @State private var naturalSize: CGSize = .zero
    /// Height of the hidden title bar's strip (the top safe area).
    @State private var topInset: CGFloat = 0
    @State private var isHovered = false

    var body: some View {
        // An invisible copy at scale 1 gives the window its natural size; the visible copy
        // scales up with the window (the text would otherwise stop growing).
        content(WindowLayout(scale: 1, measuring: true, isHovered: false))
            .fixedSize()
            .frame(minWidth: minWidth)
            .hidden()
            .disabled(true)
            .accessibilityHidden(true)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { naturalSize = $0 }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                GeometryReader { proxy in
                    let scale = WindowLayout.scale(fitting: naturalSize, in: proxy.size)
                    content(WindowLayout(scale: scale, measuring: false, isHovered: isHovered))
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .foregroundStyle(theme.text)
            .overlay(alignment: .top) { topStrip }
            .background(theme.background.ignoresSafeArea())
            .overlay { HoverEdge(isVisible: isHovered) }
            .trackingHover($isHovered)
            #if os(macOS)
            // Clicking the background ends typing a time (AppKit doesn't take focus from a text
            // field for a click on empty space); `EditableTime` then keeps or drops what was typed.
            .onTapGesture { NSApp.keyWindow?.makeFirstResponder(nil) }
            // Dragging the background moves the window, even before it's active (SwiftUI content
            // covers the window background, so the scene's background drag doesn't reach here).
            // Buttons, times and the strip keep their own clicks.
            .gesture(WindowDragGesture())
            .allowsWindowActivationEvents(true)
            #endif
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
            #if os(macOS)
            // The window keeps the content's proportions, so the content fills it at any size.
            .background(WindowAspectRatio(ratio: CGSize(width: naturalSize.width, height: naturalSize.height + topInset)))
            .background(WindowAccessibilityName(name: accessibilityName))
            #endif
    }

    /// The strip's controls, right-aligned, filling exactly the strip above the content.
    private var topStrip: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                strip()
            }
            .frame(height: proxy.safeAreaInsets.top)
            .offset(y: stripNudge - proxy.safeAreaInsets.top)
        }
    }
}
