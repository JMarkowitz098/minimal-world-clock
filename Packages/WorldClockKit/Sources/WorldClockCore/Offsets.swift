import Foundation

extension Zone {
    /// Seconds ahead of UTC at `now` (negative when behind).
    public func utcOffset(at now: Date) -> Int {
        timeZone.secondsFromGMT(for: now)
    }

    /// "UTC−5", "UTC+5:30", or "UTC" for a zero offset.
    public func utcOffsetText(at now: Date) -> String {
        let seconds = utcOffset(at: now)
        guard seconds != 0 else { return "UTC" }
        let (hours, minutes) = Self.hoursAndMinutes(seconds)
        let time = minutes == 0 ? "\(hours)" : "\(hours):\(String(format: "%02d", minutes))"
        return "UTC" + Self.sign(seconds) + time
    }

    /// Seconds this zone is ahead of `reference` at `now` (negative when behind).
    public func offset(from reference: Zone, at now: Date) -> Int {
        utcOffset(at: now) - reference.utcOffset(at: now)
    }

    /// How far this zone is ahead of `reference`: "+9 h", "−3 h 30 min", "+15 min", or "Same time".
    public func offsetText(from reference: Zone, at now: Date) -> String {
        let seconds = offset(from: reference, at: now)
        guard seconds != 0 else { return "Same time" }
        let (hours, minutes) = Self.hoursAndMinutes(seconds)
        let parts = (hours > 0 ? ["\(hours) h"] : []) + (minutes > 0 ? ["\(minutes) min"] : [])
        return Self.sign(seconds) + parts.joined(separator: " ")
    }

    /// `offsetText` as VoiceOver should say it: "14 hours ahead", "3 hours 30 minutes behind",
    /// "1 hour ahead", or "same time" (lowercase: it's read inside a longer sentence).
    public func spokenOffset(from reference: Zone, at now: Date) -> String {
        let seconds = offset(from: reference, at: now)
        guard seconds != 0 else { return "same time" }
        let (hours, minutes) = Self.hoursAndMinutes(seconds)
        let parts = (hours > 0 ? [hours == 1 ? "1 hour" : "\(hours) hours"] : [])
            + (minutes > 0 ? [minutes == 1 ? "1 minute" : "\(minutes) minutes"] : [])
        return parts.joined(separator: " ") + (seconds > 0 ? " ahead" : " behind")
    }

    /// Typographic signs: "+" and the minus sign U+2212, not a hyphen.
    private static func sign(_ seconds: Int) -> String {
        seconds < 0 ? "\u{2212}" : "+"
    }

    /// Whole hours and leftover minutes of `abs(seconds)`. Leftover seconds (only in historical
    /// local mean time) are dropped.
    private static func hoursAndMinutes(_ seconds: Int) -> (Int, Int) {
        let totalMinutes = abs(seconds) / 60
        return (totalMinutes / 60, totalMinutes % 60)
    }
}
