import ComposableArchitecture
import Foundation

/// 저장소 페이지 하나를 보여주는 화면의 상태. 어떤 주소를 보여주고, 지금 불러오는 중인지를 안다.
/// `WKWebView` 는 `RepositoryWebView` 가 다루고 여기서는 모른다.
@Reducer
struct RepositoryWebFeature {
  @ObservableState
  struct State: Equatable {
    /// 보여줄 저장소 페이지
    let url: URL
    /// 화면 제목 (저장소 이름)
    let title: String
    /// 페이지를 불러오는 중이면 로딩 표시를 보여준다.
    var isLoading: Bool

    init(url: URL, title: String, isLoading: Bool = true) {
      self.url = url
      self.title = title
      self.isLoading = isLoading
    }
  }

  enum Action {
    case pageLoadStarted
    /// 불러오기가 끝났다. 실패로 끝난 경우도 포함한다.
    case pageLoadFinished
  }

  init() {}

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .pageLoadStarted:
        state.isLoading = true
        return .none

      case .pageLoadFinished:
        state.isLoading = false
        return .none
      }
    }
  }
}
