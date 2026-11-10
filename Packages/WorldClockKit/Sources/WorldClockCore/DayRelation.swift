import Foundation

/// Where one zone's calendar date sits relative to another's at the same instant.
public enum DayRelation: Hashable, Sendable {
    case yesterday
    case today
    case tomorrow
    /// Two days apart (negative: earlier). Only zones about 24+ hours apart can do this, e.g.
    /// Kiritimati (UTC+14) and Pago Pago (UTC−11) for one hour each day.
    case days(Int)

    init(days: Int) {
        switch days {
        case -1: self = .yesterday
        case 0: self = .today
        case 1: self = .tomorrow
        default: self = .days(days)
        }
    }
}

extension Zone {
    /// This zone's date at `now` compared with `reference`'s date: `.tomorrow` when it is
    /// already the next day here.
    public func dayRelation(from reference: Zone, at now: Date) -> DayRelation {
        let calendar = WallTime.utcCalendar
        let here = wallTime(at: now), there = reference.wallTime(at: now)
        let hereDay = calendar.date(from: DateComponents(year: here.year, month: here.month, day: here.day))!
        let thereDay = calendar.date(from: DateComponents(year: there.year, month: there.month, day: there.day))!
        return DayRelation(days: calendar.dateComponents([.day], from: thereDay, to: hereDay).day!)
    }
}
