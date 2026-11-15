import Dependencies
import Foundation

/// `UserDefaults` 에 JSON 으로 저장해 `RecentSearchRepository` 를 구현한다.
extension RecentSearchRepository {
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

extension RecentSearchRepository: DependencyKey {
  static let liveValue = RecentSearchRepository.live()
}
