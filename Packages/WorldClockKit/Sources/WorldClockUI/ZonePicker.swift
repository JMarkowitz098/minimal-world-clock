import SwiftUI
import WorldClockCore

/// A search field over every zone and the matching results. Picking a row calls `onSelect`;
/// Return picks the first result. With a `theme` it uses the theme's softer `surface`
/// background (set on the popover by `ZoneButton`) and text color, and its accent for the
/// search field's focus ring, the hovered row and the checkmark; without one, the system's look.
public struct ZonePicker: View {
    @Bindable var model: ZonePickerViewModel
    let selected: Zone?
    let theme: Theme?
    let onSelect: (Zone) -> Void
    @FocusState private var searchFocused: Bool

    public init(model: ZonePickerViewModel, selected: Zone?, theme: Theme? = nil, onSelect: @escaping (Zone) -> Void) {
        self.model = model
        self.selected = selected
        self.theme = theme
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(10)
            divider
            if model.rows.isEmpty {
                Text("No matching time zones")
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.rows) { row in
                    ZonePickerRow(row: row, isSelected: row.zone == selected, accent: theme?.accent) { onSelect(row.zone) }
                        .listRowSeparatorTint(theme.map { $0.text.opacity(0.12) })
                        .listRowBackground(theme == nil ? nil : Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(theme == nil ? .automatic : .hidden)
            }
        }
        .frame(width: 300, height: 380)
        .foregroundStyle(theme?.text ?? Color.primary)
        .background(theme?.surface ?? Color.clear)
    }

    @ViewBuilder private var searchField: some View {
        let field = TextField("Search", text: $model.query, prompt: Text("City, region, or abbreviation"))
            .accessibilityLabel("Search time zones")
            .onSubmit {
                if let first = model.rows.first { onSelect(first.zone) }
            }
        if let theme {
            // The system focus ring follows the Mac's accent color, so draw one in the theme's.
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .opacity(0.6)
                    .accessibilityHidden(true)
                field
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    // The text cursor in the accent (reports say macOS may ignore tint unless
                    // the system accent color is Multicolor; checked with the user in M6).
                    .tint(theme.accent)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(theme.text.opacity(0.07), in: RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .strokeBorder(theme.accent.opacity(searchFocused ? 0.7 : 0), lineWidth: 2)
            }
        } else {
            field.textFieldStyle(.roundedBorder)
        }
    }

    @ViewBuilder private var divider: some View {
        if let theme {
            Rectangle().fill(theme.text.opacity(0.12)).frame(height: 1)
        } else {
            Divider()
        }
    }
}

/// One result: city, then region and offset; a checkmark marks the current zone. With an
/// `accent`, the checkmark uses it and the row shows an accent pill while the pointer is over it.
struct ZonePickerRow: View {
    let row: ZonePickerViewModel.Row
    let isSelected: Bool
    let accent: Color?
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.city)
                    Text(row.detail)
                        .font(.caption)
                        .opacity(0.7)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(accent ?? Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, accent == nil ? 0 : 6)
            .padding(.vertical, accent == nil ? 0 : 2)
            .background((accent ?? .clear).opacity(isHovered ? 0.15 : 0), in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel("\(row.city), \(row.detail)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
