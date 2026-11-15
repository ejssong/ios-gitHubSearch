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

  /// 검색을 실행하면 결과 영역에 요청이 전달되고 응답이 돌아온다.
  private func receiveSearch(_ store: TestStoreOf<SearchFeature>) async {
    await store.receive(\.result.searchRequested)
    await store.receive(\.result.searchResponse.success) {
      $0.result?.phase = .loaded
      $0.result?.loadedPageCount = 1
    }
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
      $0.repositorySearchClient.search = { _, _ in RepositorySearchPage(totalCount: 0, repositories: []) }
      $0.recentSearchClient.save = { _ in }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = [RecentSearch(keyword: "swift", searchedAt: now)]
    }
    await receiveSearch(store)
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
      $0.repositorySearchClient.search = { _, _ in RepositorySearchPage(totalCount: 0, repositories: []) }
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [recent("swift", secondsAgo: 0), recent("tca", secondsAgo: 10)]
    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    await receiveSearch(store)
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
      $0.repositorySearchClient.search = { _, _ in RepositorySearchPage(totalCount: 0, repositories: []) }
      $0.recentSearchClient.save = { _ in }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "SwiftUI")
      $0.recentSearches = [recent("SwiftUI", secondsAgo: 0), recent("tca", secondsAgo: 10)]
    }
    await receiveSearch(store)
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
      $0.repositorySearchClient.search = { _, _ in RepositorySearchPage(totalCount: 0, repositories: []) }
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [recent("swift", secondsAgo: 0)] + existing.dropLast()
    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    await receiveSearch(store)
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
      $0.repositorySearchClient.search = { _, _ in RepositorySearchPage(totalCount: 0, repositories: []) }
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [recent("swift", secondsAgo: 0), recent("tca", secondsAgo: 10)]
    await store.send(.recentSearchTapped(recent("swift", secondsAgo: 20))) {
      $0.query = "swift"
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    await receiveSearch(store)
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

  /// 결과가 떠 있는 상태에서 같은 검색어를 다시 제출해도 처음부터 다시 검색한다.
  @Test
  func submittingSameKeywordSearchesAgain() async {
    let repository = RepositoryItem(id: 1, name: "swift", ownerLogin: "apple", avatarURL: nil)
    let store = TestStore(
      initialState: SearchFeature.State(
        query: "swift",
        result: SearchResultFeature.State(
          keyword: "swift", phase: .loaded, repositories: [repository], totalCount: 1
        ),
        recentSearches: [recent("swift", secondsAgo: 10)]
      )
    ) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { _ in }
      $0.repositorySearchClient.search = { _, _ in
        RepositorySearchPage(totalCount: 1, repositories: [repository])
      }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = [recent("swift", secondsAgo: 0)]
    }
    await store.receive(\.result.searchRequested)
    await store.receive(\.result.searchResponse.success) {
      $0.result?.phase = .loaded
      $0.result?.repositories = [repository]
      $0.result?.totalCount = 1
      $0.result?.loadedPageCount = 1
    }
  }

  /// 응답이 오기 전에 검색어를 지우면 요청이 취소되고 결과가 반영되지 않는다.
  @Test
  func clearingQueryWhileSearchingCancelsRequest() async {
    let store = TestStore(initialState: SearchFeature.State(query: "swift")) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { _ in }
      $0.repositorySearchClient.search = { _, _ in try await Task.never() }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = [recent("swift", secondsAgo: 0)]
    }
    await store.receive(\.result.searchRequested)
    await store.send(.queryChanged("")) {
      $0.query = ""
      $0.result = nil
    }
    // 남은 effect 가 있으면 TestStore 가 실패로 알린다.
  }

  /// 응답이 오기 전에 같은 검색어를 다시 제출하면 앞선 요청은 취소되고 마지막 요청만 반영된다.
  @Test
  func resubmittingWhileSearchingKeepsOnlyLastRequest() async {
    let callCount = LockIsolated(0)
    let store = TestStore(initialState: SearchFeature.State(query: "swift")) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.recentSearchClient.save = { _ in }
      $0.repositorySearchClient.search = { _, _ in
        let call = callCount.withValue { count in
          count += 1
          return count
        }
        if call == 1 { try await Task.never() }
        return RepositorySearchPage(totalCount: 0, repositories: [])
      }
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = [recent("swift", secondsAgo: 0)]
    }
    await store.receive(\.result.searchRequested)
    await store.send(.searchSubmitted)
    await receiveSearch(store)
    #expect(callCount.value == 2)
  }

  // MARK: - 자동완성

  private var recentsForSuggestions: [RecentSearch] {
    [
      recent("SwiftUI", secondsAgo: 10),
      recent("tca", secondsAgo: 20),
      recent("swift", secondsAgo: 30),
      recent("awesome-swift", secondsAgo: 40),
    ]
  }

  /// 앞부분이 일치하는 최근 검색어만, 날짜 내림차순 그대로 나온다. 중간에만 들어 있는 것은 빠진다.
  @Test
  func typingShowsRecentSearchesWithMatchingPrefix() async {
    let store = TestStore(
      initialState: SearchFeature.State(recentSearches: recentsForSuggestions)
    ) {
      SearchFeature()
    }

    await store.send(.queryChanged("swi")) {
      $0.query = "swi"
    }
    #expect(
      store.state.suggestions == [recent("SwiftUI", secondsAgo: 10), recent("swift", secondsAgo: 30)]
    )
  }

  @Test
  func suggestionsIgnoreCaseAndSurroundingSpaces() {
    let state = SearchFeature.State(query: "  SWIFTU ", recentSearches: recentsForSuggestions)

    #expect(state.suggestions == [recent("SwiftUI", secondsAgo: 10)])
  }

  @Test
  func suggestionsIncludeExactMatch() {
    let state = SearchFeature.State(query: "tca", recentSearches: recentsForSuggestions)

    #expect(state.suggestions == [recent("tca", secondsAgo: 20)])
  }

  @Test
  func noSuggestionsWhenNothingMatches() {
    let state = SearchFeature.State(query: "kotlin", recentSearches: recentsForSuggestions)

    #expect(state.suggestions.isEmpty)
  }

  @Test(arguments: ["", "   "])
  func noSuggestionsForBlankQuery(query: String) {
    let state = SearchFeature.State(query: query, recentSearches: recentsForSuggestions)

    #expect(state.suggestions.isEmpty)
  }

  @Test
  func noSuggestionsWhileResultIsShown() {
    let state = SearchFeature.State(
      query: "swift",
      result: SearchResultFeature.State(keyword: "swift"),
      recentSearches: recentsForSuggestions
    )

    #expect(state.suggestions.isEmpty)
  }

  /// 결과를 보다가 검색어를 고치면 결과가 닫히고, 방금 검색한 검색어가 후보 맨 위에 나온다.
  @Test
  func editingQueryAfterSearchShowsSuggestionsAgain() async {
    let store = TestStore(
      initialState: SearchFeature.State(
        query: "swift",
        result: SearchResultFeature.State(keyword: "swift", phase: .loaded),
        recentSearches: [recent("swift", secondsAgo: 0), recent("SwiftUI", secondsAgo: 10)]
      )
    ) {
      SearchFeature()
    }
    #expect(store.state.suggestions.isEmpty)

    await store.send(.queryChanged("swif")) {
      $0.query = "swif"
      $0.result = nil
    }
    #expect(
      store.state.suggestions == [recent("swift", secondsAgo: 0), recent("SwiftUI", secondsAgo: 10)]
    )
  }

  @Test
  func tappingSuggestionFillsQueryAndSearches() async {
    let saved = LockIsolated<[[RecentSearch]]>([])
    let store = TestStore(
      initialState: SearchFeature.State(query: "sw", recentSearches: recentsForSuggestions)
    ) {
      SearchFeature()
    } withDependencies: {
      $0.date.now = now
      $0.repositorySearchClient.search = { _, _ in RepositorySearchPage(totalCount: 0, repositories: []) }
      $0.recentSearchClient.save = { searches in saved.withValue { $0.append(searches) } }
    }

    let expected = [
      recent("swift", secondsAgo: 0),
      recent("SwiftUI", secondsAgo: 10),
      recent("tca", secondsAgo: 20),
      recent("awesome-swift", secondsAgo: 40),
    ]
    await store.send(.suggestionTapped(recent("swift", secondsAgo: 30))) {
      $0.query = "swift"
      $0.result = SearchResultFeature.State(keyword: "swift")
      $0.recentSearches = expected
    }
    await receiveSearch(store)
    #expect(saved.value == [expected])
    #expect(store.state.suggestions.isEmpty)
  }
}
