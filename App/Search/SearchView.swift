import ComposableArchitecture
import SwiftUI

struct SearchView: View {
  let store: StoreOf<SearchFeature>

  init(store: StoreOf<SearchFeature>) {
    self.store = store
  }

  var body: some View {
    Color.clear
  }
}
