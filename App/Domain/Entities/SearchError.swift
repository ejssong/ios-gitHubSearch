/// 검색이 실패했을 때 화면에 알릴 수 있는 이유. `Data` 의 구현이 통신 오류를 이 값으로 바꿔 넘긴다.
enum SearchError: Error, Equatable, Sendable {
  /// 서버에 닿지 못했다.
  case network
  /// 호출 제한에 걸렸다.
  case rateLimited
  /// 그 밖의 모든 경우
  case unknown

  /// 화면에 보여줄 안내 문구
  var message: String {
    switch self {
    case .network:
      "네트워크 연결을 확인해 주세요."
    case .rateLimited:
      "요청이 많습니다. 잠시 후 다시 시도해 주세요."
    case .unknown:
      "문제가 발생했습니다. 다시 시도해 주세요."
    }
  }
}
