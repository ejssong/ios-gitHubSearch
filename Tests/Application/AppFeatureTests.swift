import ComposableArchitecture
import Testing

@testable import GitHubSearch

@MainActor
struct AppFeatureTests {
  @Test
  func initialState() {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    #expect(store.state == AppFeature.State())
  }
}
