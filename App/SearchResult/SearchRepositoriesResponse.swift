import Foundation

/// `GET /search/repositories` 응답(DTO). `RepositorySearchClient` 안에서만 쓰고 밖으로는 `RepositorySearchPage` 로 바꿔 넘긴다.
struct SearchRepositoriesResponse: Decodable, Equatable, Sendable {
  let totalCount: Int
  let items: [Item]

  struct Item: Decodable, Equatable, Sendable {
    let id: Int
    let name: String
    /// API 명세상 `null` 일 수 있다.
    let owner: Owner?
  }

  struct Owner: Decodable, Equatable, Sendable {
    let login: String
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
      case login
      case avatarURL = "avatar_url"
    }
  }

  enum CodingKeys: String, CodingKey {
    case totalCount = "total_count"
    case items
  }
}

extension SearchRepositoriesResponse {
  var page: RepositorySearchPage {
    RepositorySearchPage(
      totalCount: totalCount,
      repositories: items.map { item in
        RepositoryItem(
          id: item.id,
          name: item.name,
          // 소유자가 없는 항목 하나 때문에 페이지 전체를 버리지 않고, 설명과 썸네일만 비운다.
          ownerLogin: item.owner?.login ?? "",
          avatarURL: item.owner?.avatarURL.flatMap(URL.init(string:))
        )
      }
    )
  }
}
