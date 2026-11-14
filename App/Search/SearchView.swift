import ComposableArchitecture
import SwiftUI

struct SearchView: View {
  @Bindable var store: StoreOf<SearchFeature>

  init(store: StoreOf<SearchFeature>) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Search")
        .searchable(
          text: $store.query.sending(\.queryChanged),
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: "저장소 검색"
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) {
          store.send(.searchSubmitted)
        }
    }
  }

  @ViewBuilder
  private var content: some View {
    if let resultStore = store.scope(state: \.result, action: \.result) {
      SearchResultView(store: resultStore)
    } else {
      Color.clear
    }
  }
}
