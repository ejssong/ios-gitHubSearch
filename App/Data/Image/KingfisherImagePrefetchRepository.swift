import Dependencies
import Foundation
import Kingfisher

/// Kingfisher 의 `ImagePrefetcher` 로 동작하는 `ImagePrefetchRepository` 를 만든다.
///
/// 받은 이미지는 Kingfisher 기본 캐시(메모리와 디스크)에 들어간다. 화면의 `KFImage` 도 같은 주소와 기본 옵션을 쓰므로,
/// 미리 받아 둔 이미지는 다시 내려받지 않고 바로 보인다. 어떤 구현을 쓸지는 `Application` 이 정한다. (`Dependencies.swift`)
enum KingfisherImagePrefetchRepository {
  static func make() -> ImagePrefetchRepository {
    // 멈출 수 있도록 진행 중인 것만 붙잡아 둔다. 끝나면 스스로 빠진다.
    let running = LockIsolated<[UUID: ImagePrefetcher]>([:])

    return ImagePrefetchRepository(
      prefetch: { urls in
        let id = UUID()
        let prefetcher = ImagePrefetcher(
          urls: urls,
          completionHandler: { _, _, _ in
            running.withValue { $0[id] = nil }
          }
        )
        // 등록과 시작을 한 번에 한다. 그 사이에 다른 스레드의 `cancel` 이 끼어들어 먼저 멈추면
        // Kingfisher 가 "멈춘 것을 다시 시작했다"고 본다.
        running.withValue {
          $0[id] = prefetcher
          prefetcher.start()
        }
      },
      cancel: {
        let prefetchers = running.withValue { running in
          defer { running = [:] }
          return Array(running.values)
        }
        prefetchers.forEach { $0.stop() }
      }
    )
  }
}
