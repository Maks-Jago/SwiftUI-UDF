// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-UDF",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "UDF",
            targets: ["UDF"]
        ),
        .library(
            name: "UDFXCTest",
            targets: ["UDFXCTest"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.6"),
        .package(url: "https://github.com/urlaunched-com/Runtime", from: "2.2.6")
    ],
    targets: [
        .target(
            name: "UDF",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Runtime", package: "Runtime")
            ],
            path: "UDF"
        ),

        .target(
            name: "UDFXCTest",
            dependencies: [
                .target(name: "UDF")
            ],
            path: "UDFXCTest"
        ),

        .testTarget(
            name: "SwiftUI-UDF-Tests",
            dependencies: [
                .target(name: "UDFXCTest")
            ]
        ),

        .testTarget(
            name: "SwiftUI-UDF-ConcurrencyTests",
            dependencies: [
                .target(name: "UDFXCTest")
            ]
        )
    ]
)
