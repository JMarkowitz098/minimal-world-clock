import Foundation
import Testing
@testable import WorldClockCore

// MARK: Instant → wall time

@Test func wallTimeInZone() {
    #expect(zone("Asia/Tokyo").wallTime(at: jan15Noon) == wall(2026, 1, 15, 21, 0))
    #expect(zone("America/New_York").wallTime(at: jan15Noon) == wall(2026, 1, 15, 7, 0))
    #expect(zone("America/New_York").wallTime(at: jul15Noon) == wall(2026, 7, 15, 8, 0))
    #expect(zone("Asia/Calcutta").wallTime(at: jan15Noon) == wall(2026, 1, 15, 17, 30))
}

@Test func wallTimeKeepsSeconds() {
    let instant = jan15Noon.addingTimeInterval(42)
    #expect(zone("UTC").wallTime(at: instant) == WallTime(year: 2026, month: 1, day: 15, hour: 12, minute: 0, second: 42))
}

// MARK: Wall time → instant

@Test func instantFromWallTime() {
    #expect(zone("Asia/Tokyo").instant(for: wall(2026, 1, 15, 21, 0)) == jan15Noon)
    #expect(zone("America/New_York").instant(for: wall(2026, 7, 15, 8, 0)) == jul15Noon)
    #expect(zone("Asia/Kathmandu").instant(for: wall(2026, 1, 15, 17, 45)) == jan15Noon)
}

@Test func dstGapMovesForward() {
    // New York skips 02:00–03:00 on March 8, 2026: 02:30 doesn't exist and becomes 03:30 EDT.
    let newYork = zone("America/New_York")
    let instant = newYork.instant(for: wall(2026, 3, 8, 2, 30))
    #expect(instant == utc(2026, 3, 8, 7, 30))
    #expect(newYork.wallTime(at: instant) == wall(2026, 3, 8, 3, 30))
}

@Test func dstGapMovesForwardInLondon() {
    // London skips 01:00–02:00 on March 29, 2026: 01:30 becomes 02:30 BST.
    let instant = zone("Europe/London").instant(for: wall(2026, 3, 29, 1, 30))
    #expect(instant == utc(2026, 3, 29, 1, 30))
}

@Test func dstOverlapPicksFirst() {
    // New York repeats 01:00–02:00 on November 1, 2026: 01:30 happens first in EDT (UTC−4).
    #expect(zone("America/New_York").instant(for: wall(2026, 11, 1, 1, 30)) == utc(2026, 11, 1, 5, 30))
    // London repeats 01:00–02:00 on October 25, 2026: 01:30 happens first in BST (UTC+1).
    #expect(zone("Europe/London").instant(for: wall(2026, 10, 25, 1, 30)) == utc(2026, 10, 25, 0, 30))
}

@Test func skippedDayMovesForward() {
    // Samoa jumped across the date line in 2011 and skipped December 30 entirely.
    let apia = zone("Pacific/Apia")
    let instant = apia.instant(for: wall(2011, 12, 30, 12, 0))
    #expect(apia.wallTime(at: instant) == wall(2011, 12, 31, 12, 0))
}
