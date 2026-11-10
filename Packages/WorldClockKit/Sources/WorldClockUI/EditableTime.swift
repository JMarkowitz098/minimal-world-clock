import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// A large time the user can click to type a different one (Compare window). Hovering shows that
/// it's editable: a soft accent background and the text cursor. Return commits (a time that
/// can't be read beeps and keeps the field open); Esc cancels; clicking elsewhere commits if it's
/// a time and otherwise goes back to the shown time.
struct EditableTime: View {
    let time: AttributedString
    /// What VoiceOver calls it: "Time in Tokyo".
    let label: String
    /// Size relative to normal (Compare scales with its window).
    var scale: CGFloat = 1
    /// Called with the typed text; returns whether it was a time.
    let onCommit: (String) -> Bool

    /// The text being typed; `nil` when not editing.
    @Environment(\.theme) private var theme
    @State private var draft: String?
    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    private var size: CGFloat { TimeStyle.windowTimeSize * scale }

    /// The typed text's size. A text field can't draw AM/PM smaller, so the whole entry is a
    /// bit smaller than the time instead; at full size it looked much bigger (user, M6).
    private var editSize: CGFloat { size * 0.8 }

    var body: some View {
        Group {
            if let draft {
                // Keeps the shown time's height (so the date doesn't move) and grows only as
                // wide as the typed text needs, plus room for the cursor.
                ZStack {
                    shownTime.hidden()
                    Text(draft.isEmpty ? " " : draft)
                        .font(TimeStyle.timeFont(size: editSize))
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.trailing, 6 * scale)
                        .hidden()
                }
                .overlay { field }
            } else {
                shownTime
            }
        }
        .padding(.horizontal, 10 * scale)
        .background(theme.accent.opacity(isHovered || draft != nil ? 0.12 : 0), in: RoundedRectangle(cornerRadius: 10 * scale))
        .contentShape(RoundedRectangle(cornerRadius: 10 * scale))
        .onTapGesture { begin() }
        .trackingHover($isHovered)
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

    private var shownTime: some View {
        Text(TimeStyle.shrinkingDayPeriod(time, timeSize: size))
            .font(TimeStyle.timeFont(size: size))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var field: some View {
        TextField(label, text: Binding(get: { draft ?? "" }, set: { draft = $0 }))
            .labelsHidden()
            .textFieldStyle(.plain)
            .font(TimeStyle.timeFont(size: editSize))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .tint(theme.accent)
            .focused($isFocused)
            .onSubmit(commit)
            #if os(macOS)
            .onExitCommand { draft = nil }
            #endif
            .onChange(of: isFocused) { _, focused in
                // Clicked elsewhere: keep a typed time, quietly drop anything else. (After Return
                // or Esc, `draft` is already nil.)
                if !focused, let typed = draft {
                    _ = onCommit(typed)
                    draft = nil
                }
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
