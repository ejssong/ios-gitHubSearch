// swift-tools-version: 6.0

import PackageDescription

// 의존 방향: AppFeature → SearchFeature → SearchResultFeature → Core
let package = Package(
  name: "GitHubSearchKit",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "AppFeature", targets: ["AppFeature"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      exact: "1.26.2"
    ),
    // TCA 가 이미 쓰는 패키지. Core 가 TCA 전체를 모르도록 직접 선언한다.
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "1.17.2"
    ),
  ],
  targets: [
    .target(
      name: "Core",
      dependencies: [
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .testTarget(name: "CoreTests", dependencies: ["Core"]),

    .target(
      name: "SearchResultFeature",
      dependencies: [
        "Core",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(name: "SearchResultFeatureTests", dependencies: ["SearchResultFeature"]),

    .target(
      name: "SearchFeature",
      dependencies: [
        "SearchResultFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(name: "SearchFeatureTests", dependencies: ["SearchFeature"]),

    .target(
      name: "AppFeature",
      dependencies: [
        "SearchFeature",
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
      ]
    ),
    .testTarget(name: "AppFeatureTests", dependencies: ["AppFeature"]),
  ],
  swiftLanguageModes: [.v6]
)
