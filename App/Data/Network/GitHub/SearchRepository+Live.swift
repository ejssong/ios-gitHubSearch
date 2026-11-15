import Dependencies
import Foundation

/// GitHub 검색 API 로 `SearchRepository` 를 구현한다.
///
/// - 요청은 `GitHubAPI` 가 만들고, 전송과 `HTTPError` 변환은 `HTTPClient` 가 한다.
/// - 여기서는 응답(DTO)을 `RepositorySearchPage` 로, `HTTPError` 를 `SearchError` 로 바꿔 넘긴다.
extension SearchRepository {
  static func live(httpClient: HTTPClient) -> Self {
    Self(search: { keyword, page in
      do {
        let request = GitHubAPI.searchRepositories(keyword: keyword, page: page)
        let response: SearchRepositoriesResponse = try await httpClient.send(request)
        return response.page
      } catch let error as HTTPError {
        throw SearchError(error)
      }
      // 취소(`CancellationError`)는 바꾸지 않고 그대로 넘겨 effect 취소가 동작하게 한다.
    })
  }
}

extension SearchError {
  /// 통신 오류를 화면에 알릴 이유로 바꾼다. 요청이 잘못된 경우는 사용자가 구분할 필요가 없어 `unknown` 으로 합친다.
  init(_ error: HTTPError) {
    switch error {
    case .network:
      self = .network
    case .rateLimited:
      self = .rateLimited
    case .invalidRequest, .unknown:
      self = .unknown
    }
  }
}

extension SearchRepository: DependencyKey {
  /// 호출할 때의 `httpClient` 의존성을 쓴다. HTTP 계층만 바꿔 끼워도 반영된다.
  static let liveValue = SearchRepository(search: { keyword, page in
    @Dependency(\.httpClient) var httpClient
    return try await live(httpClient: httpClient).search(keyword, page)
  })
}
