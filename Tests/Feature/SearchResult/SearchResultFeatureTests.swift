import ComposableArchitecture
import Foundation
import Testing

@testable import GitHubSearch

@MainActor
struct SearchResultFeatureTests {
  private let page = RepositorySearchPage(
    totalCount: 266_714,
    repositories: [
      RepositoryItem(
        id: 1, name: "swift", ownerLogin: "apple",
        avatarURL: URL(string: "https://example.com/apple.png")
      ),
      RepositoryItem(id: 2, name: "SwiftyJSON", ownerLogin: "SwiftyJSON", avatarURL: nil),
    ]
  )

  @Test
  func initialStateIsLoading() {
    let state = SearchResultFeature.State(keyword: "swift")

    #expect(state.phase == .loading)
    #expect(state.repositories.isEmpty)
    #expect(state.notice == nil)
  }

  @Test
  func searchRequestedLoadsFirstPageOfKeyword() async {
    let calls = LockIsolated<[String]>([])
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { [page] keyword, pageNumber in
        calls.withValue { $0.append("\(keyword)#\(pageNumber)") }
        return page
      }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = page.repositories
      $0.totalCount = 266_714
      $0.loadedPageCount = 1
      $0.hasNextPage = true
    }
    #expect(calls.value == ["swift#1"])
    #expect(store.state.notice == nil)
    #expect(store.state.totalCountText == "266,714개 저장소")
  }

  @Test
  func noResultsShowsEmptyNotice() async {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "zzzz")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in
        RepositorySearchPage(totalCount: 0, repositories: [])
      }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.loadedPageCount = 1
    }
    #expect(store.state.notice == "검색 결과가 없습니다.")
  }

  @Test
  func networkErrorShowsNotice() async {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in throw SearchError.network }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.failure) {
      $0.phase = .failed(.network)
    }
    #expect(store.state.notice == "네트워크 연결을 확인해 주세요.")
  }

  @Test
  func rateLimitShowsNotice() async {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in throw SearchError.rateLimited }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.failure) {
      $0.phase = .failed(.rateLimited)
    }
    #expect(store.state.notice == "요청이 많습니다. 잠시 후 다시 시도해 주세요.")
  }

  @Test
  func errorOtherThanSearchErrorBecomesUnknown() async {
    struct SomeError: Error {}
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in throw SomeError() }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.failure) {
      $0.phase = .failed(.unknown)
    }
    #expect(store.state.notice == "문제가 발생했습니다. 다시 시도해 주세요.")
  }

  @Test
  func retryAfterFailureLoadsAgain() async {
    let store = TestStore(
      initialState: SearchResultFeature.State(keyword: "swift", phase: .failed(.network))
    ) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { [page] _, _ in page }
    }

    await store.send(.retryTapped) {
      $0.phase = .loading
    }
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = page.repositories
      $0.totalCount = 266_714
      $0.loadedPageCount = 1
      $0.hasNextPage = true
    }
  }

  @Test
  func retryClearsPreviousResultsWhileLoading() async {
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: page.repositories, totalCount: 266_714
      )
    ) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in throw SearchError.network }
    }

    await store.send(.retryTapped) {
      $0.phase = .loading
      $0.repositories = []
      $0.totalCount = 0
    }
    await store.receive(\.searchResponse.failure) {
      $0.phase = .failed(.network)
    }
  }

  /// 응답이 오기 전에 다시 요청하면 앞선 요청은 취소되고 마지막 요청의 결과만 반영된다.
  @Test
  func newRequestCancelsRequestInFlight() async {
    let callCount = LockIsolated(0)
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { [page] _, _ in
        let call = callCount.withValue { count in
          count += 1
          return count
        }
        if call == 1 { try await Task.never() }
        return page
      }
    }

    await store.send(.searchRequested)
    await store.send(.retryTapped)
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = page.repositories
      $0.totalCount = 266_714
      $0.loadedPageCount = 1
      $0.hasNextPage = true
    }
    #expect(callCount.value == 2)
  }

  // MARK: - 저장소 선택

  private let swift = RepositoryItem(
    id: 1, name: "swift", ownerLogin: "apple", avatarURL: nil,
    htmlURL: URL(string: "https://github.com/apple/swift")
  )

  private var swiftPage: RepositoryWebFeature.State {
    RepositoryWebFeature.State(url: URL(string: "https://github.com/apple/swift")!, title: "swift")
  }

  @Test
  func tappingRepositoryOpensItsPage() async {
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: [swift], totalCount: 1
      )
    ) {
      SearchResultFeature()
    }

    await store.send(.repositoryTapped(swift)) {
      $0.webPage = RepositoryWebFeature.State(
        url: URL(string: "https://github.com/apple/swift")!, title: "swift"
      )
    }
  }

  @Test
  func tappingRepositoryWithoutPageURLDoesNothing() async {
    let noPage = RepositoryItem(id: 2, name: "orphan", ownerLogin: "", avatarURL: nil)
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: [noPage], totalCount: 1
      )
    ) {
      SearchResultFeature()
    }

    await store.send(.repositoryTapped(noPage))
  }

  /// 두 행을 거의 동시에 눌러도 먼저 연 페이지가 유지된다.
  @Test
  func tappingAnotherRepositoryWhilePageIsOpenDoesNothing() async {
    let other = RepositoryItem(
      id: 3, name: "swift-nio", ownerLogin: "apple", avatarURL: nil,
      htmlURL: URL(string: "https://github.com/apple/swift-nio")
    )
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: [swift, other], totalCount: 2,
        webPage: swiftPage
      )
    ) {
      SearchResultFeature()
    }

    await store.send(.repositoryTapped(other))
  }

  @Test
  func goingBackClosesPage() async {
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: [swift], totalCount: 1,
        webPage: swiftPage
      )
    ) {
      SearchResultFeature()
    }

    await store.send(.webPage(.dismiss)) {
      $0.webPage = nil
    }
  }

  /// push 된 화면의 액션은 그 화면의 상태에 반영된다.
  @Test
  func pageActionsUpdatePageState() async {
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: [swift], totalCount: 1,
        webPage: swiftPage
      )
    ) {
      SearchResultFeature()
    }

    await store.send(.webPage(.presented(.pageLoadFinished))) {
      $0.webPage?.isLoading = false
    }
  }

  @Test
  func retryClosesPage() async {
    let store = TestStore(
      initialState: SearchResultFeature.State(
        keyword: "swift", phase: .loaded, repositories: [swift], totalCount: 1,
        webPage: swiftPage
      )
    ) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { [swift] _, _ in
        RepositorySearchPage(totalCount: 1, repositories: [swift])
      }
    }

    await store.send(.retryTapped) {
      $0.phase = .loading
      $0.repositories = []
      $0.totalCount = 0
      $0.webPage = nil
    }
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = [swift]
      $0.totalCount = 1
      $0.loadedPageCount = 1
    }
  }

  // MARK: - 다음 페이지

  /// `range` 의 숫자를 id 로 하는 저장소들
  private func items(_ range: ClosedRange<Int>) -> [RepositoryItem] {
    range.map { RepositoryItem(id: $0, name: "repo\($0)", ownerLogin: "owner", avatarURL: nil) }
  }

  /// 첫 페이지(1...30)를 불러온 상태
  private func loadedFirstPage(totalCount: Int = 100) -> SearchResultFeature.State {
    SearchResultFeature.State(
      keyword: "swift", phase: .loaded, repositories: items(1...30), totalCount: totalCount,
      loadedPageCount: 1, hasNextPage: true
    )
  }

  /// 30개 중 21번째 행이 70% 지점이다.
  @Test
  func rowPastThresholdRequestsNextPageAndAppendsIt() async {
    let calls = LockIsolated<[String]>([])
    let secondPage = RepositorySearchPage(totalCount: 100, repositories: items(31...60))
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { keyword, page in
        calls.withValue { $0.append("\(keyword)#\(page)") }
        return secondPage
      }
    }

    await store.send(.repositoryAppeared(21)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.repositories = items(1...60)
    }
    #expect(calls.value == ["swift#2"])
  }

  @Test
  func rowBeforeThresholdDoesNotRequestNextPage() async {
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    }

    await store.send(.repositoryAppeared(1))
    await store.send(.repositoryAppeared(20))
  }

  /// 목록이 길어지면 기준 지점도 비율에 따라 뒤로 간다. 60개면 42번째 행부터다.
  @Test
  func thresholdMovesWithLoadedCount() async {
    var state = loadedFirstPage()
    state.repositories = items(1...60)
    state.loadedPageCount = 2
    let thirdPage = RepositorySearchPage(totalCount: 100, repositories: items(61...90))
    let store = TestStore(initialState: state) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in thirdPage }
    }

    await store.send(.repositoryAppeared(41))
    await store.send(.repositoryAppeared(42)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 3
      $0.repositories = items(1...90)
    }
  }

  @Test
  func rowsAppearingWhileLoadingDoNotRequestAgain() async {
    let callCount = LockIsolated(0)
    // 응답을 붙잡아 두었다가, 행이 더 나타난 뒤에 돌려준다.
    let (responses, respond) = AsyncStream.makeStream(of: RepositorySearchPage.self)
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in
        callCount.withValue { $0 += 1 }
        for await page in responses { return page }
        throw CancellationError()
      }
    }

    await store.send(.repositoryAppeared(25)) {
      $0.nextPagePhase = .loading
    }
    await store.send(.repositoryAppeared(26))
    await store.send(.repositoryAppeared(30))
    respond.yield(RepositorySearchPage(totalCount: 100, repositories: items(31...60)))
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.repositories = items(1...60)
    }
    #expect(callCount.value == 1)
  }

  @Test
  func firstPageCoveringAllResultsHasNoNextPage() async {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { [items = items(1...30)] _, _ in
        RepositorySearchPage(totalCount: 30, repositories: items)
      }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = items(1...30)
      $0.totalCount = 30
      $0.loadedPageCount = 1
    }
    await store.send(.repositoryAppeared(30))
  }

  @Test
  func reachingTotalCountStopsRequesting() async {
    let lastPage = RepositorySearchPage(totalCount: 45, repositories: items(31...45))
    let store = TestStore(initialState: loadedFirstPage(totalCount: 45)) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in lastPage }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.hasNextPage = false
      $0.repositories = items(1...45)
    }
    await store.send(.repositoryAppeared(45))
  }

  /// 전체 건수가 더 많아도 API 가 돌려주는 1,000건(34페이지)까지만 요청한다.
  @Test
  func reachingAPILimitStopsRequesting() async {
    var state = loadedFirstPage(totalCount: 266_714)
    state.repositories = items(1...990)
    state.loadedPageCount = 33
    let lastPage = RepositorySearchPage(totalCount: 266_714, repositories: items(991...1_000))
    let store = TestStore(initialState: state) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in lastPage }
    }

    await store.send(.repositoryAppeared(990)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 34
      $0.hasNextPage = false
      $0.repositories = items(1...1_000)
    }
    await store.send(.repositoryAppeared(1_000))
  }

  @Test
  func emptyPageStopsRequesting() async {
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in
        RepositorySearchPage(totalCount: 100, repositories: [])
      }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.hasNextPage = false
    }
    await store.send(.repositoryAppeared(30))
  }

  /// 페이지 사이에 순위가 바뀌어 같은 저장소가 다시 와도 한 번만 보여준다.
  @Test
  func repositoriesAlreadyLoadedAreNotAppendedAgain() async {
    let overlapping = RepositorySearchPage(totalCount: 100, repositories: items(29...58))
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in overlapping }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.repositories = items(1...58)
    }
  }

  /// 새로 붙은 행이 없으면 행이 나타날 일이 없으므로, 바로 그다음 페이지를 요청한다.
  @Test
  func pageWithOnlyLoadedRepositoriesRequestsFollowingPage() async {
    let calls = LockIsolated<[Int]>([])
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { [first = items(1...30), third = items(31...60)] _, page in
        calls.withValue { $0.append(page) }
        return RepositorySearchPage(totalCount: 100, repositories: page == 2 ? first : third)
      }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.loadedPageCount = 2
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 3
      $0.repositories = items(1...60)
    }
    #expect(calls.value == [2, 3])
  }

  /// 실패하면 목록은 그대로 두고 맨 아래에 안내를 보여준다. 스크롤만으로는 다시 요청하지 않는다.
  @Test
  func nextPageFailureKeepsListAndDoesNotRetryOnScroll() async {
    let callCount = LockIsolated(0)
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in
        callCount.withValue { $0 += 1 }
        throw SearchError.rateLimited
      }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.failure) {
      $0.nextPagePhase = .failed(.rateLimited)
    }
    #expect(store.state.nextPageNotice == "요청이 많습니다. 잠시 후 다시 시도해 주세요.")
    #expect(store.state.notice == nil)

    await store.send(.repositoryAppeared(29))
    await store.send(.repositoryAppeared(30))
    #expect(callCount.value == 1)
  }

  @Test
  func retryAfterNextPageFailureRequestsSamePageAgain() async {
    let calls = LockIsolated<[Int]>([])
    var state = loadedFirstPage()
    state.nextPagePhase = .failed(.network)
    let secondPage = RepositorySearchPage(totalCount: 100, repositories: items(31...60))
    let store = TestStore(initialState: state) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, page in
        calls.withValue { $0.append(page) }
        return secondPage
      }
    }

    await store.send(.nextPageRetryTapped) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.repositories = items(1...60)
    }
    #expect(calls.value == [2])
  }

  /// 전체 건수는 마지막으로 받은 응답의 값을 따른다.
  @Test
  func nextPageUpdatesTotalCount() async {
    let secondPage = RepositorySearchPage(totalCount: 120, repositories: items(31...60))
    let store = TestStore(initialState: loadedFirstPage(totalCount: 100)) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in secondPage }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.success) {
      $0.nextPagePhase = .idle
      $0.loadedPageCount = 2
      $0.totalCount = 120
      $0.repositories = items(1...60)
    }
  }

  @Test
  func nextPageErrorOtherThanSearchErrorBecomesUnknown() async {
    struct SomeError: Error {}
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, _ in throw SomeError() }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.receive(\.nextPageResponse.failure) {
      $0.nextPagePhase = .failed(.unknown)
    }
  }

  @Test
  func unknownRowAppearingDoesNothing() async {
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    }

    await store.send(.repositoryAppeared(999))
  }

  /// 첫 페이지를 다시 불러오는 중에는 다음 페이지를 요청하지 않는다.
  @Test
  func rowAppearingWhileFirstPageIsLoadingDoesNothing() async {
    var state = loadedFirstPage()
    state.phase = .loading
    let store = TestStore(initialState: state) {
      SearchResultFeature()
    }

    await store.send(.repositoryAppeared(30))
  }

  @Test
  func nextPageRetryDoesNothingUnlessFailed() async {
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    }

    await store.send(.nextPageRetryTapped)
  }

  /// 새 검색을 하면 페이지 상태가 처음으로 돌아가고, 붙이려던 다음 페이지 응답은 반영되지 않는다.
  @Test
  func newSearchCancelsNextPageInFlight() async {
    let fresh = RepositorySearchPage(totalCount: 2, repositories: items(101...102))
    let store = TestStore(initialState: loadedFirstPage()) {
      SearchResultFeature()
    } withDependencies: {
      $0.searchRepository.search = { _, page in
        if page == 2 { try await Task.never() }
        return fresh
      }
    }

    await store.send(.repositoryAppeared(30)) {
      $0.nextPagePhase = .loading
    }
    await store.send(.searchRequested) {
      $0.phase = .loading
      $0.repositories = []
      $0.totalCount = 0
      $0.loadedPageCount = 0
      $0.hasNextPage = false
      $0.nextPagePhase = .idle
    }
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = items(101...102)
      $0.totalCount = 2
      $0.loadedPageCount = 1
    }
  }

  @Test
  func totalCountTextGroupsDigits() {
    #expect(SearchResultFeature.State(keyword: "a", totalCount: 0).totalCountText == "0개 저장소")
    #expect(SearchResultFeature.State(keyword: "a", totalCount: 999).totalCountText == "999개 저장소")
    #expect(
      SearchResultFeature.State(keyword: "a", totalCount: 1_234_567).totalCountText
        == "1,234,567개 저장소"
    )
  }
}
