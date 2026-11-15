import Foundation

/// GitHub 검색 API 로 동작하는 `SearchRepository` 를 만든다.
///
/// - 경로와 쿼리는 `APIClientProtocol.searchRepositories(keyword:page:)` 가 정하고, 전송과 `HTTPError` 변환은 그 구현(`SearchAPIClient`)이 한다.
/// - 여기서는 응답(DTO)을 `RepositorySearchPage` 로, `HTTPError` 를 `SearchError` 로 바꿔 넘긴다.
/// - 어떤 구현을 쓸지는 `Application` 이 정한다. (`Dependencies.swift`)
enum RemoteSearchRepository {
  static func make(apiClient: some APIClientProtocol) -> SearchRepository {
    SearchRepository(search: { keyword, page in
      do {
        return try await apiClient.searchRepositories(keyword: keyword, page: page).page
      } catch let error as HTTPError {
        throw searchError(from: error)
      }
      // 취소(`CancellationError`)는 바꾸지 않고 그대로 넘겨 effect 취소가 동작하게 한다.
    })
  }

  /// 통신 오류를 화면에 알릴 이유로 바꾼다. 요청이 잘못된 경우는 사용자가 구분할 필요가 없어 `unknown` 으로 합친다.
  private static func searchError(from error: HTTPError) -> SearchError {
    switch error {
    case .network:
      .network
    case .rateLimited:
      .rateLimited
    case .invalidRequest, .unknown:
      .unknown
    }
  }
}
