import Foundation
import SwiftUI
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

// The windows draw the time with its day period (AM/PM) smaller than the digits. The formatted time marks that part so views can style it.

private func dayPeriod(in time: AttributedString) -> String? {
    time.runs.first { $0.foundation.dateField == .amPM }.map { String(time[$0.range].characters) }
}

@Test func timeMarksItsDayPeriod() {
    let display = ZoneFormatter(zone: zone("Asia/Tokyo"), locale: Locale(identifier: "en_US")).display(at: jan15Noon)
    #expect(String(display.time.characters) == display.timeText)
    #expect(dayPeriod(in: display.time) == "PM")
}

@Test func twentyFourHourTimeHasNoDayPeriod() {
    let display = ZoneFormatter(zone: zone("Asia/Tokyo"), locale: Locale(identifier: "en_GB")).display(at: jan15Noon)
    #expect(display.timeText == "21:00")
    #expect(dayPeriod(in: display.time) == nil)
}

@Test func styledTimeSetsAFontOnlyOnTheDayPeriod() {
    let display = ZoneFormatter(zone: zone("Asia/Tokyo"), locale: Locale(identifier: "en_US")).display(at: jan15Noon)
    let styled = TimeStyle.shrinkingDayPeriod(display.time, timeSize: 56)
    #expect(String(styled.characters) == display.timeText)
    for run in styled.runs {
        let text = String(styled[run.range].characters)
        #expect((run.swiftUI.font != nil) == (text == "PM"), "run \(text)")
    }
}

@MainActor @Test func scrubberMarksEverySixHours() {
    let (model, _, _) = makeCompare()
    #expect(model.scrubberMarks.map(\.minuteOfDay) == [0, 360, 720, 1080])
    #expect(model.scrubberMarks.map(\.label) == ["12\(nnbsp)AM", "6\(nnbsp)AM", "12\(nnbsp)PM", "6\(nnbsp)PM"])
}

@MainActor @Test func scrubberMarksFollowTwentyFourHourLocale() {
    let model = CompareViewModel(
        store: InMemorySettingsStore(), defaultZones: (zone("Europe/London"), zone("Asia/Tokyo")),
        locale: Locale(identifier: "en_GB"), clock: { jan15Noon }, ticker: FakeTicker()
    )
    #expect(model.scrubberMarks.map(\.label) == ["00", "06", "12", "18"])
}


// The Compare window sizes itself by the widest time, so its scale doesn't change while scrubbing.
@Test func widestTimeHasTwoHourDigits() {
    let formatter = ZoneFormatter(zone: zone("America/New_York"), locale: Locale(identifier: "en_US"))
    let sevenAM = formatter.display(at: jan15Noon).time  // "7:00 AM"
    #expect(String(TimeStyle.widestTime(sevenAM).characters) == "87:00\u{202F}AM")
    #expect(dayPeriod(in: TimeStyle.widestTime(sevenAM)) == "AM")
    let tenPM = formatter.display(at: jan15Noon.addingTimeInterval(15 * 3600)).time  // "10:00 PM"
    #expect(TimeStyle.widestTime(tenPM) == tenPM)
}
