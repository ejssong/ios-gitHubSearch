import Foundation

/// `APIClientProtocol` 구현이 던지는 오류. `Data` 안에서만 쓰고, 화면에는 `SearchError` 로 바꿔 넘긴다.
enum HTTPError: Error, Equatable, Sendable {
  /// 연결 실패, 타임아웃 등 서버에 닿지 못한 경우
  case network
  /// 호출 제한에 걸린 경우 (429, 또는 한도 소진을 알리는 403)
  case rateLimited
  /// 요청 자체가 잘못된 경우 (URL 을 만들 수 없음, 그 밖의 4xx)
  case invalidRequest
  /// 그 밖의 모든 경우 (5xx, 해석할 수 없는 응답)
  case unknown
}

extension HTTPError {
  /// 응답 상태를 오류로 바꾼다. 2xx 면 `nil`.
  init?(statusCode: Int, headerFields: [String: String]) {
    switch statusCode {
    case 200..<300:
      return nil
    case 429:
      self = .rateLimited
    case 403 where Self.isRateLimitExhausted(headerFields):
      self = .rateLimited
    case 400..<500:
      self = .invalidRequest
    default:
      self = .unknown
    }
  }

  /// GitHub 은 한도 소진을 403 과 `x-ratelimit-remaining: 0` 또는 `retry-after` 로 알린다.
  private static func isRateLimitExhausted(_ headerFields: [String: String]) -> Bool {
    let fields = Dictionary(
      headerFields.map { ($0.key.lowercased(), $0.value) },
      uniquingKeysWith: { first, _ in first }
    )
    return fields["x-ratelimit-remaining"] == "0" || fields["retry-after"] != nil
  }
}
