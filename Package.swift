// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CarromAICoach",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CarromAICoach",
            targets: ["CarromAICoach"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
    ],
    targets: [
        .target(
            name: "CarromAICoach",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CarromAICoachTests",
            dependencies: ["CarromAICoach"],
            path: "Tests"
        )
    ]
)
