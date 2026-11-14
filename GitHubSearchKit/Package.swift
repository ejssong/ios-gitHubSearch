// swift-tools-version: 6.0

import PackageDescription

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
    )
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
      ]
    )
  ],
  swiftLanguageModes: [.v6]
)
