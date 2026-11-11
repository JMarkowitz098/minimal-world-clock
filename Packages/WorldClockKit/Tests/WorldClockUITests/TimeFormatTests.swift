import Foundation
import Testing
@testable import WorldClockCore
@testable import WorldClockUI

private let enUS = Locale(identifier: "en_US")
private let enGB = Locale(identifier: "en_GB")

@Test func systemTimeFormatKeepsTheLocale() {
    #expect(enUS.applying(.system) == enUS)
    #expect(enGB.applying(.system) == enGB)
}

@Test func timeFormatOverridesTheLocale() {
    #expect(!enUS.applying(.twentyFourHour).usesTwelveHourTime)
    #expect(enGB.applying(.twelveHour).usesTwelveHourTime)
}

@Test func timeTextHonorsTheTimeFormat() {
    let tokyo = zone("Asia/Tokyo")
    #expect(ZoneFormatter(zone: tokyo, locale: enUS.applying(.twentyFourHour)).display(at: jan15Noon).timeText == "21:00")
    #expect(ZoneFormatter(zone: tokyo, locale: enGB.applying(.twelveHour)).display(at: jan15Noon).timeText == "9:00\(nnbsp)pm")
}

@MainActor @Test func clockFollowsALocaleChange() {
    let (model, _, _) = makeClock()
    #expect(model.timeText == "9:00\(nnbsp)PM")
    model.setLocale(enUS.applying(.twentyFourHour))
    #expect(model.timeText == "21:00")
    #expect(model.dateText == "Thursday, January 15")
}

@MainActor @Test func compareFollowsALocaleChange() {
    let (model, _, _) = makeCompare()
    model.setLocale(enUS.applying(.twentyFourHour))
    #expect(model.a.timeText == "07:00")
    #expect(model.b.timeText == "21:00")
    #expect(model.scrubberMarks.map(\.label) == ["00", "06", "12", "18"])
    // Typed times are read as 24-hour now: "5" is 05:00, not 5 in the shown half of the day.
    model.scrub(toMinuteOfDay: 15 * 60)
    #expect(model.typeTimeA("5"))
    #expect(model.scrubberMinuteOfDay == 5 * 60)
}

@MainActor @Test func compareKeepsItsStateAcrossALocaleChange() {
    let (model, _, _) = makeCompare()
    model.scrub(toMinuteOfDay: 9 * 60)
    model.setLocale(enUS.applying(.twentyFourHour))
    #expect(!model.isLive)
    #expect(model.a.timeText == "09:00")
}

@Test func widgetHonorsTheTimeFormat() {
    let display = WidgetDisplay(zone: zone("Asia/Tokyo"), at: jan15Noon, locale: enUS.applying(.twentyFourHour))
    #expect(display.timeText == "21:00")
    #expect(display.dayPeriodText == nil)
}

// 24-hour time end to end (M9). 24-hour locales pad the hour ("09:00", like macOS's menu bar
// clock); kept as the locale gives it (decided with the user).

@Test func widestTimeInTwentyFourHourLocale() {
    let formatter = ZoneFormatter(zone: zone("America/New_York"), locale: enGB)
    let sevenAM = formatter.display(at: jan15Noon).time
    #expect(String(sevenAM.characters) == "07:00")
    // Already two hour digits: as wide as it gets.
    #expect(TimeStyle.widestTime(sevenAM) == sevenAM)
    // A 24-hour format without the padding still sizes for two digits.
    #expect(String(TimeStyle.widestTime(AttributedString("7:00")).characters) == "87:00")
}

@MainActor @Test func compareTimesInTwentyFourHourLocale() {
    let (model, _, _) = makeCompare(locale: "en_GB")
    #expect(model.a.timeText == "07:00")
    #expect(model.b.timeText == "21:00")
    #expect(model.scrubberSpokenValue == "07:00; in Tokyo 21:00")
    #expect(model.typeTimeA("21:30"))
    #expect(model.a.timeText == "21:30")
    #expect(model.b.timeText == "11:30")
    #expect(model.zoneBDateText == "Friday 16 January · next day")
}

@Test func formattersFollowALocaleChange() {
    let formatter = ZoneFormatter(zone: zone("Asia/Tokyo"), locale: enUS)
    #expect(formatter.display(at: jan15Noon).timeText == "9:00\(nnbsp)PM")
    formatter.locale = enGB
    #expect(formatter.display(at: jan15Noon).timeText == "21:00")
    #expect(formatter.display(at: jan15Noon).dateText == "Thursday 15 January")
    formatter.locale = enGB.applying(.twelveHour)
    #expect(formatter.display(at: jan15Noon).timeText == "9:00\(nnbsp)pm")
}
