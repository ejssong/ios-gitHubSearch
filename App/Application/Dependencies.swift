import Dependencies

// 앱이 실제로 쓸 구현을 고르는 곳. `Domain` 의 저장소 인터페이스에 `Data` 의 구현을 연결한다.
// `Feature` 는 인터페이스만 보고, `Data` 는 `Domain` 타입을 확장하지 않는다.

extension SearchRepository: DependencyKey {
  static let liveValue = RemoteSearchRepository.make(apiClient: SearchAPIClient())
}

extension RecentSearchRepository: DependencyKey {
  static let liveValue = UserDefaultsRecentSearchRepository.make()
}
