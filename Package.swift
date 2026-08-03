// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TonConnect",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(name: "TonConnectCore", targets: ["TonConnectCore"]),
        .library(name: "TonConnectConformance", targets: ["TonConnectConformance"]),
        .library(name: "TonConnectJSCoreEngine", targets: ["TonConnectJSCoreEngine"]),
        .library(name: "TonConnectTransport", targets: ["TonConnectTransport"]),
        .library(name: "TonConnectUI", targets: ["TonConnectUI"]),
        .library(name: "TonConnectSDK", targets: ["TonConnectSDK"]),
        .library(name: "TonConnectNativeEngine", targets: ["TonConnectNativeEngine"]),
    ],
    dependencies: [
        // Adds `swift package generate-documentation`. It is a build-time plugin:
        // it produces no code, and nothing it brings is linked into a consumer.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "TonConnectCore"),
        .target(name: "TonConnectConformance", dependencies: ["TonConnectCore"]),
        .target(
            name: "TonConnectJSCoreEngine",
            dependencies: ["TonConnectCore", "TonConnectTransport"],
            resources: [.copy("Resources/tonconnect-sdk.bundle.js")]
        ),
        .target(name: "TonConnectTransport"),
        .target(
            name: "TonConnectUI",
            dependencies: ["TonConnectCore"],
            resources: [
                .copy("WalletsList/Resources/wallets-v2.snapshot.json"),
                .process("Resources/Media.xcassets"),
            ]
        ),
        .target(
            name: "TonConnectSDK",
            dependencies: ["TonConnectCore", "TonConnectNativeEngine"]
        ),
        .target(
            name: "CTweetNacl",
            path: "Sources/CTweetNacl",
            publicHeadersPath: "include"
        ),
        .target(
            name: "TonConnectNativeEngine",
            dependencies: ["TonConnectCore", "CTweetNacl", "TonConnectTransport"]
        ),
        .target(name: "TonConnectTestSupport", dependencies: ["TonConnectCore"]),
        // Test targets
        .testTarget(
            name: "TonConnectCoreTests",
            dependencies: ["TonConnectCore", "TonConnectConformance"]
        ),
        .testTarget(
            name: "TonConnectJSCoreEngineTests",
            dependencies: ["TonConnectJSCoreEngine", "TonConnectTestSupport", "TonConnectConformance"]
        ),
        .testTarget(
            name: "TonConnectTransportTests",
            dependencies: ["TonConnectTransport", "TonConnectTestSupport"]
        ),
        .testTarget(
            name: "TonConnectUITests",
            dependencies: ["TonConnectUI", "TonConnectCore"]
        ),
        .testTarget(
            name: "TonConnectNativeEngineTests",
            dependencies: ["TonConnectNativeEngine", "TonConnectTestSupport", "TonConnectConformance"],
            resources: [
                .copy("Fixtures/session-crypto-vectors.json"),
                .copy("Fixtures/nacl.js"),
            ]
        )
    ]
)
