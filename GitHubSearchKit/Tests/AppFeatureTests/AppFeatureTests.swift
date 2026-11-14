import ComposableArchitecture
import Testing

@testable import AppFeature

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
