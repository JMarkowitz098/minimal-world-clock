import SwiftUI

/// The desktop widget's container background: the theme's background with a thin border in the
/// text color along the widget's edge (chosen by the user in M6; not the accent, which means
/// hover in the windows). The border follows the widget's corners (`ContainerRelativeShape`).
public struct WidgetBackground: View {
    let themes: ThemePair
    @Environment(\.colorScheme) private var colorScheme

    public init(themes: ThemePair) {
        self.themes = themes
    }

    public var body: some View {
        let theme = themes.theme(for: colorScheme)
        theme.background
            .overlay { ContainerRelativeShape().strokeBorder(theme.text, lineWidth: 2) }
    }
}
