import Dependencies
import DependenciesMacros

/// 최근 검색어 저장소의 인터페이스. 목록을 통째로 읽고 쓴다.
///
/// 어디에 저장하는지는 `Data` 의 구현이 맡고, 어떤 구현을 쓸지는 `Application` 이 정한다. 중복, 정렬, 개수 제한은 이것을 쓰는 리듀서가 정한다.
@DependencyClient
struct RecentSearchRepository: Sendable {
  /// 저장된 목록. 저장된 것이 없거나 읽을 수 없으면 빈 배열.
  var load: @Sendable () -> [RecentSearch] = { [] }
  var save: @Sendable (_ searches: [RecentSearch]) -> Void
}

extension RecentSearchRepository: TestDependencyKey {
  static let testValue = RecentSearchRepository()
}

extension DependencyValues {
  var recentSearchRepository: RecentSearchRepository {
    get { self[RecentSearchRepository.self] }
    set { self[RecentSearchRepository.self] = newValue }
  }
}
