import ComposableArchitecture
import Testing

@testable import SearchFeature

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
