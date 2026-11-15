import Foundation

/// GET 요청 하나를 나타낸다. endpoint 는 `GitHubAPI` 가, 응답 모델은 이 요청을 쓰는 Feature 가 정한다.
struct HTTPRequest: Sendable, Equatable {
  var url: URL
  var queryItems: [URLQueryItem]
  var headers: [String: String]

  init(
    url: URL,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:]
  ) {
    self.url = url
    self.queryItems = queryItems
    self.headers = headers
  }
}
