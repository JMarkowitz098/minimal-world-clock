import Foundation
import Testing
@testable import WorldClockCore

// When a widget's date or offset text changes: the next midnight in the zone or the next
// UTC offset change, whichever is sooner. The widget's timeline refreshes only then.

@Test func nextDisplayChangeIsNextMidnightInZone() {
    // 21:00 in Tokyo; midnight there is 15:00 UTC.
    #expect(zone("Asia/Tokyo").nextDisplayChange(after: jan15Noon) == utc(2026, 1, 15, 15, 0))
}

@Test func nextDisplayChangeIsStrictlyAfterNow() {
    // Exactly midnight in Tokyo: the next change is the following midnight.
    #expect(zone("Asia/Tokyo").nextDisplayChange(after: utc(2026, 1, 15, 15, 0)) == utc(2026, 1, 16, 15, 0))
}

@Test func nextDisplayChangeIsDSTTransitionWhenSooner() {
    // 1:00 AM EST on March 8, 2026; clocks jump at 2:00 AM EST (07:00 UTC).
    #expect(zone("America/New_York").nextDisplayChange(after: utc(2026, 3, 8, 6, 0)) == utc(2026, 3, 8, 7, 0))
}

@Test func nextDisplayChangeAfterTransitionIsMidnight() {
    // Right after the jump, the next change is midnight EDT (04:00 UTC).
    #expect(zone("America/New_York").nextDisplayChange(after: utc(2026, 3, 8, 7, 0)) == utc(2026, 3, 9, 4, 0))
}

@Test func midnightSkippedByDSTMovesToTheTransition() {
    // Santiago skips from 00:00 to 01:00 on September 6, 2026 (04:00 UTC).
    #expect(zone("America/Santiago").nextDisplayChange(after: utc(2026, 9, 5, 16, 0)) == utc(2026, 9, 6, 4, 0))
}

@Test func displayChangesListsSuccessiveChanges() {
    let changes = zone("America/New_York").displayChanges(after: utc(2026, 3, 7, 12, 0), count: 3)
    #expect(changes == [utc(2026, 3, 8, 5, 0), utc(2026, 3, 8, 7, 0), utc(2026, 3, 9, 4, 0)])
}
