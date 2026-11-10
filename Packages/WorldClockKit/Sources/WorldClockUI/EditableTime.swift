import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// A large time the user can click to type a different one (Compare window). Hovering shows that
/// it's editable: a soft accent background and the text cursor. Return commits, Esc or clicking
/// elsewhere cancels; a time that can't be read beeps and keeps the field open.
struct EditableTime: View {
    let time: AttributedString
    /// What VoiceOver calls it: "Time in Tokyo".
    let label: String
    let theme: Theme
    /// Called with the typed text; returns whether it was a time.
    let onCommit: (String) -> Bool

    /// The text being typed; `nil` when not editing.
    @State private var draft: String?
    @State private var isHovered = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if let draft {
                // The field draws AM/PM full size, so it's sized by a hidden copy of the typed
                // text (plus room for the cursor) rather than by the shown time.
                Text(draft.isEmpty ? " " : draft)
                    .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.trailing, 8)
                    .hidden()
                    .overlay { field }
            } else {
                Text(TimeStyle.shrinkingDayPeriod(time, timeSize: TimeStyle.windowTimeSize))
                    .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(.horizontal, 10)
        .background(theme.accent.opacity(isHovered || draft != nil ? 0.12 : 0), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { begin() }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { isHovered = hovering }
        }
        #if os(macOS)
        .pointerStyle(.horizontalText)
        #endif
        .help("Click to type a time")
        .accessibilityElement(children: draft == nil ? .ignore : .contain)
        .accessibilityLabel(label)
        .accessibilityValue(String(time.characters))
        .accessibilityHint("Type a different time")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { begin() }
    }

    private var field: some View {
        TextField(label, text: Binding(get: { draft ?? "" }, set: { draft = $0 }))
            .labelsHidden()
            .textFieldStyle(.plain)
            .font(TimeStyle.timeFont(size: TimeStyle.windowTimeSize))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .tint(theme.accent)
            .focused($isFocused)
            .onSubmit(commit)
            #if os(macOS)
            .onExitCommand { draft = nil }
            #endif
            .onChange(of: isFocused) { _, focused in
                if !focused { draft = nil }
            }
            // Focusing in the same pass the field appears marks it focused without making it
            // the first responder (keys went nowhere until a second click); a beat later works.
            .onAppear { DispatchQueue.main.async { isFocused = true } }
    }

    private func begin() {
        guard draft == nil else { return }
        draft = String(time.characters)
    }

    private func commit() {
        guard let draft else { return }
        if onCommit(draft) {
            self.draft = nil
        } else {
            #if canImport(AppKit)
            NSSound.beep()
            #endif
        }
    }
}
