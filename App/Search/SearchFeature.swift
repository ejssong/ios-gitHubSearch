import ComposableArchitecture

@Reducer
struct SearchFeature {
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
