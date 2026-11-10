import Foundation

/// A date and time as read off a clock in some zone, with no zone attached: "January 15, 2026, 21:00".
public struct WallTime: Hashable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int
    public var hour: Int
    public var minute: Int
    public var second: Int

    public init(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int = 0) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
    }

    /// This wall time read as if it were UTC. Used as a zone-free reference point.
    var asUTC: Date {
        Self.utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
}

extension Zone {
    /// The time on a clock in this zone at `now`.
    public func wallTime(at now: Date) -> WallTime {
        let shifted = now.addingTimeInterval(TimeInterval(utcOffset(at: now)))
        let c = WallTime.utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: shifted)
        return WallTime(year: c.year!, month: c.month!, day: c.day!, hour: c.hour!, minute: c.minute!, second: c.second!)
    }

    /// The instant when clocks in this zone show `wall`.
    /// - A time skipped by a DST gap moves forward by the gap (02:30 on a spring-forward night → 03:30).
    /// - A time that happens twice in a DST overlap resolves to the first occurrence.
    public func instant(for wall: WallTime) -> Date {
        let reference = wall.asUTC
        // Every offset in effect near this wall time. Real offsets lie within UTC−12...UTC+14,
        // so the instant is within that range of `reference`.
        let offsets = Set([-14 * 3600, 0, 12 * 3600].map { utcOffset(at: reference.addingTimeInterval(TimeInterval($0))) })
        let candidates = offsets
            .map { reference.addingTimeInterval(TimeInterval(-$0)) }
            .filter { wallTime(at: $0) == wall }
        if let first = candidates.min() {
            return first
        }
        // In a gap: apply the offset from before the jump (the smaller one), which lands after it.
        return reference.addingTimeInterval(TimeInterval(-offsets.min()!))
    }
}
