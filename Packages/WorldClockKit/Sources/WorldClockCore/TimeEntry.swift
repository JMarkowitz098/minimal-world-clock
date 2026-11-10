import Foundation

/// Reads a time of day the user typed: "9", "9:30", "930", "9.30", "21:30", "9:30 pm", "9p",
/// "9 a.m.". English AM/PM markers only (localization is for later).
public enum TimeEntry {
    /// The typed time in minutes since midnight (0...1439), or `nil` if it isn't a time.
    ///
    /// With AM/PM the hour must be 1–12. Without, hours 0 and 13–23 read as 24-hour time; hours
    /// 1–12 do too when `twelveHour` is false, and otherwise keep the AM/PM of `editing` (the
    /// time being replaced), so typing "5" over 3:00 PM means 5 PM.
    public static func minuteOfDay(from text: String, twelveHour: Bool, editing: Int) -> Int? {
        var rest = text.lowercased().filter { !$0.isWhitespace }
        var isPM: Bool?
        for (marker, pm) in [("a.m.", false), ("p.m.", true), ("am", false), ("pm", true), ("a", false), ("p", true)]
        where rest.hasSuffix(marker) {
            isPM = pm
            rest.removeLast(marker.count)
            break
        }
        guard let (hour, minute) = hourAndMinute(rest), minute < 60 else { return nil }

        if let isPM {
            guard (1...12).contains(hour) else { return nil }
            return (hour % 12 + (isPM ? 12 : 0)) * 60 + minute
        }
        guard hour < 24 else { return nil }
        if twelveHour, (1...12).contains(hour) {
            let afternoon = editing >= 12 * 60
            return (hour % 12 + (afternoon ? 12 : 0)) * 60 + minute
        }
        return hour * 60 + minute
    }

    /// "9" → (9, 0); "9:30", "9.30", "930" → (9, 30); "2130" → (21, 30). Minutes need two digits.
    private static func hourAndMinute(_ text: String) -> (Int, Int)? {
        let parts = text.split(separator: /[:.]/, omittingEmptySubsequences: false)
        guard parts.allSatisfy({ !$0.isEmpty && $0.allSatisfy(\.isASCII) && $0.allSatisfy(\.isNumber) }) else { return nil }
        switch parts.count {
        case 1:
            let digits = parts[0]
            switch digits.count {
            case 1, 2: return (Int(digits)!, 0)
            case 3, 4: return (Int(digits.dropLast(2))!, Int(digits.suffix(2))!)
            default: return nil
            }
        case 2 where parts[0].count <= 2 && parts[1].count == 2:
            return (Int(parts[0])!, Int(parts[1])!)
        default:
            return nil
        }
    }
}
