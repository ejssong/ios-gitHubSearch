import ComposableArchitecture
import Testing

@testable import GitHubSearch

@MainActor
struct SearchResultFeatureTests {
  @Test
  func initialState() {
    let store = TestStore(initialState: SearchResultFeature.State()) {
      SearchResultFeature()
    }

    #expect(store.state == SearchResultFeature.State())
  }
}
