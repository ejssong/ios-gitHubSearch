import ComposableArchitecture

@Reducer
struct SearchResultFeature {
  @ObservableState
  struct State: Equatable {
    init() {}
  }

  enum Action {}

  init() {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
