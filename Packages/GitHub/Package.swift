// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GitHub",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GitHubData", targets: [
            "GitHubData"
        ]),
        .library(name: "GitHubDomain", targets: [
            "GitHubDomain"
        ]),
        .library(name: "WebhookServer", targets: [
            "WebhookServer"
        ])
    ],
    dependencies: [
        .package(path: "../Keychain"),
        .package(path: "../Networking"),
        .package(url: "https://github.com/Kitura/Swift-JWT", from: "4.0.0"),
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.21.0"))
    ],
    targets: [
        .target(name: "GitHubData", dependencies: [
            "GitHubDomain",
            .product(name: "Keychain", package: "Keychain"),
            .product(name: "NetworkingDomain", package: "Networking")
        ]),
        .target(name: "GitHubDomain", dependencies: [
            .product(name: "SwiftJWT", package: "Swift-JWT")
        ]),
        .target(name: "WebhookServer", dependencies: [
            "GitHubDomain",
            .product(name: "FlyingFox", package: "FlyingFox")
        ])
    ]
)
