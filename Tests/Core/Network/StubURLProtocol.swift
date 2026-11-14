import Dependencies
import Foundation

/// 실제 네트워크 대신 미리 정해 둔 응답을 돌려준다. 요청 경로(path)로 응답을 고른다.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
  enum Stub: Sendable {
    case response(statusCode: Int, headers: [String: String] = [:], body: Data = Data())
    case failure(URLError.Code)
  }

  private static let stubs = LockIsolated<[String: Stub]>([:])
  private static let requests = LockIsolated<[String: URLRequest]>([:])

  static func session(path: String, stub: Stub) -> URLSession {
    stubs.withValue { $0[path] = stub }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  static func lastRequest(path: String) -> URLRequest? {
    requests.value[path]
  }

  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

  override func startLoading() {
    guard let url = request.url, let stub = Self.stubs.value[url.path] else {
      client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
      return
    }
    Self.requests.withValue { $0[url.path] = request }

    switch stub {
    case let .response(statusCode, headers, body):
      let response = HTTPURLResponse(
        url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers
      )!
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: body)
      client?.urlProtocolDidFinishLoading(self)
    case let .failure(code):
      client?.urlProtocol(self, didFailWithError: URLError(code))
    }
  }

  override func stopLoading() {}
}
