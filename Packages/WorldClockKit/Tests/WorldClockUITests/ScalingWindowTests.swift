import CoreGraphics
import Testing
@testable import WorldClockUI

// How much the Clock and Compare windows scale their content as the window grows.

@Test func scaleIsOneAtTheNaturalSize() {
    #expect(WindowLayout.scale(fitting: CGSize(width: 300, height: 100), in: CGSize(width: 300, height: 100)) == 1)
}

@Test func scaleFollowsWhicheverSideRunsOutFirst() {
    // Twice as wide but only 1.5 times as tall: the height limits it.
    #expect(WindowLayout.scale(fitting: CGSize(width: 300, height: 100), in: CGSize(width: 600, height: 150)) == 1.5)
}

@Test func scaleNeverShrinksBelowOne() {
    #expect(WindowLayout.scale(fitting: CGSize(width: 300, height: 100), in: CGSize(width: 150, height: 50)) == 1)
}

@Test func scaleIsOneBeforeMeasuring() {
    #expect(WindowLayout.scale(fitting: .zero, in: CGSize(width: 600, height: 200)) == 1)
}
