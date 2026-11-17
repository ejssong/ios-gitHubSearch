import ComposableArchitecture
import Foundation

/// 검색어 하나에 대한 결과 영역. 언제 요청하고 무엇을 보여줄지를 정한다.
/// 어디서 어떻게 가져오는지는 `SearchRepository` 의 구현이 맡고 여기서는 모른다.
@Reducer
struct SearchResultFeature {
  /// 나타난 행이 불러온 목록의 이 지점(%)을 지났으면 다음 페이지를 미리 요청한다.
  static let prefetchThresholdPercent = 70
  /// 한 페이지의 항목 수. 검색 API 의 기본값이다. 요청에 `per_page` 를 보내지 않는다.
  /// `per_page` 를 보내게 되면 이 값도 함께 맞춰야 한다.
  static let pageSize = 30
  /// GitHub 검색 API 가 돌려주는 결과의 상한
  static let maxResultCount = 1_000

  @ObservableState
  struct State: Equatable {
    /// 검색을 실행한 검색어
    let keyword: String
    var phase: Phase
    var repositories: [RepositoryItem]
    /// 검색어에 맞는 전체 저장소 수
    var totalCount: Int
    /// 지금까지 불러온 페이지 수
    var loadedPageCount: Int
    /// 더 불러올 페이지가 있는지. 전체 건수나 API 상한에 닿았거나 빈 페이지가 왔으면 `false`.
    var hasNextPage: Bool
    var nextPagePhase: NextPagePhase
    /// 눌러서 고른 저장소의 페이지. `nil` 이 아니면 WebView 화면이 push 되어 있다.
    @Presents var webPage: RepositoryWebFeature.State?

    init(
      keyword: String,
      phase: Phase = .loading,
      repositories: [RepositoryItem] = [],
      totalCount: Int = 0,
      loadedPageCount: Int = 0,
      hasNextPage: Bool = false,
      nextPagePhase: NextPagePhase = .idle,
      webPage: RepositoryWebFeature.State? = nil
    ) {
      self.keyword = keyword
      self.phase = phase
      self.repositories = repositories
      self.totalCount = totalCount
      self.loadedPageCount = loadedPageCount
      self.hasNextPage = hasNextPage
      self.nextPagePhase = nextPagePhase
      self.webPage = webPage
    }

    /// 예: "266,714개 저장소". 기기 설정과 상관없이 세 자리마다 쉼표를 찍는다.
    var totalCountText: String {
      "\(totalCount.groupedText)개 저장소"
    }

    /// 목록 대신 보여줄 안내 문구. 목록이나 로딩을 보여줄 때는 `nil`.
    var notice: String? {
      switch phase {
      case .loading:
        nil
      case .loaded:
        repositories.isEmpty ? "검색 결과가 없습니다." : nil
      case let .failed(error):
        error.message
      }
    }

    /// 다음 페이지를 불러오지 못했을 때 목록 맨 아래에 보여줄 안내 문구
    var nextPageNotice: String? {
      guard case let .failed(error) = nextPagePhase else { return nil }
      return error.message
    }
  }

  enum NextPagePhase: Equatable {
    case idle
    /// 다음 페이지를 불러오는 중. 목록 맨 아래에 로딩 표시를 보여준다.
    case loading
    case failed(SearchError)
  }

  enum Phase: Equatable {
    /// 첫 페이지를 불러오는 중
    case loading
    /// 불러오기를 마쳤다. `repositories` 가 비어 있으면 결과 0건이다.
    case loaded
    case failed(SearchError)
  }

  enum Action {
    /// 검색이 실행되었다. `SearchFeature` 가 결과 상태를 만든 직후 보낸다.
    case searchRequested
    case retryTapped
    case searchResponse(Result<RepositorySearchPage, SearchError>)
    case repositoryTapped(RepositoryItem)
    /// 행이 화면에 나타났다. 다음 페이지를 미리 불러올지는 리듀서가 정한다.
    case repositoryAppeared(RepositoryItem.ID)
    case nextPageResponse(Result<RepositorySearchPage, SearchError>)
    case nextPageRetryTapped
    /// push 된 WebView 화면의 액션. 뒤로 가면 `.dismiss` 가 온다.
    case webPage(PresentationAction<RepositoryWebFeature.Action>)
  }

  private enum CancelID { case search, nextPage }

  @Dependency(\.searchRepository) var searchRepository
  @Dependency(\.imagePrefetchRepository) var imagePrefetchRepository

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .searchRequested, .retryTapped:
        // 검색어만 남기고 처음 상태(첫 페이지 로딩 중)로 되돌린다.
        state = State(keyword: state.keyword)
        // 이전 목록의 썸네일을 미리 받던 것은 더 필요 없다.
        imagePrefetchRepository.cancel()
        // 이전 목록에 붙이려던 다음 페이지 요청은 버린다.
        return .merge(
          .cancel(id: CancelID.nextPage),
          firstPage(keyword: state.keyword)
        )

      case let .searchResponse(result):
        switch result {
        case let .success(page):
          state.phase = .loaded
          append(page, to: &state)
        case let .failure(error):
          state.phase = .failed(error)
        }
        return .none

