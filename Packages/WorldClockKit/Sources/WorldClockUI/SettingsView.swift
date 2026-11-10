import SwiftUI
import WorldClockCore

/// The Settings window (⌘,): 12/24-hour time, open at login, and the theme as a grid of
/// swatches. Drawn in the system's look, like other Mac apps' settings, not in the theme.
public struct SettingsView: View {
    @Bindable var model: SettingsViewModel

    public init(model: SettingsViewModel) {
        self.model = model
    }

    public var body: some View {
        Form {
            Picker("Time", selection: $model.timeFormat) {
                Text("System").tag(TimeFormat.system)
                Text("12-hour").tag(TimeFormat.twelveHour)
                Text("24-hour").tag(TimeFormat.twentyFourHour)
            }
            .pickerStyle(.segmented)
            Toggle("Open at login", isOn: $model.launchesAtLogin)
            Section("Theme") {
                ThemeGrid(selection: $model.theme)
                    .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
        // System Settings → General → Login Items can change it while the window is closed.
        .onAppear { model.refreshLoginItem() }
    }
}

/// Every theme as a swatch; the chosen one has a ring and a checkmark (not color alone).
struct ThemeGrid: View {
    @Binding var selection: Theme

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(ThemeSwatch.width), spacing: 12), count: 4), spacing: 12) {
            ForEach(Theme.all) { theme in
                Button { selection = theme } label: {
                    ThemeSwatch(theme: theme, isSelected: theme == selection)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.name)
                .accessibilityAddTraits(theme == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }
}

/// A theme in miniature: its background, a time in its text color and a dot of its accent.
struct ThemeSwatch: View {
    static let width: CGFloat = 92
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.background)
                .overlay(Text("9:41").font(TimeStyle.timeFont(size: 20)).foregroundStyle(theme.text))
                .overlay(alignment: .bottomTrailing) {
                    Circle().fill(theme.accent).frame(width: 8, height: 8).padding(6)
                }
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.primary.opacity(0.15)))
                .frame(height: 54)
                .padding(3)
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2))
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(.white, Color.accentColor)
                            .offset(x: 5, y: -5)
                    }
                }
            Text(theme.name)
                .font(.system(size: 11))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: Self.width)
        .contentShape(Rectangle())
    }
}
