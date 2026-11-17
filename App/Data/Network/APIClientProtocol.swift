import Foundation

/// 서버에서 값을 가져오는 통로. 저장소 구현은 이 프로토콜만 보고, 테스트에서는 가짜로 바꿔 끼운다.
protocol APIClientProtocol: Sendable {
  /// `path` 에 GET 요청을 보내고 응답 본문을 `Response` 로 해석해 돌려준다.
  /// 실패하면 `HTTPError` 를 던진다. 취소는 `CancellationError` 로 던진다.
  func get<Response: Decodable>(_ path: String, queryItems: [URLQueryItem]) async throws -> Response
}
