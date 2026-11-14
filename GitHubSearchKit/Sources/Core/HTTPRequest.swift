import Foundation

/// GET 요청 하나를 나타낸다. endpoint 와 응답 모델은 이 요청을 쓰는 Feature 가 정한다.
public struct HTTPRequest: Sendable, Equatable {
  public var url: URL
  public var queryItems: [URLQueryItem]
  public var headers: [String: String]

  public init(
    url: URL,
    queryItems: [URLQueryItem] = [],
    headers: [String: String] = [:]
  ) {
    self.url = url
    self.queryItems = queryItems
    self.headers = headers
  }
}
