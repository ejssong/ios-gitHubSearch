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
      $0.repositorySearchClient.search = { [page] keyword, pageNumber in
        calls.withValue { $0.append("\(keyword)#\(pageNumber)") }
        return page
      }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = page.repositories
      $0.totalCount = 266_714
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
      $0.repositorySearchClient.search = { _, _ in
        RepositorySearchPage(totalCount: 0, repositories: [])
      }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
    }
    #expect(store.state.notice == "검색 결과가 없습니다.")
  }

  @Test
  func networkErrorShowsNotice() async {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.repositorySearchClient.search = { _, _ in throw HTTPError.network }
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
      $0.repositorySearchClient.search = { _, _ in throw HTTPError.rateLimited }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.failure) {
      $0.phase = .failed(.rateLimited)
    }
    #expect(store.state.notice == "요청이 많습니다. 잠시 후 다시 시도해 주세요.")
  }

  @Test
  func invalidRequestShowsGenericNotice() async {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.repositorySearchClient.search = { _, _ in throw HTTPError.invalidRequest }
    }

    await store.send(.searchRequested)
    await store.receive(\.searchResponse.failure) {
      $0.phase = .failed(.invalidRequest)
    }
    #expect(store.state.notice == "문제가 발생했습니다. 다시 시도해 주세요.")
  }

  @Test
  func errorOtherThanHTTPErrorBecomesUnknown() async {
    struct SomeError: Error {}
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    } withDependencies: {
      $0.repositorySearchClient.search = { _, _ in throw SomeError() }
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
      $0.repositorySearchClient.search = { [page] _, _ in page }
    }

    await store.send(.retryTapped) {
      $0.phase = .loading
    }
    await store.receive(\.searchResponse.success) {
      $0.phase = .loaded
      $0.repositories = page.repositories
      $0.totalCount = 266_714
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
      $0.repositorySearchClient.search = { _, _ in throw HTTPError.network }
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
      $0.repositorySearchClient.search = { [page] _, _ in
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
    }
    #expect(callCount.value == 2)
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
