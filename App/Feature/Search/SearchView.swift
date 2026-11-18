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
        dismissKeyboard()
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
              dismissKeyboard()
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

  /// 지금 입력을 받는 곳(이 화면에서는 검색창)의 포커스를 풀어 키보드를 내린다. 검색어는 검색창에 그대로 남는다.
  ///
  /// 액션을 보내기 전에 부른다. 조합 중인 글자가 있으면 포커스가 풀릴 때 확정되면서 `queryChanged` 가 오는데,
  /// 그것이 고른 검색어보다 나중에 오면 방금 연 결과가 닫힌다.
  /// 키보드의 "검색" 키로 실행하면 시스템이 내려 주지만, 목록의 항목을 눌러 실행할 때는 직접 내려야
  /// 결과 목록이 가려지지 않는다. `dismissSearch` 는 검색어까지 지우고, `searchFocused` 는 iOS 18 부터라 쓰지 않는다.
  private func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
    )
  }
}
