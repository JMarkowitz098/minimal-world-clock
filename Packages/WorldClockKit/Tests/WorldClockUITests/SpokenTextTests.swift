import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

// What VoiceOver reads (M8). jan15Noon is 7:00 AM Thursday in New York, 9:00 PM Thursday in Tokyo.

@Test @MainActor func clockSpokenText() {
    let (model, _, _) = makeClock()
    #expect(model.spokenText == "Tokyo, 9:00\(nnbsp)PM, Thursday, January 15")
    model.select(place("America/New_York"))
    #expect(model.spokenText == "New York, 7:00\(nnbsp)AM, Thursday, January 15")
}

@Test @MainActor func compareSpokenDifference() {
    let (model, _, _) = makeCompare()
    #expect(model.spokenDifference == "Tokyo is 14 hours ahead of New York")
    model.swap()
    #expect(model.spokenDifference == "New York is 14 hours behind Tokyo")
}

@Test @MainActor func compareSpokenDifferenceSameTime() {
    let (model, _, _) = makeCompare(a: zone("Europe/London"), b: zone("UTC"))
    #expect(model.spokenDifference == "UTC has the same time as London")
}

@Test @MainActor func zoneBSpokenDateNamesItsDay() {
    let (model, _, _) = makeCompare()
    #expect(model.zoneBSpokenDate == "Thursday, January 15")
    model.scrub(toMinuteOfDay: 15 * 60)  // 3 PM New York = 5 AM Friday Tokyo
    #expect(model.zoneBSpokenDate == "Friday, January 16, next day")
}

@Test @MainActor func scrubberSpokenValueIncludesZoneB() {
    let (model, _, _) = makeCompare()
    #expect(model.scrubberSpokenValue == "7:00\(nnbsp)AM; in Tokyo 9:00\(nnbsp)PM")
    model.scrub(toMinuteOfDay: 15 * 60)
    #expect(model.scrubberSpokenValue == "3:00\(nnbsp)PM; in Tokyo 5:00\(nnbsp)AM, next day")
}

@Test @MainActor func pickerRowSpokenLabelHasNoSeparator() {
    let picker = ZonePickerViewModel(catalog: ZoneCatalog(zones: [zone("Asia/Tokyo"), zone("UTC")]), now: jan15Noon)
    #expect(picker.rows.map(\.spokenLabel) == ["Tokyo, Asia, UTC+9", "UTC"])
}
