import Foundation
import Testing

@testable import GitHubSearch

struct RecentSearchClientTests {
  @Test
  func loadReturnsEmptyWhenNothingSaved() {
    let suiteName = "RecentSearchClientTests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }

    #expect(RecentSearchClient.live(suiteName: suiteName).load() == [])
  }

  /// 앱을 다시 시작한 것처럼 새로 만든 클라이언트가 저장된 목록을 그대로 읽는다.
  @Test
  func savedSearchesAreLoadedByNewClient() {
    let suiteName = "RecentSearchClientTests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    let searches = [
      RecentSearch(keyword: "SwiftUI", searchedAt: Date(timeIntervalSince1970: 2_000)),
      RecentSearch(keyword: "tca", searchedAt: Date(timeIntervalSince1970: 1_000)),
    ]

    RecentSearchClient.live(suiteName: suiteName).save(searches)

    #expect(RecentSearchClient.live(suiteName: suiteName).load() == searches)
  }

  @Test
  func savingEmptyListClearsStoredSearches() {
    let suiteName = "RecentSearchClientTests.\(UUID().uuidString)"
    defer { UserDefaults.standard.removePersistentDomain(forName: suiteName) }
    let client = RecentSearchClient.live(suiteName: suiteName)

    client.save([RecentSearch(keyword: "swift", searchedAt: Date(timeIntervalSince1970: 1_000))])
    client.save([])

    #expect(RecentSearchClient.live(suiteName: suiteName).load() == [])
  }
}
