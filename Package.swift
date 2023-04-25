// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-UDF",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "UDF",
            targets: ["UDF"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.4")
    ],
    targets: [
        .target(
            name: "UDF",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .target(name: "UDFCore")
            ],
            path: "Sources"
        ),

        .binaryTarget(name: "UDFCore", path: "Artifacts/UDFCore.xcframework"),

        .testTarget(
            name: "SwiftUI-UDF-Tests",
            dependencies: [
                .target(name: "UDF")
            ]
        ),

        .testTarget(
            name: "SwiftUI-UDF-ConcurrencyTests",
            dependencies: [
                .target(name: "UDF")
            ]
        )
    ]
)
