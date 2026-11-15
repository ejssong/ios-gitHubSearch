import Foundation

/// 목록 한 줄에 보여줄 저장소
struct RepositoryItem: Equatable, Identifiable, Sendable {
  let id: Int
  /// 제목
  let name: String
  /// 설명
  let ownerLogin: String
  /// 썸네일. 주소가 없거나 잘못되면 `nil`.
  let avatarURL: URL?
  /// 저장소 페이지. 주소가 없거나 잘못되면 `nil` 이고, 그 항목은 눌러도 이동하지 않는다.
  let htmlURL: URL?

  init(id: Int, name: String, ownerLogin: String, avatarURL: URL?, htmlURL: URL? = nil) {
    self.id = id
    self.name = name
    self.ownerLogin = ownerLogin
    self.avatarURL = avatarURL
    self.htmlURL = htmlURL
  }
}

/// 검색 결과 한 페이지
struct RepositorySearchPage: Equatable, Sendable {
  /// 검색어에 맞는 전체 저장소 수
  let totalCount: Int
  let repositories: [RepositoryItem]

  init(totalCount: Int, repositories: [RepositoryItem]) {
    self.totalCount = totalCount
    self.repositories = repositories
  }
}
