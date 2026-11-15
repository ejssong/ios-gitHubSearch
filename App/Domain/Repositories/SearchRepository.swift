import Dependencies
import DependenciesMacros

/// 저장소 검색의 인터페이스. 리듀서는 이것만 본다.
///
/// 어디서 어떻게 가져오는지(GitHub API, HTTP, 응답 모양)는 `Data` 의 구현이 맡는다.
/// 화면 상태(로딩, 재시도)는 이것을 쓰는 리듀서가 정한다.
@DependencyClient
struct SearchRepository: Sendable {
  /// `page` 는 1부터 센다. 실패하면 `SearchError` 를 던진다.
  var search: @Sendable (_ keyword: String, _ page: Int) async throws -> RepositorySearchPage
}

extension SearchRepository: TestDependencyKey {
  static let testValue = SearchRepository()
}

extension DependencyValues {
  var searchRepository: SearchRepository {
    get { self[SearchRepository.self] }
    set { self[SearchRepository.self] = newValue }
  }
}
