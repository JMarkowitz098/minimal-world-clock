import Foundation

extension Locale {
    /// Whether this locale shows 12-hour time (with AM/PM) by default.
    var usesTwelveHourTime: Bool {
        DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: self)?.contains("a") ?? false
    }
}
