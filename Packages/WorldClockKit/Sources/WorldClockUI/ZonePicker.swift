import SwiftUI
import WorldClockCore

/// A search field over every zone and the matching results. Picking a row calls `onSelect`;
/// ↓/↑ highlight a row and Return picks it (the first result if none is highlighted). Drawn in `\.theme`: its softer `surface` background (also set
/// on the popover by `ZoneButton`) and text color, and its accent for the search field's focus
/// ring, the hovered row and the checkmark.
public struct ZonePicker: View {
    @Bindable var model: ZonePickerViewModel
    let selected: Zone?
    let onSelect: (Zone) -> Void
    @Environment(\.theme) private var theme
    @FocusState private var searchFocused: Bool

    public init(model: ZonePickerViewModel, selected: Zone?, onSelect: @escaping (Zone) -> Void) {
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
                    List(model.rows) { row in
                        ZonePickerRow(row: row, isSelected: row.zone == selected,
                                      isHighlighted: row.zone == model.highlighted) { onSelect(row.zone) }
                            .listRowSeparatorTint(theme.line(0.12))
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onChange(of: model.highlighted) { _, zone in
                        if let zone { scroller.scrollTo(zone.identifier) }
                    }
                }
            }
        }
        .frame(width: 300, height: 380)
        .foregroundStyle(theme.text)
        .background(theme.surface)
    }

    /// A plain field with its own focus ring: the system's follows the Mac's accent color, not
    /// the theme's.
    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(theme.line(0.6))
                .accessibilityHidden(true)
            TextField("Search", text: $model.query, prompt: Text("City, region, or abbreviation"))
                .accessibilityLabel("Search time zones")
                .onSubmit {
                    if let choice = model.choice { onSelect(choice) }
                }
                // ↓/↑ move through the results without leaving the field (M8, keyboard use).
                .onKeyPress(.downArrow) { model.moveHighlight(by: 1); return .handled }
                .onKeyPress(.upArrow) { model.moveHighlight(by: -1); return .handled }
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

/// One result: city, then region and offset; an accent checkmark marks the current zone, and an
/// accent pill shows behind the row while the pointer is over it; the row the arrow keys reach
/// also gets a solid accent outline.
struct ZonePickerRow: View {
    let row: ZonePickerViewModel.Row
    let isSelected: Bool
    /// Reached with the arrow keys: drawn like a hovered row.
    let isHighlighted: Bool
    let action: () -> Void
    @Environment(\.theme) private var theme
    @State private var isHovered = false

    var body: some View {
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
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(theme.accent.opacity(isHovered || isHighlighted ? Theme.hoverFill : 0), in: RoundedRectangle(cornerRadius: 6))
            // The keyboard's row needs a clear outline, not just the faint hover fill (a focus
            // indicator: 3:1 against the surface, which `everyThemesAccentMeetsAA` checks).
            .overlay {
                RoundedRectangle(cornerRadius: 6).strokeBorder(isHighlighted ? theme.accent : .clear, lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Instant, not faded (`trackingHover`): a fade lags when running the pointer down a list.
        .onHover { isHovered = $0 }
        .accessibilityLabel(row.spokenLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
