import ComposableArchitecture
import Foundation

/// 검색어 하나에 대한 결과 영역. 언제 요청하고 무엇을 보여줄지를 정한다.
/// URL, JSON, DTO 는 `RepositorySearchClient` 가 맡고 여기서는 모른다.
@Reducer
struct SearchResultFeature {
  @ObservableState
  struct State: Equatable {
    /// 검색을 실행한 검색어
    let keyword: String
    var phase: Phase
    var repositories: [RepositoryItem]
    /// 검색어에 맞는 전체 저장소 수
    var totalCount: Int

    init(
      keyword: String,
      phase: Phase = .loading,
      repositories: [RepositoryItem] = [],
      totalCount: Int = 0
    ) {
      self.keyword = keyword
      self.phase = phase
      self.repositories = repositories
      self.totalCount = totalCount
    }

    /// 예: "266,714개 저장소". 기기 설정과 상관없이 세 자리마다 쉼표를 찍는다.
    var totalCountText: String {
      let count = totalCount.formatted(.number.grouping(.automatic).locale(Locale(identifier: "en_US")))
      return "\(count)개 저장소"
    }

    /// 목록 대신 보여줄 안내 문구. 목록이나 로딩을 보여줄 때는 `nil`.
    var notice: String? {
      switch phase {
      case .loading:
        nil
      case .loaded:
        repositories.isEmpty ? "검색 결과가 없습니다." : nil
      case .failed(.network):
        "네트워크 연결을 확인해 주세요."
      case .failed(.rateLimited):
        "요청이 많습니다. 잠시 후 다시 시도해 주세요."
      case .failed(.invalidRequest), .failed(.unknown):
        "문제가 발생했습니다. 다시 시도해 주세요."
      }
    }
  }

  enum Phase: Equatable {
    /// 첫 페이지를 불러오는 중
    case loading
    /// 불러오기를 마쳤다. `repositories` 가 비어 있으면 결과 0건이다.
    case loaded
    case failed(HTTPError)
  }

  enum Action {
    /// 검색이 실행되었다. `SearchFeature` 가 결과 상태를 만든 직후 보낸다.
    case searchRequested
    case retryTapped
    case searchResponse(Result<RepositorySearchPage, HTTPError>)
  }

  private enum CancelID { case search }

  @Dependency(\.repositorySearchClient) var repositorySearchClient

  init() {}

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .searchRequested, .retryTapped:
        state.phase = .loading
        state.repositories = []
        state.totalCount = 0
        return .run { [keyword = state.keyword] send in
          do {
            let page = try await repositorySearchClient.search(keyword, 1)
            await send(.searchResponse(.success(page)))
          } catch is CancellationError {
            // 새 검색이나 화면 닫힘으로 취소된 요청은 결과를 알리지 않는다.
          } catch let error as HTTPError {
            await send(.searchResponse(.failure(error)))
          } catch {
            await send(.searchResponse(.failure(.unknown)))
          }
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)

      case let .searchResponse(.success(page)):
        state.phase = .loaded
        state.repositories = page.repositories
        state.totalCount = page.totalCount
        return .none

      case let .searchResponse(.failure(error)):
        state.phase = .failed(error)
        return .none
      }
    }
  }
}