      case let .repositoryAppeared(id):
        guard
          state.phase == .loaded, state.nextPagePhase == .idle, state.hasNextPage,
          let index = state.repositories.firstIndex(where: { $0.id == id }),
          (index + 1) * 100 >= state.repositories.count * Self.prefetchThresholdPercent
        else { return .none }
        return nextPage(state: &state)

      case .nextPageRetryTapped:
        // 실패한 뒤에는 스크롤만으로 다시 요청하지 않고, 버튼을 눌렀을 때만 다시 요청한다.
        guard case .failed = state.nextPagePhase else { return .none }
        return nextPage(state: &state)

      case let .nextPageResponse(result):
        switch result {
        case let .success(page):
          state.nextPagePhase = .idle
          let newRepositories = append(page, to: &state)
          // 새로 붙은 행이 없으면 행이 나타날 일도 없어 멈춘다. 바로 그다음 페이지를 요청한다.
          guard newRepositories.isEmpty, state.hasNextPage else { return .none }
          return nextPage(state: &state)
        case let .failure(error):
          state.nextPagePhase = .failed(error)
          return .none
        }

      case let .repositoryTapped(repository):
        // 보여줄 주소가 없는 항목은 이동하지 않는다.
        // 이미 페이지가 열려 있으면 바꾸지 않는다. 두 행을 동시에 누르면 제목과 내용이 어긋날 수 있다.
        guard state.webPage == nil, let url = repository.htmlURL else { return .none }
        state.webPage = RepositoryWebFeature.State(url: url, title: repository.name)
        return .none

      case .webPage:
        return .none
      }
    }
    .ifLet(\.$webPage, action: \.webPage) {
      RepositoryWebFeature()
    }
  }

  private func firstPage(keyword: String) -> Effect<Action> {
    .run { send in
      guard let result = await fetchPage(keyword: keyword, page: 1) else { return }
      await send(.searchResponse(result))
    }
    .cancellable(id: CancelID.search, cancelInFlight: true)
  }

  /// 다음 페이지를 요청하고 목록 맨 아래에 로딩 표시를 올린다.
  private func nextPage(state: inout State) -> Effect<Action> {
    state.nextPagePhase = .loading
    return .run { [keyword = state.keyword, page = state.loadedPageCount + 1] send in
      guard let result = await fetchPage(keyword: keyword, page: page) else { return }
      await send(.nextPageResponse(result))
    }
    .cancellable(id: CancelID.nextPage, cancelInFlight: true)
  }

  /// 한 페이지를 요청한다. 새 검색이나 화면 닫힘으로 취소된 요청은 결과를 알리지 않도록 `nil` 을 돌려준다.
  private func fetchPage(
    keyword: String, page: Int
  ) async -> Result<RepositorySearchPage, SearchError>? {
    do {
      return .success(try await searchRepository.search(keyword, page))
    } catch is CancellationError {
      return nil
    } catch {
      return .failure(error as? SearchError ?? .unknown)
    }
  }

  /// 받은 페이지를 목록 뒤에 붙이고 건수, 불러온 페이지 수, 다음 페이지 여부를 갱신한다.
  /// 첫 페이지는 빈 목록에 붙이는 것과 같아 첫 페이지와 다음 페이지가 함께 쓴다. 새로 붙은 항목을 돌려준다.
  /// 첫 페이지는 상태를 처음으로 되돌린 직후에만 요청한다는 전제에 기댄다. 되돌리지 않고 요청하면 이전 목록 뒤에 붙는다.
  @discardableResult
  private func append(_ page: RepositorySearchPage, to state: inout State) -> [RepositoryItem] {
    state.loadedPageCount += 1
    state.totalCount = page.totalCount
    state.hasNextPage = hasNextPage(after: page, loadedPageCount: state.loadedPageCount)
    // 페이지 사이에 순위가 바뀌면 같은 저장소가 다시 올 수 있다.
    let loadedIDs = Set(state.repositories.map(\.id))
    let newRepositories = page.repositories.filter { !loadedIDs.contains($0.id) }
    state.repositories += newRepositories
    prefetchThumbnails(of: newRepositories)
    return newRepositories
  }

  /// 방금 붙은 항목의 썸네일을 행이 화면에 나타나기 전에 미리 받아 둔다.
  /// effect 로 미루지 않고 바로 부른다. 새 검색의 `cancel` 다음에 그 검색의 `prefetch` 가 오는 순서를 지키기 위해서다.
  private func prefetchThumbnails(of repositories: [RepositoryItem]) {
    let urls = repositories.compactMap(\.avatarURL)
    guard !urls.isEmpty else { return }
    imagePrefetchRepository.prefetch(urls)
  }

  /// 빈 페이지가 왔거나, 전체 건수 또는 API 상한까지 불러왔으면 더 요청하지 않는다.
  private func hasNextPage(after page: RepositorySearchPage, loadedPageCount: Int) -> Bool {
    !page.repositories.isEmpty
      && loadedPageCount * Self.pageSize < min(page.totalCount, Self.maxResultCount)
  }
}
