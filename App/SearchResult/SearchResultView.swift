import ComposableArchitecture
import SwiftUI

struct SearchResultView: View {
  let store: StoreOf<SearchResultFeature>

  init(store: StoreOf<SearchResultFeature>) {
    self.store = store
  }

  var body: some View {
    if let notice = store.notice {
      ContentUnavailableView {
        Text(notice)
          .font(.body)
      } actions: {
        Button("다시 시도") {
          store.send(.retryTapped)
        }
      }
    } else if store.phase == .loading {
      ProgressView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      List {
        Section {
          ForEach(store.repositories) { repository in
            RepositoryRow(repository: repository)
          }
        } header: {
          Text(store.totalCountText)
        }
      }
      .listStyle(.plain)
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
  }
}
