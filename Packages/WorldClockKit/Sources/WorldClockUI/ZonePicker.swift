import SwiftUI
import WorldClockCore

/// A search field over every zone and the matching results. Picking a row calls `onSelect`;
/// Return picks the first result.
public struct ZonePicker: View {
    @Bindable var model: ZonePickerViewModel
    let selected: Zone?
    let onSelect: (Zone) -> Void

    public init(model: ZonePickerViewModel, selected: Zone?, onSelect: @escaping (Zone) -> Void) {
        self.model = model
        self.selected = selected
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 0) {
            TextField("Search", text: $model.query, prompt: Text("City, region, or abbreviation"))
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Search time zones")
                .onSubmit {
                    if let first = model.rows.first { onSelect(first.zone) }
                }
                .padding(10)
            Divider()
            if model.rows.isEmpty {
                Text("No matching time zones")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.rows) { row in
                    ZonePickerRow(row: row, isSelected: row.zone == selected) { onSelect(row.zone) }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 300, height: 380)
    }
}

/// One result: city, then region and offset; a checkmark marks the current zone.
struct ZonePickerRow: View {
    let row: ZonePickerViewModel.Row
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(row.city)
                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(row.city), \(row.detail)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
