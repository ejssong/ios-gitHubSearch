import ComposableArchitecture
import SearchFeature
import SwiftUI

public struct AppView: View {
  let store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  public var body: some View {
    SearchView(store: store.scope(state: \.search, action: \.search))
  }
}
