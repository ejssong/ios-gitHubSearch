import Foundation
import Testing

@testable import GitHubSearch

struct SearchAPIClientTests {
  private struct Payload: Decodable, Equatable { var value: Int }
  private struct Empty: Decodable {}

  /// `path` 로 가는 요청에 `stub` 을 돌려주는 클라이언트. 테스트마다 다른 경로를 써서 서로 섞이지 않게 한다.
  private func client(_ path: String, _ stub: StubURLProtocol.Stub) -> SearchAPIClient {
    SearchAPIClient(session: StubURLProtocol.session(path: "/\(path)", stub: stub))
  }

  private let emptyObject = Data("{}".utf8)

  @Test
  func successDecodesBody() async throws {
    let client = client("success", .response(statusCode: 200, body: Data(#"{"value":1}"#.utf8)))

    let payload: Payload = try await client.get("success", queryItems: [])

    #expect(payload == Payload(value: 1))
  }

  @Test
  func requestGoesToBaseURLWithQueryItemsAndCommonHeaders() async throws {
    let client = client("query", .response(statusCode: 200, body: emptyObject))

    let _: Empty = try await client.get(
      "query",
      queryItems: [URLQueryItem(name: "q", value: "swift"), URLQueryItem(name: "page", value: "2")]
    )

    let sent = try #require(StubURLProtocol.lastRequest(path: "/query"))
    #expect(sent.url?.absoluteString == "https://api.github.com/query?q=swift&page=2")
    #expect(sent.httpMethod == "GET")
    #expect(sent.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
  }

  @Test
  func requestWithoutQueryItemsHasNoQuery() async throws {
    let client = client("no-query", .response(statusCode: 200, body: emptyObject))

    let _: Empty = try await client.get("no-query", queryItems: [])

    let sent = try #require(StubURLProtocol.lastRequest(path: "/no-query"))
    #expect(sent.url?.absoluteString == "https://api.github.com/no-query")
  }

  /// 서버는 쿼리의 `+` 를 공백으로 읽으므로 `%2B` 로 보내야 한다.
  @Test
  func plusInQueryValueIsPercentEncoded() async throws {
    let client = client("plus", .response(statusCode: 200, body: emptyObject))
    let queryItems = [URLQueryItem(name: "q", value: "c++ a&b"), URLQueryItem(name: "page", value: "1")]

    let _: Empty = try await client.get("plus", queryItems: queryItems)

    let sent = try #require(StubURLProtocol.lastRequest(path: "/plus"))
    #expect(sent.url?.query(percentEncoded: true) == "q=c%2B%2B%20a%26b&page=1")
    #expect(
      URLComponents(url: try #require(sent.url), resolvingAgainstBaseURL: false)?.queryItems
        == queryItems
    )
  }

  @Test
  func undecodableBodyIsInvalidResponse() async {
    let client = client("undecodable", .response(statusCode: 200, body: Data("not json".utf8)))

    await #expect(throws: HTTPError.invalidResponse) {
      let _: Payload = try await client.get("undecodable", queryItems: [])
    }
  }

  @Test
  func connectionFailureIsNetwork() async {
    let client = client("offline", .failure(.notConnectedToInternet))

    await #expect(throws: HTTPError.network) {
      let _: Empty = try await client.get("offline", queryItems: [])
    }
  }

  /// 취소는 오류로 바꾸지 않고 취소로 넘긴다.
  @Test
  func cancelledRequestThrowsCancellation() async {
    let client = client("cancelled", .failure(.cancelled))

    await #expect(throws: CancellationError.self) {
      let _: Empty = try await client.get("cancelled", queryItems: [])
    }
  }

  /// 성공(2xx)이 아니면 상태 코드만 담아 던진다. 헤더는 보지 않고, 코드의 뜻은 저장소 구현이 정한다.
  @Test(arguments: [403, 404, 422, 429, 500])
  func unsuccessfulStatusCodeIsThrownAsIs(statusCode: Int) async {
    let client = client(
      "status-\(statusCode)",
      .response(statusCode: statusCode, headers: ["X-RateLimit-Remaining": "0"])
    )

    await #expect(throws: HTTPError.unsuccessfulStatusCode(statusCode)) {
      let _: Empty = try await client.get("status-\(statusCode)", queryItems: [])
    }
  }
}
