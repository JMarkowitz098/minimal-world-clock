import SwiftUI

/// The desktop widget's container background: the theme's background with a thin border in the
/// text color, set in from the widget's edge (chosen by the user in M6; not the accent, which
/// means hover in the windows). macOS draws its own light line along the top and bottom edges of
/// every widget, so a border on the edge looked broken; inset, the gap reads as deliberate. The
/// border's corners stay concentric with the widget's (`ContainerRelativeShape`).
public struct WidgetBackground: View {
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        theme.background
            .overlay { ContainerRelativeShape().inset(by: 6).strokeBorder(theme.text, lineWidth: 1.5) }
    }
}
