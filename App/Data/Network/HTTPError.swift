import Foundation

/// `APIClientProtocol` 구현이 던지는 오류. `Data` 안에서만 쓰고, 화면에는 `SearchError` 로 바꿔 넘긴다.
enum HTTPError: Error, Equatable, Sendable {
  /// 연결 실패, 타임아웃 등 서버에 닿지 못한 경우
  case network
  /// 요청할 URL 을 만들 수 없는 경우
  case invalidRequest
  /// HTTP 응답이 아니거나 본문을 해석할 수 없는 경우
  case invalidResponse
  /// 응답이 성공(2xx)이 아닌 경우. 상태 코드가 무슨 뜻인지는 저장소 구현이 정한다.
  case unsuccessfulStatusCode(Int)
}
