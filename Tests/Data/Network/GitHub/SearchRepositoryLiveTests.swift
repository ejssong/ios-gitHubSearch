import Dependencies
import Foundation
import Testing

@testable import GitHubSearch

struct SearchRepositoryLiveTests {
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
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { [body] _ in body }))

    let page = try await repository.search("swift", 1)

    #expect(
      page
        == RepositorySearchPage(
          totalCount: 266_714,
          repositories: [
            RepositoryItem(
              id: 44_838_949,
              name: "swift",
              ownerLogin: "apple",
              avatarURL: URL(string: "https://avatars.githubusercontent.com/u/10639145?v=4"),
              htmlURL: URL(string: "https://github.com/apple/swift")
            ),
            RepositoryItem(id: 790_019, name: "SwiftyJSON", ownerLogin: "SwiftyJSON", avatarURL: nil),
          ]
        )
    )
  }

  @Test
  func searchSendsSearchRepositoriesRequest() async throws {
    let requests = LockIsolated<[HTTPRequest]>([])
    let repository = SearchRepository.live(
      httpClient: HTTPClient(send: { [body] request in
        requests.withValue { $0.append(request) }
        return body
      })
    )

    _ = try await repository.search("swift ui", 3)

    #expect(requests.value == [GitHubAPI.searchRepositories(keyword: "swift ui", page: 3)])
  }

  /// 통신 오류는 화면에 알릴 이유(`SearchError`)로 바뀌어 나온다.
  @Test(arguments: [
    (HTTPError.network, SearchError.network),
    (HTTPError.rateLimited, SearchError.rateLimited),
    (HTTPError.invalidRequest, SearchError.unknown),
    (HTTPError.unknown, SearchError.unknown),
  ])
  func searchConvertsHTTPErrorToSearchError(httpError: HTTPError, expected: SearchError) async {
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { _ in throw httpError }))

    await #expect(throws: expected) {
      try await repository.search("swift", 1)
    }
  }

  @Test
  func searchThrowsUnknownWhenBodyCannotBeDecoded() async {
    let repository = SearchRepository.live(
      httpClient: HTTPClient(send: { _ in Data(#"{"message":"unexpected"}"#.utf8) })
    )

    await #expect(throws: SearchError.unknown) {
      try await repository.search("swift", 1)
    }
  }

  /// 취소는 오류로 바꾸지 않고 그대로 넘긴다.
  @Test
  func searchPassesCancellationThrough() async {
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { _ in throw CancellationError() }))

    await #expect(throws: CancellationError.self) {
      try await repository.search("swift", 1)
    }
  }

  @Test
  func itemWithoutOwnerIsKeptWithEmptyOwner() async throws {
    let body = Data(
      #"{"total_count": 1, "items": [{"id": 7, "name": "orphan", "owner": null}]}"#.utf8
    )
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { _ in body }))

    let page = try await repository.search("orphan", 1)

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
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { _ in body }))

    let page = try await repository.search("blank", 1)

    #expect(
      page.repositories
        == [RepositoryItem(id: 8, name: "blank", ownerLogin: "someone", avatarURL: nil)]
    )
  }

  @Test
  func htmlURLThatCannotBeParsedBecomesNil() async throws {
    let body = Data(
      #"{"total_count": 1, "items": [{"id": 9, "name": "blank", "owner": {"login": "someone"}, "html_url": ""}]}"#
        .utf8
    )
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { _ in body }))

    let page = try await repository.search("blank", 1)

    #expect(page.repositories.map(\.htmlURL) == [nil])
  }

  /// `html_url` 이 없거나 `null` 이거나 웹 주소가 아니면 `htmlURL` 은 `nil` 이다.
  @Test(arguments: [
    #""name": "a""#,
    #""name": "a", "html_url": null"#,
    #""name": "a", "html_url": "github.com/apple/swift""#,
    #""name": "a", "html_url": "file:///etc/hosts""#,
    #""name": "a", "html_url": "abc def""#,
  ])
  func htmlURLIsNilUnlessItIsWebAddress(fields: String) async throws {
    let body = Data(#"{"total_count": 1, "items": [{"id": 1, \#(fields)}]}"#.utf8)
    let repository = SearchRepository.live(httpClient: HTTPClient(send: { _ in body }))

    let page = try await repository.search("a", 1)

    #expect(page.repositories.map(\.htmlURL) == [nil])
  }

  /// 기본 구현은 바꿔 끼운 `httpClient` 를 통해 요청한다.
  @Test
  func liveValueUsesHTTPClientDependency() async throws {
    let page = try await withDependencies {
      $0.httpClient.send = { [body] _ in body }
    } operation: {
      try await SearchRepository.liveValue.search("swift", 1)
    }

    #expect(page.totalCount == 266_714)
  }
}
