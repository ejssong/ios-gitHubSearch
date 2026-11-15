import Foundation
import Testing

@testable import GitHubSearch

struct UserDefaultsRecentSearchRepositoryTests {
  @Test
  func loadReturnsEmptyWhenNothingSaved() {
    let suiteName = "UserDefaultsRecentSearchRepositoryTests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    #expect(UserDefaultsRecentSearchRepository.make(suiteName: suiteName).load() == [])
  }

  /// 앱을 다시 시작한 것처럼 새로 만든 저장소가 저장된 목록을 그대로 읽는다.
  @Test
  func savedSearchesAreLoadedByNewRepository() {
    let suiteName = "UserDefaultsRecentSearchRepositoryTests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    let searches = [
      RecentSearch(keyword: "SwiftUI", searchedAt: Date(timeIntervalSince1970: 2_000)),
      RecentSearch(keyword: "tca", searchedAt: Date(timeIntervalSince1970: 1_000)),
    ]

    UserDefaultsRecentSearchRepository.make(suiteName: suiteName).save(searches)

    #expect(UserDefaultsRecentSearchRepository.make(suiteName: suiteName).load() == searches)
  }

  @Test
  func savingEmptyListClearsStoredSearches() {
    let suiteName = "UserDefaultsRecentSearchRepositoryTests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    let repository = UserDefaultsRecentSearchRepository.make(suiteName: suiteName)

    repository.save([RecentSearch(keyword: "swift", searchedAt: Date(timeIntervalSince1970: 1_000))])
    repository.save([])

    #expect(UserDefaultsRecentSearchRepository.make(suiteName: suiteName).load() == [])
  }
}
