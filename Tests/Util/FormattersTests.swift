import Foundation
import Testing

@testable import GitHubSearch

struct FormattersTests {
  @Test
  func monthDayTextIsZeroPaddedMonthAndDay() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
    let date = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 0, minute: 30))
    )

    #expect(date.monthDayText(calendar: calendar) == "03.09")
  }

  /// 같은 시각이라도 달력의 시간대에 따라 날짜가 달라진다.
  @Test
  func monthDayTextFollowsCalendarTimeZone() throws {
    var seoul = Calendar(identifier: .gregorian)
    seoul.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = try #require(TimeZone(identifier: "UTC"))
    let date = try #require(
      seoul.date(from: DateComponents(year: 2026, month: 12, day: 25, hour: 0, minute: 30))
    )

    #expect(date.monthDayText(calendar: seoul) == "12.25")
    #expect(date.monthDayText(calendar: utc) == "12.24")
  }

  @Test
  func groupedTextPutsCommaEveryThreeDigits() {
    #expect(0.groupedText == "0")
    #expect(999.groupedText == "999")
    #expect(1_000.groupedText == "1,000")
    #expect(266_714.groupedText == "266,714")
    #expect(1_234_567.groupedText == "1,234,567")
  }

  @Test
  func trimmedRemovesSurroundingWhitespaceAndNewlines() {
    #expect(" swift \n".trimmed == "swift")
    #expect("swift ui".trimmed == "swift ui")
    #expect(" \n\t".trimmed == "")
  }
}
