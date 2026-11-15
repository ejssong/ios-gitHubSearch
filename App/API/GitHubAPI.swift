import Foundation

/// GitHub REST API 의 요청을 한곳에서 만든다. 서버 주소, 공통 헤더, 각 endpoint 의 경로와 쿼리를 안다.
/// 응답 모양(DTO)과 화면용 모델로의 변환은 그 endpoint 를 쓰는 Feature 가 맡는다.
enum GitHubAPI {
  /// 고정된 문자열이라 실패하지 않는다.
  static let baseURL = URL(string: "https://api.github.com")!

  /// 모든 요청에 붙이는 헤더. 인증 없이 호출한다.
  static let defaultHeaders = ["Accept": "application/vnd.github+json"]

  /// `GET /search/repositories?q={keyword}&page={page}`. `page` 는 1부터 센다.
  static func searchRepositories(keyword: String, page: Int) -> HTTPRequest {
    request(
      path: "search/repositories",
      queryItems: [
        URLQueryItem(name: "q", value: keyword),
        URLQueryItem(name: "page", value: String(page)),
      ]
    )
  }

  private static func request(path: String, queryItems: [URLQueryItem]) -> HTTPRequest {
    HTTPRequest(
      url: baseURL.appending(path: path),
      queryItems: queryItems,
      headers: defaultHeaders
    )
  }
}
