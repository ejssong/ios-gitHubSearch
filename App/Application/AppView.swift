import ComposableArchitecture
import SwiftUI

struct AppView: View {
  let store: StoreOf<AppFeature>

  init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  var body: some View {
    SearchView(store: store.scope(state: \.search, action: \.search))
  }
}
