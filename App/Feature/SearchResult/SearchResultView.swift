import ComposableArchitecture
import SwiftUI

struct SearchResultView: View {
  @Bindable var store: StoreOf<SearchResultFeature>

  init(store: StoreOf<SearchResultFeature>) {
    self.store = store
  }

  var body: some View {
    content
      .navigationDestination(
        item: $store.scope(state: \.webPage, action: \.webPage)
      ) { webPageStore in
        RepositoryWebView(store: webPageStore)
      }
  }

  @ViewBuilder
  private var content: some View {
    switch store.phase {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    case .loaded where store.repositories.isEmpty, .failed:
      noticeView
    case .loaded:
      repositoryList
    }
  }

  /// 결과가 없거나 불러오지 못했을 때 목록 자리에 보여주는 안내와 "다시 시도"
  private var noticeView: some View {
    ContentUnavailableView {
      Text(store.notice ?? "")
        .font(.body)
    } actions: {
      Button("다시 시도") {
        store.send(.retryTapped)
      }
    }
  }

  private var repositoryList: some View {
    List {
      Section {
        ForEach(store.repositories) { repository in
          Button {
            store.send(.repositoryTapped(repository))
          } label: {
            RepositoryRow(repository: repository)
          }
          .buttonStyle(.plain)
          .onAppear {
            store.send(.repositoryAppeared(repository.id))
          }
        }
        nextPageFooter
      } header: {
        Text(store.totalCountText)
      }
    }
    .listStyle(.plain)
  }
}

extension SearchResultView {
  /// 목록 맨 아래. 다음 페이지를 불러오는 중이면 로딩 표시, 실패했으면 안내와 "다시 시도".
  @ViewBuilder
  fileprivate var nextPageFooter: some View {
    if store.nextPagePhase == .loading {
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        // 행이 재사용되면 멈춘 채로 보일 수 있어 페이지마다 새로 만든다.
        .id(store.loadedPageCount)
        .listRowSeparator(.hidden)
    } else if let notice = store.nextPageNotice {
      HStack {
        Text(notice)
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Spacer()
        Button("다시 시도") {
          store.send(.nextPageRetryTapped)
        }
        .buttonStyle(.borderless)
      }
      .listRowSeparator(.hidden)
    }
  }
}

private struct RepositoryRow: View {
  let repository: RepositoryItem

  var body: some View {
    HStack(spacing: 12) {
      AsyncImage(url: repository.avatarURL) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Color(.secondarySystemFill)
      }
      .frame(width: 44, height: 44)
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(repository.name)
          .font(.headline)
          .lineLimit(1)
        Text(repository.ownerLogin)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    // 글자가 없는 빈 곳을 눌러도 행이 선택되게 한다.
    .frame(maxWidth: .infinity, alignment: .leading)
    .contentShape(Rectangle())
  }
}
