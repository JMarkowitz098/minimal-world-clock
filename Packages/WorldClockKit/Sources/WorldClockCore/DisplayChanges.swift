import Foundation

extension Zone {
    /// The first instant after `now` when this zone's date or UTC offset changes: the next
    /// midnight here or the next offset change (DST), whichever is sooner. A widget showing
    /// the date and offset only needs to refresh then; its time text updates on its own.
    /// A midnight skipped by a DST gap resolves to the gap's end, which is the transition.
    public func nextDisplayChange(after now: Date) -> Date {
        let today = wallTime(at: now)
        let tomorrow = WallTime(year: today.year, month: today.month, day: today.day, hour: 0, minute: 0).asUTC
            .addingTimeInterval(24 * 3600)
        let c = WallTime.utcCalendar.dateComponents([.year, .month, .day], from: tomorrow)
        let midnight = instant(for: WallTime(year: c.year!, month: c.month!, day: c.day!, hour: 0, minute: 0))
        guard let transition = timeZone.nextDaylightSavingTimeTransition(after: now) else { return midnight }
        return min(midnight, transition)
    }

    /// The next `count` display changes after `now`, in order.
    public func displayChanges(after now: Date, count: Int) -> [Date] {
        var changes: [Date] = []
        var last = now
        for _ in 0..<count {
            last = nextDisplayChange(after: last)
            changes.append(last)
        }
        return changes
    }
}
