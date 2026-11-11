import SwiftUI
import WorldClockCore

/// A search field over every zone and the matching results, favorites first in a section of
/// their own. Picking a row calls `onSelect`; ↓/↑ highlight a row and Return picks it (the
/// first result if none is highlighted); ⌘D stars the highlighted row. Drawn in `\.theme`: its
/// softer `surface` background (also set on the popover by `ZoneButton`) and text color, and
/// its accent for the search field's focus ring, the hovered row, the checkmark and the stars.
public struct ZonePicker: View {
    @Bindable var model: ZonePickerViewModel
    let selected: Place?
    let onSelect: (Place) -> Void
    @Environment(\.theme) private var theme
    @FocusState private var searchFocused: Bool

    public init(model: ZonePickerViewModel, selected: Place?, onSelect: @escaping (Place) -> Void) {
        self.model = model
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(10)
            Rectangle().fill(theme.line(0.12)).frame(height: 1)
            if model.rows.isEmpty {
                Text("No matching time zones")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { scroller in
                    List {
                        if model.favoriteCount > 0 {
                            Section { rows(model.rows[..<model.favoriteCount]) }
                        }
                        Section { rows(model.rows[model.favoriteCount...]) }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onChange(of: model.highlighted) { _, place in
                        if let place { scroller.scrollTo(place.id) }
                    }
                }
            }
        }
        .frame(width: 300, height: 380)
        .foregroundStyle(theme.text)
        .background(theme.surface)
    }

    /// Rows in one section. Starring a row only fills its star (`toggleFavorite` keeps the
    /// order), so a row never moves between sections under the pointer.
    private func rows(_ rows: ArraySlice<ZonePickerViewModel.Row>) -> some View {
        ForEach(rows) { row in
            ZonePickerRow(row: row, isSelected: row.place == selected, isHighlighted: row.place == model.highlighted,
                          onToggleFavorite: model.canFavorite ? { model.toggleFavorite(row.place) } : nil) {
                onSelect(row.place)
            }
            // The line under the last favorite is the divider between the sections: stronger.
            .listRowSeparatorTint(theme.line(row.id == lastFavorite ? 0.45 : 0.12))
            .listRowBackground(Color.clear)
        }
    }

    private var lastFavorite: String? {
        model.favoriteCount > 0 ? model.rows[model.favoriteCount - 1].id : nil
    }

    /// A plain field with its own focus ring: the system's follows the Mac's accent color, not
    /// the theme's.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.line(0.6))
                .accessibilityHidden(true)
            TextField("Search", text: $model.query, prompt: Text("City, country, or time zone"))
                .accessibilityLabel("Search time zones")
                .onSubmit {
                    if let choice = model.choice { onSelect(choice) }
                }
                // ↓/↑ move through the results without leaving the field (M8, keyboard use).
                .onKeyPress(.downArrow) { model.moveHighlight(by: 1); return .handled }
                .onKeyPress(.upArrow) { model.moveHighlight(by: -1); return .handled }
                // ⌘D stars the highlighted row (as in browsers' bookmarks): the keyboard's way to
                // what the star does on hover.
                .onKeyPress(characters: ["d"]) { press in
                    guard press.modifiers == .command, model.canFavorite, let place = model.highlighted else { return .ignored }
                    model.toggleFavorite(place)
                    return .handled
                }
                .textFieldStyle(.plain)
                .focused($searchFocused)
                // The text cursor in the accent (reports say macOS may ignore tint unless the
                // system accent color is Multicolor; checked with the user in M6).
                .tint(theme.accent)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(theme.line(0.07), in: RoundedRectangle(cornerRadius: 7))
        .overlay {
            RoundedRectangle(cornerRadius: 7)
                .strokeBorder(searchFocused ? theme.ring(0.7) : .clear, lineWidth: 2)
        }
    }
}

/// One result: city, then region and offset (or, for a city found inside a zone, the zone's
/// city and offset); an accent checkmark marks the current zone; a star toggles the favorite
/// (filled for a favorite, outlined while the pointer is over the row). An accent pill shows
/// behind the row while hovered; the row the arrow keys reach also gets a solid accent outline.
struct ZonePickerRow: View {
    let row: ZonePickerViewModel.Row
    let isSelected: Bool
    /// Reached with the arrow keys: drawn like a hovered row.
    let isHighlighted: Bool
    /// Nil when the picker has no favorites (no star).
    let onToggleFavorite: (() -> Void)?
    let action: () -> Void
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(row.city)
                        // Solid, not faded: faded text failed contrast on the softer themes (M8).
                        Text(row.detail)
                            .font(.caption)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(theme.accent)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(row.spokenLabel)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityActions {
                if let onToggleFavorite {
                    Button(row.isFavorite ? "Remove from Favorites" : "Add to Favorites", action: onToggleFavorite)
                }
            }
            if let onToggleFavorite {
                star(onToggleFavorite)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(theme.accent.opacity(isHovered || isHighlighted ? Theme.hoverFill : 0), in: RoundedRectangle(cornerRadius: 6))
        // The keyboard's row needs a clear outline, not just the faint hover fill (a focus
        // indicator: 3:1 against the surface, which `everyThemesAccentMeetsAA` checks).
        .overlay {
            RoundedRectangle(cornerRadius: 6).strokeBorder(isHighlighted ? theme.accent : .clear, lineWidth: 2)
        }
        // Instant, not faded (`trackingHover`): a fade lags when running the pointer down a list.
        .onHover { isHovered = $0 }
        .contextMenu {
            if let onToggleFavorite {
                Button(row.isFavorite ? "Remove from Favorites" : "Add to Favorites", action: onToggleFavorite)
            }
        }
    }

    /// Filled for a favorite; outlined on the hovered or highlighted row; otherwise empty space
    /// (kept, so the text doesn't shift). VoiceOver uses the row's action instead.
    private func star(_ toggle: @escaping () -> Void) -> some View {
        let shown = row.isFavorite || isHovered || isHighlighted
        return Button(action: toggle) {
            Image(systemName: row.isFavorite ? "star.fill" : "star")
                .foregroundStyle(theme.accent)
                .opacity(shown ? 1 : 0)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!shown)
        .help(row.isFavorite ? "Remove from Favorites" : "Add to Favorites")
        .accessibilityHidden(true)
    }
}
