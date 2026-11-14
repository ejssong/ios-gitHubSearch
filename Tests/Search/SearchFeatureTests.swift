import ComposableArchitecture
import Testing

@testable import GitHubSearch

@MainActor
struct SearchFeatureTests {
  @Test
  func initialState() {
    let store = TestStore(initialState: SearchFeature.State()) {
      SearchFeature()
    }

    #expect(store.state == SearchFeature.State())
  }
}
