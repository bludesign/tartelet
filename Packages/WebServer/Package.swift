// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebServer",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WebServer", targets: [
            "WebServer"
        ])
    ],
    dependencies: [
        .package(path: "../Logging"),
        .package(url: "https://github.com/swhitty/FlyingFox.git", .upToNextMajor(from: "0.21.0"))
    ],
    targets: [
        .target(name: "WebServer", dependencies: [
            .product(name: "LoggingDomain", package: "Logging"),
            .product(name: "FlyingFox", package: "FlyingFox")
        ])
    ]
)
