import ComposableArchitecture

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var search = SearchFeature.State()

    init() {}
  }

  enum Action {
    case search(SearchFeature.Action)
  }

  init() {}

  var body: some ReducerOf<Self> {
    Scope(state: \.search, action: \.search) {
      SearchFeature()
    }
  }
}
