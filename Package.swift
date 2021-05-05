// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "SpotifyAPIServer",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(
            url: "https://github.com/vapor/vapor.git",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/Peter-Schorn/SpotifyAPI.git",
            .branch("proxy-token-server")
        )
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "SpotifyAPI", package: "SpotifyAPI")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release
                // configuration. Despite the use of the `.unsafeFlags`
                // construct required by SwiftPM, this flag is recommended for
                // Release builds. See
                // <https://github.com/swift-server/guides#building-for-production>
                // for details.
                .unsafeFlags(
                    ["-cross-module-optimization"],
                    .when(configuration: .release)
                )
            ]
        ),
        .target(
            name: "Run",
            dependencies: [
                .target(name: "App"),
                .product(name: "SpotifyAPI", package: "SpotifyAPI")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ]
        )
    ]
)
