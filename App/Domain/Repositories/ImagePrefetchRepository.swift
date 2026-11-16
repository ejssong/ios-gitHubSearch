import Dependencies
import DependenciesMacros
import Foundation

/// 이미지를 화면에 보이기 전에 미리 받아 두는 일의 인터페이스.
///
/// 어떤 캐시에 어떻게 받는지는 `Data` 의 구현이 맡고, 어떤 구현을 쓸지는 `Application` 이 정한다.
/// 언제 무엇을 미리 받을지는 이것을 쓰는 리듀서가 정한다.
@DependencyClient
struct ImagePrefetchRepository: Sendable {
  /// `urls` 의 이미지를 미리 받아 캐시에 넣는다. 끝나기를 기다리지 않는다.
  var prefetch: @Sendable (_ urls: [URL]) -> Void
  /// 진행 중인 미리 받기를 모두 멈춘다.
  var cancel: @Sendable () -> Void
}

extension ImagePrefetchRepository: TestDependencyKey {
  static let testValue = ImagePrefetchRepository()
}

extension DependencyValues {
  var imagePrefetchRepository: ImagePrefetchRepository {
    get { self[ImagePrefetchRepository.self] }
    set { self[ImagePrefetchRepository.self] = newValue }
  }
}
