import Foundation

extension Zone {
    /// The first instant after `now` when this zone's date, AM/PM or UTC offset changes: the
    /// next noon or midnight here or the next offset change (DST), whichever is soonest. A
    /// widget showing them only needs to refresh then; its hours and minutes update on their
    /// own. A midnight skipped by a DST gap resolves to the gap's end, which is the transition.
    public func nextDisplayChange(after now: Date) -> Date {
        let today = wallTime(at: now)
        let tomorrow = WallTime(year: today.year, month: today.month, day: today.day, hour: 0, minute: 0).asUTC
            .addingTimeInterval(24 * 3600)
        let c = WallTime.utcCalendar.dateComponents([.year, .month, .day], from: tomorrow)
        let midnight = instant(for: WallTime(year: c.year!, month: c.month!, day: c.day!, hour: 0, minute: 0))
        let noon = instant(for: WallTime(year: today.year, month: today.month, day: today.day, hour: 12, minute: 0))
        let next = noon > now ? min(noon, midnight) : midnight
        guard let transition = timeZone.nextDaylightSavingTimeTransition(after: now) else { return next }
        return min(next, transition)
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
