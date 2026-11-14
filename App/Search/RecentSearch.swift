import Foundation

/// 실행한 검색어와 그 시각
struct RecentSearch: Codable, Equatable, Identifiable, Sendable {
  /// 앞뒤 공백을 제거한, 마지막에 입력한 형태의 검색어
  let keyword: String
  let searchedAt: Date

  /// 목록 안에서 검색어는 대소문자를 무시하고 하나뿐이다.
  var id: String { keyword.lowercased() }

  init(keyword: String, searchedAt: Date) {
    self.keyword = keyword
    self.searchedAt = searchedAt
  }

  /// 검색한 날짜. `MM.dd` (예: `03.09`)
  func searchedDateText(calendar: Calendar = .current) -> String {
    searchedAt.formatted(
      Date.VerbatimFormatStyle(
        format: "\(month: .twoDigits).\(day: .twoDigits)",
        timeZone: calendar.timeZone,
        calendar: calendar
      )
    )
  }
}
