import Foundation
import Testing

@testable import GitHubSearch

struct GitHubAPITests {
  @Test
  func searchRepositoriesHasPathKeywordPageAndCommonHeaders() throws {
    let request = GitHubAPI.searchRepositories(keyword: "swift ui", page: 3)

    #expect(
      request
        == HTTPRequest(
          url: try #require(URL(string: "https://api.github.com/search/repositories")),
          queryItems: [
            URLQueryItem(name: "q", value: "swift ui"),
            URLQueryItem(name: "page", value: "3"),
          ],
          headers: ["Accept": "application/vnd.github+json"]
        )
    )
  }
}
