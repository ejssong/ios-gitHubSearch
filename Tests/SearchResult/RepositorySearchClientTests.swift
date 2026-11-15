import Dependencies
import Foundation
import Testing

@testable import GitHubSearch

struct RepositorySearchClientTests {
  /// 실제 응답에서 쓰는 필드와 쓰지 않는 필드를 섞은 본문
  private let body = Data(
    """
    {
      "total_count": 266714,
      "incomplete_results": false,
      "items": [
        {
          "id": 44838949,
          "node_id": "MDEwOlJlcG9zaXRvcnk0NDgzODk0OQ==",
          "name": "swift",
          "full_name": "apple/swift",
          "owner": {
            "login": "apple",
            "id": 10639145,
            "avatar_url": "https://avatars.githubusercontent.com/u/10639145?v=4"
          },
          "html_url": "https://github.com/apple/swift",
          "description": "The Swift Programming Language",
          "stargazers_count": 61000
        },
        {
          "id": 790019,
          "name": "SwiftyJSON",
          "owner": { "login": "SwiftyJSON", "avatar_url": null },
          "description": null
        }
      ]
    }
    """.utf8
  )

  @Test
  func searchDecodesTotalCountAndRepositories() async throws {
    let client = RepositorySearchClient.live(httpClient: HTTPClient(send: { [body] _ in body }))

    let page = try await client.search("swift", 1)

    #expect(
      page
        == RepositorySearchPage(
          totalCount: 266_714,
          repositories: [
            RepositoryItem(
              id: 44_838_949,
              name: "swift",
              ownerLogin: "apple",
              avatarURL: URL(string: "https://avatars.githubusercontent.com/u/10639145?v=4")
            ),
            RepositoryItem(id: 790_019, name: "SwiftyJSON", ownerLogin: "SwiftyJSON", avatarURL: nil),
          ]
        )
    )
  }

  @Test
  func searchSendsSearchRepositoriesRequest() async throws {
    let requests = LockIsolated<[HTTPRequest]>([])
    let client = RepositorySearchClient.live(
      httpClient: HTTPClient(send: { [body] request in
        requests.withValue { $0.append(request) }
        return body
      })
    )

    _ = try await client.search("swift ui", 3)

    #expect(requests.value == [GitHubAPI.searchRepositories(keyword: "swift ui", page: 3)])
  }

  @Test
  func searchPassesHTTPErrorThrough() async {
    let client = RepositorySearchClient.live(
      httpClient: HTTPClient(send: { _ in throw HTTPError.rateLimited })
    )

    await #expect(throws: HTTPError.rateLimited) {
      try await client.search("swift", 1)
    }
  }

  @Test
  func searchThrowsUnknownWhenBodyCannotBeDecoded() async {
    let client = RepositorySearchClient.live(
      httpClient: HTTPClient(send: { _ in Data(#"{"message":"unexpected"}"#.utf8) })
    )

    await #expect(throws: HTTPError.unknown) {
      try await client.search("swift", 1)
    }
  }

  @Test
  func itemWithoutOwnerIsKeptWithEmptyOwner() async throws {
    let body = Data(
      #"{"total_count": 1, "items": [{"id": 7, "name": "orphan", "owner": null}]}"#.utf8
    )
    let client = RepositorySearchClient.live(httpClient: HTTPClient(send: { _ in body }))

    let page = try await client.search("orphan", 1)

    #expect(
      page
        == RepositorySearchPage(
          totalCount: 1,
          repositories: [RepositoryItem(id: 7, name: "orphan", ownerLogin: "", avatarURL: nil)]
        )
    )
  }

  @Test
  func avatarURLThatCannotBeParsedBecomesNil() async throws {
    let body = Data(
      #"{"total_count": 1, "items": [{"id": 8, "name": "blank", "owner": {"login": "someone", "avatar_url": ""}}]}"#
        .utf8
    )
    let client = RepositorySearchClient.live(httpClient: HTTPClient(send: { _ in body }))

    let page = try await client.search("blank", 1)

    #expect(
      page.repositories
        == [RepositoryItem(id: 8, name: "blank", ownerLogin: "someone", avatarURL: nil)]
    )
  }

  /// 기본 클라이언트는 바꿔 끼운 `httpClient` 를 통해 요청한다.
  @Test
  func liveValueUsesHTTPClientDependency() async throws {
    let page = try await withDependencies {
      $0.httpClient.send = { [body] _ in body }
    } operation: {
      try await RepositorySearchClient.liveValue.search("swift", 1)
    }

    #expect(page.totalCount == 266_714)
  }
}
