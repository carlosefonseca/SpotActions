// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CEFSpotifyCore",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7),
        .macOS(.v10_15),
        .tvOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CEFSpotifyCore",
            targets: ["CEFSpotifyCore"]),
        .library(
            name: "CEFSpotifyDoubles",
            targets: ["CEFSpotifyDoubles"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/groue/CombineExpectations.git", from: "0.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CEFSpotifyCore",
            dependencies: []),
        .target(
            name: "CEFSpotifyDoubles",
            dependencies: ["CEFSpotifyCore"]),
        .testTarget(
            name: "CEFSpotifyCoreTests",
            dependencies: ["CEFSpotifyCore", "CEFSpotifyDoubles", "CombineExpectations"]),
    ])
