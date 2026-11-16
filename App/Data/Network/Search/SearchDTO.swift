import Foundation

/// `GET /search/repositories` 응답(DTO). `SearchRepository` 구현 안에서만 쓰고 밖으로는 `RepositorySearchPage` 로 바꿔 넘긴다.
struct SearchDTO: Decodable, Equatable, Sendable {
  let totalCount: Int
  let items: [Item]

  struct Item: Decodable, Equatable, Sendable {
    let id: Int
    let name: String
    /// API 명세상 `null` 일 수 있다.
    let owner: Owner?
    let htmlURL: String?

    enum CodingKeys: String, CodingKey {
      case id, name, owner
      case htmlURL = "html_url"
    }
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

extension SearchDTO {
  /// WebView 로 열 수 있는 주소만 남긴다. `URL(string:)` 은 scheme 이 없거나 `file:` 인 문자열도 받아들이기 때문이다.
  private static func webPageURL(_ string: String) -> URL? {
    guard
      let url = URL(string: string),
      let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
      url.host() != nil
    else { return nil }
    return url
  }

  var page: RepositorySearchPage {
    RepositorySearchPage(
      totalCount: totalCount,
      repositories: items.map { item in
        RepositoryItem(
          id: item.id,
          name: item.name,
          // 소유자가 없는 항목 하나 때문에 페이지 전체를 버리지 않고, 설명과 썸네일만 비운다.
          ownerLogin: item.owner?.login ?? "",
          avatarURL: item.owner?.avatarURL.flatMap(URL.init(string:)),
          htmlURL: item.htmlURL.flatMap(Self.webPageURL)
        )
      }
    )
  }
}
