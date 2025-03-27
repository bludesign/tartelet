// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Router",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "Router", targets: [
            "Router"
        ])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.3")
    ],
    targets: [
        .target(name: "Router", dependencies: [
            .product(name: "Yams", package: "Yams")
        ])
    ]
)
