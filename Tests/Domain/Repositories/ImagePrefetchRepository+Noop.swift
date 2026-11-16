@testable import GitHubSearch

extension ImagePrefetchRepository {
  /// 아무것도 하지 않는다. 썸네일 미리 받기를 보지 않는 테스트에서 쓴다.
  static let noop = ImagePrefetchRepository(prefetch: { _ in }, cancel: {})
}
