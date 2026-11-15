import Dependencies
import DependenciesMacros
import Foundation

/// 저장소 검색. 리듀서가 보는 창구다.
///
/// - 요청은 `GitHubAPI` 가 만들고, 전송과 `HTTPError` 변환은 `HTTPClient` 가 한다.
/// - 여기서는 응답(DTO)을 화면용 모델(`RepositorySearchPage`)로 바꿔 넘긴다. `HTTPError` 는 그대로 넘긴다.
/// - 화면 상태(로딩, 재시도, 안내 문구)는 `SearchResultFeature` 가 정한다.
@DependencyClient
struct RepositorySearchClient: Sendable {
  /// `page` 는 1부터 센다. 실패하면 `HTTPError` 를 던진다.
  var search: @Sendable (_ keyword: String, _ page: Int) async throws -> RepositorySearchPage
}

extension RepositorySearchClient {
  static func live(httpClient: HTTPClient) -> Self {
    Self(search: { keyword, page in
      let request = GitHubAPI.searchRepositories(keyword: keyword, page: page)
      let response: SearchRepositoriesResponse = try await httpClient.send(request)
      return response.page
    })
  }
}

extension RepositorySearchClient: DependencyKey {
  /// 호출할 때의 `httpClient` 의존성을 쓴다. HTTP 계층만 바꿔 끼워도 반영된다.
  static let liveValue = RepositorySearchClient(search: { keyword, page in
    @Dependency(\.httpClient) var httpClient
    return try await live(httpClient: httpClient).search(keyword, page)
  })
  static let testValue = RepositorySearchClient()
}

extension DependencyValues {
  var repositorySearchClient: RepositorySearchClient {
    get { self[RepositorySearchClient.self] }
    set { self[RepositorySearchClient.self] = newValue }
  }
}
