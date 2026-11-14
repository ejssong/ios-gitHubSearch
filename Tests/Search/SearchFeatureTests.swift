import ComposableArchitecture
import Testing

@testable import GitHubSearch

@MainActor
struct SearchFeatureTests {
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
    }

    await store.send(.searchSubmitted) {
      $0.result = SearchResultFeature.State(keyword: "swift")
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
}
