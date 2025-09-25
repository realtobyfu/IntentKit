// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IntentKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16)
    ],
    products: [
        .library(
            name: "IntentKit",
            targets: ["IntentKitCore"]
        ),
        .library(
            name: "IntentKitCodeGen",
            targets: ["IntentKitCodeGen"]
        ),
        .executable(
            name: "intentkit-gen",
            targets: ["IntentKitCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "IntentKitCore",
            dependencies: [],
            path: "Sources/IntentKitCore"
        ),
        .target(
            name: "IntentKitCodeGen",
            dependencies: ["Yams"],
            path: "Sources/IntentKitCodeGen"
        ),
        .executableTarget(
            name: "IntentKitCLI",
            dependencies: [
                "IntentKitCodeGen",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/IntentKitCLI"
        ),
        .testTarget(
            name: "IntentKitCoreTests",
            dependencies: ["IntentKitCore"],
            path: "Tests/IntentKitCoreTests"
        ),
        .testTarget(
            name: "IntentKitCodeGenTests",
            dependencies: ["IntentKitCodeGen"],
            path: "Tests/IntentKitCodeGenTests"
        ),
        .testTarget(
            name: "IntentKitBenchmarks",
            dependencies: ["IntentKitCore"],
            path: "Tests/IntentKitBenchmarks"
        )
    ]
)
