import Foundation

/// GET 요청 하나를 나타낸다. 어떤 endpoint 인지와 응답 모양은 이 요청을 만드는 쪽(`GitHub` 폴더)이 정한다.
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
