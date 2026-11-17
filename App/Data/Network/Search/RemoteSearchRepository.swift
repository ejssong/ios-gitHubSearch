import Foundation

/// GitHub 검색 API 로 동작하는 `SearchRepository` 를 만든다.

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

  private static func searchError(from error: HTTPError) -> SearchError {
    switch error {
    case .network:
      .network
    case .unsuccessfulStatusCode(403), .unsuccessfulStatusCode(429):
      .rateLimited
    case .invalidRequest, .invalidResponse, .unsuccessfulStatusCode:
      .unknown
    }
  }
}
