import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

/// A large time the user can click to type a different one (Compare window). Hovering shows that
/// it's editable: a soft accent background and the text cursor. Return commits (a time that
/// can't be read beeps and keeps the field open); Esc cancels; clicking elsewhere commits if it's
/// a time and otherwise goes back to the shown time. Keyboard: Tab reaches it (an accent ring
/// shows), Return or Space starts typing, and focus comes back to it after Return or Esc.
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
    /// Keyboard focus on the shown time (not the field).
    @FocusState private var timeFocused: Bool
    /// Set by Return and Esc: focus goes back to the time once the field is gone.
    @State private var refocusWhenClosed = false
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
        .background(theme.accent.opacity(isHovered || draft != nil ? Theme.hoverFill : 0), in: RoundedRectangle(cornerRadius: 10 * scale))
        .overlay {
            // Keyboard focus: a solid accent ring (the system's ignores the theme); solid so it
            // reaches 3:1, like the strip's thumb.
            RoundedRectangle(cornerRadius: 10 * scale)
                .strokeBorder(timeFocused ? theme.accent : .clear, lineWidth: 2 * scale)
        }
        .contentShape(RoundedRectangle(cornerRadius: 10 * scale))
        .onTapGesture { begin() }
        .focusable(draft == nil)
        .focused($timeFocused)
        .focusEffectDisabled()
        // Only while the time is shown: these also see every key typed into the field (it's
        // inside this view), and handling them there swallowed Return (no commit) and spaces.
        .onKeyPress(.return) { startTypingFromKeyboard() }
        .onKeyPress(.space) { startTypingFromKeyboard() }
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
            .onExitCommand {
                refocusWhenClosed = true
                draft = nil
            }
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
            // After Return or Esc, keyboard focus goes back to the time (it was in the field),
            // so Tab carries on from here. Only once the field is gone: refocusing right after
            // a commit lost the focus (the commit re-renders the window while AppKit is still
            // ending the edit), and keys went nowhere.
            .onDisappear {
                guard refocusWhenClosed else { return }
                refocusWhenClosed = false
                DispatchQueue.main.async { timeFocused = true }
            }
    }

    private func startTypingFromKeyboard() -> KeyPress.Result {
        guard draft == nil else { return .ignored }
        begin()
        return .handled
    }

    private func begin() {
        guard draft == nil else { return }
        draft = String(time.characters)
    }

    private func commit() {
        guard let draft else { return }
        if onCommit(draft) {
            refocusWhenClosed = true
            self.draft = nil
        } else {
            #if canImport(AppKit)
            NSSound.beep()
            #endif
        }
    }
}
