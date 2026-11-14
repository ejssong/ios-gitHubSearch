import Foundation
import Testing

@testable import GitHubSearch

struct RecentSearchTests {
  @Test
  func searchedDateTextIsZeroPaddedMonthAndDay() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
    let date = try #require(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 0, minute: 30))
    )

    let recentSearch = RecentSearch(keyword: "swift", searchedAt: date)

    #expect(recentSearch.searchedDateText(calendar: calendar) == "03.09")
  }

  @Test
  func idIgnoresCase() {
    let date = Date(timeIntervalSince1970: 0)

    #expect(
      RecentSearch(keyword: "SwiftUI", searchedAt: date).id
        == RecentSearch(keyword: "swiftui", searchedAt: date).id
    )
  }
}
