import ComposableArchitecture

@Reducer
struct SearchFeature {
  @ObservableState
  struct State: Equatable {
    /// 검색창에 입력 중인 검색어
    var query: String
    /// 검색을 실행한 뒤의 결과 영역. `nil` 이면 결과를 보여주지 않는다.
    var result: SearchResultFeature.State?

    init(query: String = "", result: SearchResultFeature.State? = nil) {
      self.query = query
      self.result = result
    }
  }

  enum Action {
    case queryChanged(String)
    case searchSubmitted
    case result(SearchResultFeature.Action)
  }

  init() {}

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .queryChanged(query):
        state.query = query
        // 결과는 실행한 검색어에 대한 것이다. 검색어를 지우거나("취소" 포함) 고치면 결과 영역을 닫는다.
        if state.result?.keyword != query.trimmed {
          state.result = nil
        }
        return .none

      case .searchSubmitted:
        let keyword = state.query.trimmed
        guard !keyword.isEmpty else { return .none }
        state.result = SearchResultFeature.State(keyword: keyword)
        return .none

      case .result:
        return .none
      }
    }
    .ifLet(\.result, action: \.result) {
      SearchResultFeature()
    }
  }
}

extension String {
  fileprivate var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
