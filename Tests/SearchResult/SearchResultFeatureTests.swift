import ComposableArchitecture
import Testing

@testable import GitHubSearch

@MainActor
struct SearchResultFeatureTests {
  @Test
  func initialState() {
    let store = TestStore(initialState: SearchResultFeature.State(keyword: "swift")) {
      SearchResultFeature()
    }

    #expect(store.state.keyword == "swift")
  }
}
