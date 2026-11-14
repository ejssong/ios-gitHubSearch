import ComposableArchitecture
import Foundation
import Testing

@testable import GitHubSearch

@MainActor
struct SearchFeatureTests {
  private let now = Date(timeIntervalSince1970: 1_000_000)

  private func recent(_ keyword: String, secondsAgo: TimeInterval) -> RecentSearch {
    RecentSearch(keyword: keyword, searchedAt: now.addingTimeInterval(-secondsAgo))
  }

  @Test
  func typingDoesNotSearch() async {
    let store = TestStore(initialState: SearchFeature.State()) {
      SearchFeature()
    }

    await store.send(.queryChanged("swift")) {
      $0.query = "swift"
    }
  }

  @Test
  func submitShowsResultForTrimmedKeyword() async {
    let store = TestStore(initialState: SearchFeature.State(query: "  swift ")) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { _ in }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = [RecentSearch(keyword: "swift", searchedAt: now)]
    }
  }

  @Test
  func submitWithBlankQueryDoesNothing() async {
    let store = TestStore(initialState: SearchFeature.State(query: "   ")) {
      SearchFeature()
    }

    await store.send(.searchSubmitted)
  }

  @Test
  func clearingQueryClosesResult() async {
    let store = TestStore(
      initialState: SearchFeature.State(
        query: "swift", result: SearchResultFeature.State(keyword: "swift")
      )
    ) {
      SearchFeature()
    }

    // "취소" 는 검색어를 비운다.
    await store.send(.queryChanged("")) {
      $0.query = ""
      $0.result = nil
    }
  }

  @Test
  func editingQueryClosesResult() async {
    let store = TestStore(
      initialState: SearchFeature.State(
        query: "swift", result: SearchResultFeature.State(keyword: "swift")
      )
    ) {
      SearchFeature()
    }

    await store.send(.queryChanged("swiftui")) {
      $0.query = "swiftui"
      $0.result = nil
    }
  }

  @Test
  func sameQueryKeepsResult() async {
    let store = TestStore(
      initialState: SearchFeature.State(
        query: "swift", result: SearchResultFeature.State(keyword: "swift")
      )
    ) {
      SearchFeature()
    }

    await store.send(.queryChanged("swift"))
  }

  // MARK: - 최근 검색어

  @Test
  func viewAppearedLoadsNewestTenInDateOrder() async {
    // 저장소에 순서가 섞인 12개가 있어도 최신 10개만 날짜 내림차순으로 보여준다.
    let newestFirst = (1...12).map { recent("keyword\($0)", secondsAgo: TimeInterval($0)) }
    let stored = Array(newestFirst.reversed())
    let store = TestStore(initialState: SearchFeature.State()) {
      SearchFeature()
    } withDependencies: {
      $0.recentSearchClient.load = { stored }
    }

    await store.send(.viewAppeared) {
      $0.recentSearches = Array(newestFirst.prefix(10))
    }
  }

  @Test
  func submitSavesKeywordAndDateOnTop() async {
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(
        query: " swift ", recentSearches: [recent("tca", secondsAgo: 10)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [recent("swift", secondsAgo: 0), recent("tca", secondsAgo: 10)]
    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    #expect(saved.value == [expected])
  }

  @Test
  func duplicateIgnoringCaseAndSpacesMovesToTopWithLatestSpelling() async {
    let store = TestStore(
      initialState: SearchFeature.State(
        query: "  SwiftUI ",
        recentSearches: [recent("tca", secondsAgo: 10), recent("swiftui", secondsAgo: 20)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { _ in }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "SwiftUI")
      $0.recentSearches = [recent("SwiftUI", secondsAgo: 0), recent("tca", secondsAgo: 10)]
    }
  }

  @Test
  func eleventhSearchDropsOldest() async {
    let existing = (1...10).map { recent("keyword\($0)", secondsAgo: TimeInterval($0)) }
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(query: "swift", recentSearches: existing)
    ) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [recent("swift", secondsAgo: 0)] + existing.dropLast()
    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    #expect(saved.value.last?.count == 10)
    #expect(saved.value == [expected])
  }

  @Test
  func tappingRecentSearchFillsQueryAndSearches() async {
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(
        recentSearches: [recent("tca", secondsAgo: 10), recent("swift", secondsAgo: 20)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [recent("swift", secondsAgo: 0), recent("tca", secondsAgo: 10)]
    await store.send(.recentSearchTapped(recent("swift", secondsAgo: 20))) {
      $0.query = "swift"
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    #expect(saved.value == [expected])
  }

  @Test
  func deletingRecentSearchRemovesOnlyThatOneAndSaves() async {
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(
        recentSearches: [recent("tca", secondsAgo: 10), recent("swift", secondsAgo: 20)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    await store.send(.recentSearchDeleteTapped(recent("tca", secondsAgo: 10))) {
      $0.recentSearches = [recent("swift", secondsAgo: 20)]
    }
    #expect(saved.value == [[recent("swift", secondsAgo: 20)]])
  }

  @Test
  func clearingRecentSearchesRemovesAllAndSaves() async {
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(
        recentSearches: [recent("tca", secondsAgo: 10), recent("swift", secondsAgo: 20)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    await store.send(.recentSearchesClearTapped) {
      $0.recentSearches = []
    }
    #expect(saved.value == [[]])
  }

  /// 연달아 바꾸면 바꾼 순서대로 저장되어, 마지막 목록이 마지막에 남는다.
  @Test
  func consecutiveChangesAreSavedInOrder() async {
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(
        recentSearches: [recent("tca", secondsAgo: 10), recent("swift", secondsAgo: 20)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    await store.send(.recentSearchDeleteTapped(recent("tca", secondsAgo: 10))) {
      $0.recentSearches = [recent("swift", secondsAgo: 20)]
    }
    await store.send(.recentSearchDeleteTapped(recent("swift", secondsAgo: 20))) {
      $0.recentSearches = []
    }
    #expect(saved.value == [[recent("swift", secondsAgo: 20)], []])
  }
}
