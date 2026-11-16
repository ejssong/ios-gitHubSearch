import Testing

@testable import GitHubSearch

struct SearchErrorTests {
  @Test
  func messageForEachError() {
    #expect(SearchError.network.message == "네트워크 연결을 확인해 주세요.")
    #expect(SearchError.rateLimited.message == "요청이 많습니다. 잠시 후 다시 시도해 주세요.")
    #expect(SearchError.unknown.message == "문제가 발생했습니다. 다시 시도해 주세요.")
  }
}
