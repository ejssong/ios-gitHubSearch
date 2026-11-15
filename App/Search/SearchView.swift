import ComposableArchitecture
import SwiftUI

struct SearchView: View {
  @Bindable var store: StoreOf<SearchFeature>

  init(store: StoreOf<SearchFeature>) {
    self.store = store
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle("Search")
        .searchable(
          text: $store.query.sending(\.queryChanged),
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: "저장소 검색"
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit(of: .search) {
          store.send(.searchSubmitted)
        }
    }
    .onAppear {
      store.send(.viewAppeared)
    }
  }

  @ViewBuilder
  private var content: some View {
    if let resultStore = store.scope(state: \.result, action: \.result) {
      SearchResultView(store: resultStore)
    } else if store.query.isEmpty, !store.recentSearches.isEmpty {
      recentSearchList
    } else if !store.suggestions.isEmpty {
      suggestionList
    } else {
      Color.clear
    }
  }

  private var suggestionList: some View {
    List(store.suggestions) { suggestion in
      Button {
        store.send(.suggestionTapped(suggestion))
      } label: {
        HStack {
          Text(suggestion.keyword)
            .lineLimit(1)
          Spacer()
          Text(suggestion.searchedDateText())
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
    .listStyle(.plain)
  }

  private var recentSearchList: some View {
    List {
      Section {
        ForEach(store.recentSearches) { recentSearch in
          HStack(spacing: 12) {
            Button {
              store.send(.recentSearchTapped(recentSearch))
            } label: {
              HStack {
                Text(recentSearch.keyword)
                  .lineLimit(1)
                Spacer()
                Text(recentSearch.searchedDateText())
                  .font(.subheadline)
                  .foregroundStyle(.secondary)
              }
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 한 행에 버튼이 둘이라, 행 전체가 아니라 각 버튼이 따로 눌리도록 스타일을 지정한다.
            Button {
              store.send(.recentSearchDeleteTapped(recentSearch))
            } label: {
              Image(systemName: "xmark")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("\(recentSearch.keyword) 삭제")
          }
        }
      } header: {
        HStack {
          Text("최근 검색")
          Spacer()
          Button("전체삭제") {
            store.send(.recentSearchesClearTapped)
          }
          .font(.subheadline)
        }
      }
    }
    .listStyle(.plain)
  }
}
