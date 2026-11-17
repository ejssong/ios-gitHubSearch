import Foundation

@testable import GitHubSearch

/// 실제로 요청을 보내지 않고, 정해 둔 본문을 해석해 돌려주거나 오류를 던지는 가짜 `APIClientProtocol`.
struct StubAPIClient: APIClientProtocol {
  var respond: @Sendable (_ path: String, _ queryItems: [URLQueryItem]) async throws -> Data

  func get<Response: Decodable>(_ path: String, queryItems: [URLQueryItem]) async throws -> Response {
    let data = try await respond(path, queryItems)
    do {
      return try JSONDecoder().decode(Response.self, from: data)
    } catch {
      // 프로토콜의 약속대로, 해석할 수 없는 본문은 `HTTPError` 로 알린다.
      throw HTTPError.invalidResponse
    }
  }
}
