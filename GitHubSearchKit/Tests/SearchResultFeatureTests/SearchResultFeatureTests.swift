import ComposableArchitecture
import Testing

@testable import SearchResultFeature

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
