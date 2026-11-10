import SwiftUI
import WorldClockCore

/// Temporary content for the Clock window until M3 replaces it with `ClockView`.
public struct PlaceholderView: View {
    public init() {}

    public var body: some View {
        Text("Minimal World Clock")
            .font(.title)
            .padding(40)
    }
}
