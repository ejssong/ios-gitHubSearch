import ComposableArchitecture
import Foundation
import Testing

@testable import GitHubSearch

@MainActor
struct RepositoryWebFeatureTests {
  private let url = URL(string: "https://github.com/apple/swift")!

  @Test
  func initialStateIsLoading() {
    let state = RepositoryWebFeature.State(url: url, title: "swift")

    #expect(state.isLoading)
  }

  @Test
  func pageLoadFinishedHidesLoading() async {
    let store = TestStore(initialState: RepositoryWebFeature.State(url: url, title: "swift")) {
      RepositoryWebFeature()
    }

    await store.send(.pageLoadFinished) {
      $0.isLoading = false
    }
  }

  /// 페이지 안에서 다른 링크로 이동하면 다시 로딩 표시가 나온다.
  @Test
  func pageLoadStartedShowsLoadingAgain() async {
    let store = TestStore(
      initialState: RepositoryWebFeature.State(url: url, title: "swift", isLoading: false)
    ) {
      RepositoryWebFeature()
    }

    await store.send(.pageLoadStarted) {
      $0.isLoading = true
    }
    await store.send(.pageLoadFinished) {
      $0.isLoading = false
    }
  }
}
