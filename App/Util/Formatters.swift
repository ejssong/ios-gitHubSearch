import Foundation

// 화면에 보여줄 문자열을 만들거나 입력 문자열을 다듬는 공통 도구. 어느 계층에서나 쓸 수 있고, 다른 폴더를 참조하지 않는다.

extension Date {
  /// 월과 일을 두 자리씩 `MM.dd` 로 적는다. (예: `03.09`)
  func monthDayText(calendar: Calendar = .current) -> String {
    formatted(
      Date.VerbatimFormatStyle(
        format: "\(month: .twoDigits).\(day: .twoDigits)",
        timeZone: calendar.timeZone,
        calendar: calendar
      )
    )
  }
}

extension Int {
  /// 세 자리마다 쉼표를 찍는다. 기기 설정과 상관없이 같은 모양이다. (예: `266,714`)
  var groupedText: String {
    formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
  }
}

extension String {
  /// 앞뒤의 공백과 줄바꿈을 뗀다. (예: `" swift \n"` → `"swift"`)
  var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
