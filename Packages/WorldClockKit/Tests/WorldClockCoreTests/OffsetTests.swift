import Foundation
import Testing
@testable import WorldClockCore

// MARK: UTC offset text

@Test func utcOffsetTextInWinterAndSummer() {
    #expect(zone("America/New_York").utcOffsetText(at: jan15Noon) == "UTC−5")
    #expect(zone("America/New_York").utcOffsetText(at: jul15Noon) == "UTC−4")
    #expect(zone("Europe/London").utcOffsetText(at: jan15Noon) == "UTC")
    #expect(zone("Europe/London").utcOffsetText(at: jul15Noon) == "UTC+1")
    #expect(zone("Australia/Sydney").utcOffsetText(at: jan15Noon) == "UTC+11")
    #expect(zone("Australia/Sydney").utcOffsetText(at: jul15Noon) == "UTC+10")
}

@Test func utcOffsetTextForUTCIsPlain() {
    #expect(zone("UTC").utcOffsetText(at: jan15Noon) == "UTC")
    #expect(zone("UTC").utcOffset(at: jan15Noon) == 0)
}

@Test func utcOffsetTextForHalfAndQuarterHourZones() {
    #expect(zone("Asia/Calcutta").utcOffsetText(at: jan15Noon) == "UTC+5:30")
    #expect(zone("Asia/Kathmandu").utcOffsetText(at: jan15Noon) == "UTC+5:45")
    #expect(zone("America/St_Johns").utcOffsetText(at: jan15Noon) == "UTC−3:30")
    #expect(zone("Asia/Calcutta").utcOffset(at: jan15Noon) == 5 * 3600 + 30 * 60)
}

// MARK: Difference between two zones

@Test func differenceTextInWholeHours() {
    let newYork = zone("America/New_York"), tokyo = zone("Asia/Tokyo")
    #expect(tokyo.offsetText(from: newYork, at: jan15Noon) == "+14 h")
    #expect(newYork.offsetText(from: tokyo, at: jan15Noon) == "−14 h")
    #expect(tokyo.offset(from: newYork, at: jan15Noon) == 14 * 3600)
}

@Test func differenceTextWithMinutes() {
    let london = zone("Europe/London")
    #expect(zone("Asia/Calcutta").offsetText(from: london, at: jan15Noon) == "+5 h 30 min")
    #expect(zone("America/St_Johns").offsetText(from: london, at: jan15Noon) == "−3 h 30 min")
}

@Test func differenceTextUnderAnHour() {
    let kolkata = zone("Asia/Calcutta"), kathmandu = zone("Asia/Kathmandu")
    #expect(kathmandu.offsetText(from: kolkata, at: jan15Noon) == "+15 min")
    #expect(kolkata.offsetText(from: kathmandu, at: jan15Noon) == "−15 min")
}

@Test func differenceTextSameTime() {
    #expect(zone("Europe/London").offsetText(from: zone("UTC"), at: jan15Noon) == "Same time")
    #expect(zone("Europe/Paris").offsetText(from: zone("Europe/Berlin"), at: jul15Noon) == "Same time")
}

@Test func differenceChangesAcrossDSTTransitions() {
    let newYork = zone("America/New_York"), london = zone("Europe/London")
    #expect(london.offsetText(from: newYork, at: jan15Noon) == "+5 h")
    #expect(london.offsetText(from: newYork, at: mar15Noon) == "+4 h")
    #expect(london.offsetText(from: newYork, at: jul15Noon) == "+5 h")
    #expect(london.offsetText(from: newYork, at: oct28Noon) == "+4 h")
}

@Test func differenceFlipsAcrossHemispheres() {
    let london = zone("Europe/London"), sydney = zone("Australia/Sydney")
    #expect(sydney.offsetText(from: london, at: jan15Noon) == "+11 h")
    #expect(sydney.offsetText(from: london, at: jul15Noon) == "+9 h")
}
