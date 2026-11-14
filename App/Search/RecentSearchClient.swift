import Dependencies
import DependenciesMacros
import Foundation

/// 최근 검색어 목록을 통째로 읽고 쓴다. 중복, 정렬, 개수 제한은 `SearchFeature` 가 정한다.
@DependencyClient
struct RecentSearchClient: Sendable {
  /// 저장된 목록. 저장된 것이 없거나 읽을 수 없으면 빈 배열.
  var load: @Sendable () -> [RecentSearch] = { [] }
  var save: @Sendable (_ searches: [RecentSearch]) -> Void
}

extension RecentSearchClient {
  /// - Parameter suiteName: `nil` 이면 `UserDefaults.standard` 를 쓴다.
  static func live(suiteName: String? = nil) -> Self {
    let key = "recentSearches"
    // `UserDefaults` 는 `Sendable` 이 아니라서 붙잡아 두지 않고 쓸 때마다 얻는다.
    let userDefaults: @Sendable () -> UserDefaults = {
      UserDefaults(suiteName: suiteName) ?? .standard
    }
    return Self(
      load: {
        guard let data = userDefaults().data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([RecentSearch].self, from: data)) ?? []
      },
      save: { searches in
        guard let data = try? JSONEncoder().encode(searches) else { return }
        userDefaults().set(data, forKey: key)
      }
    )
  }
}

extension RecentSearchClient: DependencyKey {
  static let liveValue = RecentSearchClient.live()
  static let testValue = RecentSearchClient()
}

extension DependencyValues {
  var recentSearchClient: RecentSearchClient {
    get { self[RecentSearchClient.self] }
    set { self[RecentSearchClient.self] = newValue }
  }
}
