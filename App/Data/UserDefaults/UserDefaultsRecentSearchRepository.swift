import Foundation

/// `UserDefaults` 에 JSON 으로 저장하는 `RecentSearchRepository` 를 만든다.
/// 어떤 구현을 쓸지는 `Application` 이 정한다. (`Dependencies.swift`)
enum UserDefaultsRecentSearchRepository {
  /// - Parameter suiteName: `nil` 이면 `UserDefaults.standard` 를 쓴다.
  static func make(suiteName: String? = nil) -> RecentSearchRepository {
    let key = "recentSearches"
    // `UserDefaults` 는 `Sendable` 이 아니라서 붙잡아 두지 않고 쓸 때마다 얻는다.
    let userDefaults: @Sendable () -> UserDefaults = {
      UserDefaults(suiteName: suiteName) ?? .standard
    }
    return RecentSearchRepository(
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
