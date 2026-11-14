import ComposableArchitecture

@Reducer
struct SearchResultFeature {
  @ObservableState
  struct State: Equatable {
    /// 검색을 실행한 검색어
    let keyword: String

    init(keyword: String) {
      self.keyword = keyword
    }
  }

  enum Action {}

  init() {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
