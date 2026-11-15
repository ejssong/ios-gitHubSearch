import ComposableArchitecture
import Foundation

@Reducer
struct SearchFeature {
  /// 저장하고 보여주는 최근 검색어의 최대 개수
  static let maxRecentSearchCount = 10

  @ObservableState
  struct State: Equatable {
    /// 검색창에 입력 중인 검색어
    var query: String
    /// 검색을 실행한 뒤의 결과 영역. `nil` 이면 결과를 보여주지 않는다.
    var result: SearchResultFeature.State?
    /// 최근 검색어. 날짜 내림차순이고 최대 `maxRecentSearchCount` 개다.
    var recentSearches: [RecentSearch]

    init(
      query: String = "",
      result: SearchResultFeature.State? = nil,
      recentSearches: [RecentSearch] = []
    ) {
      self.query = query
      self.result = result
      self.recentSearches = recentSearches
    }

    /// 입력 중에 보여줄 자동완성 후보. 대소문자를 무시하고 앞부분이 검색어와 일치하는 최근 검색어다.
    /// 검색어가 비어 있거나 결과를 보여주는 중이면 없다. 순서는 최근 검색어와 같은 날짜 내림차순이다.
    var suggestions: [RecentSearch] {
      let prefix = query.trimmed.lowercased()
      guard result == nil, !prefix.isEmpty else { return [] }
      return recentSearches.filter { $0.keyword.lowercased().hasPrefix(prefix) }
    }
  }

  enum Action {
    case viewAppeared
    case queryChanged(String)
    case searchSubmitted
    case recentSearchTapped(RecentSearch)
    case recentSearchDeleteTapped(RecentSearch)
    case recentSearchesClearTapped
    case suggestionTapped(RecentSearch)
    case result(SearchResultFeature.Action)
  }

  @Dependency(\.date.now) var now
  @Dependency(\.recentSearchClient) var recentSearchClient

  init() {}

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .viewAppeared:
        state.recentSearches = Array(
          recentSearchClient.load()
            .sorted { $0.searchedAt > $1.searchedAt }
            .prefix(Self.maxRecentSearchCount)
        )
        return .none

      case let .queryChanged(query):
        state.query = query
        // 결과는 실행한 검색어에 대한 것이다. 검색어를 지우거나("취소" 포함) 고치면 결과 영역을 닫는다.
        if state.result?.keyword != query.trimmed {
          state.result = nil
        }
        return .none

      case .searchSubmitted:
        return search(state.query, state: &state)

      // 최근 검색어든 자동완성이든 고른 검색어로 검색창을 채우고 검색한다.
      case let .recentSearchTapped(recentSearch), let .suggestionTapped(recentSearch):
        state.query = recentSearch.keyword
        return search(recentSearch.keyword, state: &state)

      case let .recentSearchDeleteTapped(recentSearch):
        state.recentSearches.removeAll { $0.id == recentSearch.id }
        return save(state.recentSearches)

      case .recentSearchesClearTapped:
        state.recentSearches = []
        return save(state.recentSearches)

      case .result:
        return .none
      }
    }
    .ifLet(\.result, action: \.result) {
      SearchResultFeature()
    }
  }

  /// 결과 영역을 열어 검색을 시작하고, 검색어를 최근 검색어 맨 위에 기록한다. 빈 검색어면 아무것도 하지 않는다.
  private func search(_ query: String, state: inout State) -> Effect<Action> {
    let keyword = query.trimmed
    guard !keyword.isEmpty else { return .none }
    state.result = SearchResultFeature.State(keyword: keyword)

    // 대소문자만 다른 검색어는 같은 것으로 보고, 마지막에 입력한 형태와 지금 시각으로 바꾼다.
    let recentSearch = RecentSearch(keyword: keyword, searchedAt: now)
    state.recentSearches.removeAll { $0.id == recentSearch.id }
    state.recentSearches.insert(recentSearch, at: 0)
    if state.recentSearches.count > Self.maxRecentSearchCount {
      state.recentSearches.removeLast(state.recentSearches.count - Self.maxRecentSearchCount)
    }
    return save(state.recentSearches)
      .merge(with: .send(.result(.searchRequested)))
  }

  /// 연달아 바꿔도 마지막 목록이 마지막에 쓰이도록, effect 로 미루지 않고 바로 저장한다.
  private func save(_ recentSearches: [RecentSearch]) -> Effect<Action> {
    recentSearchClient.save(recentSearches)
    return .none
  }
}

extension String {
  fileprivate var trimmed: String {
    trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
