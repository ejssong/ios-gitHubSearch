import Foundation
import Testing

@testable import GitHubSearch

struct HTTPClientTests {
  private func request(_ path: String) -> HTTPRequest {
    HTTPRequest(url: URL(string: "https://stub.test\(path)")!)
  }

  private func client(_ path: String, _ stub: StubURLProtocol.Stub) -> HTTPClient {
    .live(session: StubURLProtocol.session(path: path, stub: stub))
  }

  @Test
  func successReturnsBody() async throws {
    let body = Data(#"{"value":1}"#.utf8)
    let client = client("/success", .response(statusCode: 200, body: body))

    let data = try await client.send(request("/success"))

    #expect(data == body)
  }

  @Test
  func queryItemsAndHeadersAreSent() async throws {
    let client = client("/query", .response(statusCode: 200))
    var request = request("/query")
    request.queryItems = [URLQueryItem(name: "q", value: "swift"), URLQueryItem(name: "page", value: "2")]
    request.headers = ["Accept": "application/json"]

    _ = try await client.send(request)

    let sent = try #require(StubURLProtocol.lastRequest(path: "/query"))
    #expect(sent.url?.query == "q=swift&page=2")
    #expect(sent.value(forHTTPHeaderField: "Accept") == "application/json")
  }

  /// 서버는 쿼리의 `+` 를 공백으로 읽으므로 `%2B` 로 보내야 한다.
  @Test
  func plusInQueryValueIsPercentEncoded() async throws {
    let client = client("/plus", .response(statusCode: 200))
    var request = request("/plus")
    request.queryItems = [URLQueryItem(name: "q", value: "c++ a&b"), URLQueryItem(name: "page", value: "1")]

    _ = try await client.send(request)

    let sent = try #require(StubURLProtocol.lastRequest(path: "/plus"))
    #expect(sent.url?.query(percentEncoded: true) == "q=c%2B%2B%20a%26b&page=1")
    #expect(
      URLComponents(url: try #require(sent.url), resolvingAgainstBaseURL: false)?.queryItems
        == [URLQueryItem(name: "q", value: "c++ a&b"), URLQueryItem(name: "page", value: "1")]
    )
  }

  @Test
  func decodesResponse() async throws {
    struct Payload: Decodable, Equatable { var value: Int }
    let client = client("/decode", .response(statusCode: 200, body: Data(#"{"value":1}"#.utf8)))

    let payload = try await client.send(request("/decode"), as: Payload.self)

    #expect(payload == Payload(value: 1))
  }

  @Test
  func undecodableBodyIsUnknown() async {
    struct Payload: Decodable { var value: Int }
    let client = client("/undecodable", .response(statusCode: 200, body: Data("not json".utf8)))

    await #expect(throws: HTTPError.unknown) {
      _ = try await client.send(request("/undecodable"), as: Payload.self)
    }
  }

  @Test
  func connectionFailureIsNetwork() async {
    let client = client("/offline", .failure(.notConnectedToInternet))

    await #expect(throws: HTTPError.network) {
      _ = try await client.send(request("/offline"))
    }
  }

  @Test
  func tooManyRequestsIsRateLimited() async {
    let client = client("/429", .response(statusCode: 429))

    await #expect(throws: HTTPError.rateLimited) {
      _ = try await client.send(request("/429"))
    }
  }

  @Test
  func forbiddenWithExhaustedLimitIsRateLimited() async {
    let client = client(
      "/403-limit", .response(statusCode: 403, headers: ["X-RateLimit-Remaining": "0"])
    )

    await #expect(throws: HTTPError.rateLimited) {
      _ = try await client.send(request("/403-limit"))
    }
  }

  @Test
  func forbiddenWithoutLimitHeaderIsInvalidRequest() async {
    let client = client("/403", .response(statusCode: 403))

    await #expect(throws: HTTPError.invalidRequest) {
      _ = try await client.send(request("/403"))
    }
  }

  @Test
  func unprocessableIsInvalidRequest() async {
    let client = client("/422", .response(statusCode: 422))

    await #expect(throws: HTTPError.invalidRequest) {
      _ = try await client.send(request("/422"))
    }
  }

  @Test
  func serverErrorIsUnknown() async {
    let client = client("/500", .response(statusCode: 500))

    await #expect(throws: HTTPError.unknown) {
      _ = try await client.send(request("/500"))
    }
  }
}
