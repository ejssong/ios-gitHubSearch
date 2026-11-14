import ComposableArchitecture
import SwiftUI

struct SearchResultView: View {
  let store: StoreOf<SearchResultFeature>

  init(store: StoreOf<SearchResultFeature>) {
    self.store = store
  }

  var body: some View {
    Color.clear
  }
}
