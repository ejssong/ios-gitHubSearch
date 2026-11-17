import Foundation

/// GitHub API 에 실제로 요청을 보내는 `APIClientProtocol` 구현.
///
/// 서버 주소와 공통 헤더를 알고, 응답이 성공(2xx)인지 확인하고, 본문을 JSON 으로 해석한다.
/// 실패한 상태 코드가 무슨 뜻인지는 여기서 정하지 않고 코드만 담아 던진다. (`RemoteSearchRepository` 가 정한다.)
/// 검색 endpoint 의 경로와 쿼리는 아래 `APIClientProtocol` 확장의 `searchRepositories(keyword:page:)` 가 정한다.
struct SearchAPIClient: APIClientProtocol {
  private enum Host {
    static let apiBaseURL = URL(string: "https://api.github.com")!
  }

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func get<Response: Decodable>(_ path: String, queryItems: [URLQueryItem]) async throws -> Response {
    let url = try makeURL(path: path, queryItems: queryItems)
    let data = try await data(from: url)
    do {
      return try JSONDecoder().decode(Response.self, from: data)
    } catch {
      throw HTTPError.invalidResponse
    }
  }

  /// 공통 헤더를 붙여 요청을 보내고, 성공한 응답의 본문을 돌려준다. 인증 없이 호출한다.
  private func data(from url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    do {
      let (data, response) = try await session.data(for: request)
      try validate(response)
      return data
    } catch let error as URLError {
      // 취소는 오류가 아니라 취소로 전달해 effect 취소가 그대로 동작하게 한다.
      throw error.code == .cancelled ? CancellationError() : HTTPError.network
    }
  }

  private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
    guard
      var components = URLComponents(
        url: Host.apiBaseURL.appending(path: path), resolvingAgainstBaseURL: false
      )
    else { throw HTTPError.invalidRequest }
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    // `URLComponents` 는 `+` 를 인코딩하지 않는데 서버는 쿼리의 `+` 를 공백으로 읽는다.
    // 그대로 보내면 "c++" 가 "c" 로 검색되므로 직접 인코딩한다.
    let encodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
    components.percentEncodedQuery = encodedQuery

    guard let url = components.url else { throw HTTPError.invalidRequest }
    return url
  }

  private func validate(_ response: URLResponse) throws {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw HTTPError.invalidResponse
    }
    guard (200..<300).contains(httpResponse.statusCode) else {
      throw HTTPError.unsuccessfulStatusCode(httpResponse.statusCode)
    }
  }
}

extension APIClientProtocol {
  /// `GET /search/repositories?q={keyword}&page={page}`. `page` 는 1부터 센다.
  ///
  /// `per_page` 를 보내지 않아 한 페이지는 API 기본값인 30개다. 화면의 다음 페이지 판단이 이 값에 기대므로,
  /// `per_page` 를 보내게 되면 함께 맞춰야 한다.
  func searchRepositories(keyword: String, page: Int) async throws -> SearchDTO {
    try await get(
      "search/repositories",
      queryItems: [
        URLQueryItem(name: "q", value: keyword),
        URLQueryItem(name: "page", value: String(page)),
      ]
    )
  }
}
