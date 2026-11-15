import Foundation

/// GitHub API 에 실제로 요청을 보내는 `APIClientProtocol` 구현.
///
/// 서버 주소와 공통 헤더를 알고, 연결 오류와 상태 코드를 `HTTPError` 로 바꾸고, 응답 본문을 JSON 으로 해석한다.
/// 검색 endpoint 의 경로와 쿼리는 아래 `APIClientProtocol` 확장의 `searchRepositories(keyword:page:)` 가 정한다.
struct SearchAPIClient: APIClientProtocol {
  /// 고정된 문자열이라 실패하지 않는다.
  private static let baseURL = URL(string: "https://api.github.com")!

  /// 모든 요청에 붙이는 헤더. 인증 없이 호출한다.
  private static let defaultHeaders = ["Accept": "application/vnd.github+json"]

  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func get<Response: Decodable>(path: String, queryItems: [URLQueryItem]) async throws -> Response {
    let data = try await data(path: path, queryItems: queryItems)
    do {
      return try JSONDecoder().decode(Response.self, from: data)
    } catch {
      // 해석할 수 없는 본문은 그 밖의 오류로 본다.
      throw HTTPError.unknown
    }
  }

  /// 2xx 면 응답 본문을 돌려주고, 아니면 `HTTPError` 를 던진다.
  private func data(path: String, queryItems: [URLQueryItem]) async throws -> Data {
    let request = try urlRequest(path: path, queryItems: queryItems)

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch let error as URLError where error.code == .cancelled {
      // 취소는 오류가 아니라 취소로 전달해 effect 취소가 그대로 동작하게 한다.
      throw CancellationError()
    } catch is URLError {
      throw HTTPError.network
    } catch is CancellationError {
      throw CancellationError()
    } catch {
      throw HTTPError.unknown
    }

    guard let httpResponse = response as? HTTPURLResponse else { throw HTTPError.unknown }
    let headerFields = Dictionary(
      httpResponse.allHeaderFields.compactMap { key, value in
        (key as? String).map { ($0, "\(value)") }
      },
      uniquingKeysWith: { first, _ in first }
    )
    if let error = HTTPError(statusCode: httpResponse.statusCode, headerFields: headerFields) {
      throw error
    }
    return data
  }

  private func urlRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
    guard
      var components = URLComponents(
        url: Self.baseURL.appending(path: path), resolvingAgainstBaseURL: false
      )
    else { throw HTTPError.invalidRequest }
    if !queryItems.isEmpty {
      components.queryItems = queryItems
      // `URLComponents` 는 `+` 를 인코딩하지 않는데 서버는 쿼리의 `+` 를 공백으로 읽는다.
      // 그대로 보내면 "c++" 가 "c" 로 검색되므로 직접 인코딩한다.
      components.percentEncodedQuery = components.percentEncodedQuery?
        .replacingOccurrences(of: "+", with: "%2B")
    }
    guard let url = components.url else { throw HTTPError.invalidRequest }

    var request = URLRequest(url: url)
    for (field, value) in Self.defaultHeaders {
      request.setValue(value, forHTTPHeaderField: field)
    }
    return request
  }
}

extension APIClientProtocol {
  /// `GET /search/repositories?q={keyword}&page={page}`. `page` 는 1부터 센다.
  ///
  /// `per_page` 를 보내지 않아 한 페이지는 API 기본값인 30개다. 화면의 다음 페이지 판단이 이 값에 기대므로,
  /// `per_page` 를 보내게 되면 함께 맞춰야 한다.
  func searchRepositories(keyword: String, page: Int) async throws -> SearchRepositoriesResponse {
    try await get(
      path: "search/repositories",
      queryItems: [
        URLQueryItem(name: "q", value: keyword),
        URLQueryItem(name: "page", value: String(page)),
      ]
    )
  }
}
