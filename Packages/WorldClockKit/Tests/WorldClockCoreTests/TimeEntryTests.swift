import Testing
@testable import WorldClockCore

// Typed times in the Compare window. `editing` is the time being replaced, in minutes since midnight.
private let threePM = 15 * 60
private let threeAM = 3 * 60

@Test func typedTimeWithDayPeriod() {
    #expect(TimeEntry.minuteOfDay(from: "9:30 pm", twelveHour: true, editing: threeAM) == 21 * 60 + 30)
    #expect(TimeEntry.minuteOfDay(from: "9:30PM", twelveHour: true, editing: threeAM) == 21 * 60 + 30)
    #expect(TimeEntry.minuteOfDay(from: "9 a.m.", twelveHour: true, editing: threePM) == 9 * 60)
    #expect(TimeEntry.minuteOfDay(from: "12 am", twelveHour: true, editing: threePM) == 0)
    #expect(TimeEntry.minuteOfDay(from: "12:15 pm", twelveHour: true, editing: threeAM) == 12 * 60 + 15)
    #expect(TimeEntry.minuteOfDay(from: "9p", twelveHour: false, editing: threeAM) == 21 * 60)
}

@Test func typedTimeWithoutDayPeriodKeepsTheShownHalfOfTheDay() {
    #expect(TimeEntry.minuteOfDay(from: "5", twelveHour: true, editing: threePM) == 17 * 60)
    #expect(TimeEntry.minuteOfDay(from: "5", twelveHour: true, editing: threeAM) == 5 * 60)
    #expect(TimeEntry.minuteOfDay(from: "12:30", twelveHour: true, editing: threePM) == 12 * 60 + 30)
    #expect(TimeEntry.minuteOfDay(from: "12:30", twelveHour: true, editing: threeAM) == 30)
}

@Test func typedTwentyFourHourTime() {
    #expect(TimeEntry.minuteOfDay(from: "17:45", twelveHour: true, editing: threeAM) == 17 * 60 + 45)
    #expect(TimeEntry.minuteOfDay(from: "5", twelveHour: false, editing: threePM) == 5 * 60)
    #expect(TimeEntry.minuteOfDay(from: "0:05", twelveHour: false, editing: threePM) == 5)
    #expect(TimeEntry.minuteOfDay(from: "2130", twelveHour: false, editing: threePM) == 21 * 60 + 30)
    #expect(TimeEntry.minuteOfDay(from: "21.30", twelveHour: false, editing: threePM) == 21 * 60 + 30)
}

@Test func typedTimeIgnoresSpacesAndNarrowNoBreakSpace() {
    // The shown time ("3:00 PM" with U+202F) must read back as itself.
    #expect(TimeEntry.minuteOfDay(from: " 3:00\u{202F}PM ", twelveHour: true, editing: threePM) == threePM)
}

@Test func invalidTypedTimeIsRejected() {
    for text in ["", "pm", "25", "13 pm", "0 am", "9:60", "9:3", "abc", "9:30 xm", "12345"] {
        #expect(TimeEntry.minuteOfDay(from: text, twelveHour: true, editing: threePM) == nil, "\(text)")
    }
}
