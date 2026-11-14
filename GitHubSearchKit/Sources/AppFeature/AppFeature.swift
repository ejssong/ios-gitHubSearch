import ComposableArchitecture
import SearchFeature

@Reducer
public struct AppFeature {
  @ObservableState
  public struct State: Equatable {
    public var search = SearchFeature.State()

    public init() {}
  }

  public enum Action {
    case search(SearchFeature.Action)
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Scope(state: \.search, action: \.search) {
      SearchFeature()
    }
  }
}
