// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-UDF",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "UDF",
            targets: ["UDF"]
        ),
        .library(
            name: "UDFSwiftTesting",
            targets: ["UDFSwiftTesting"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.0"),
        .package(url: "https://github.com/urlaunched-com/Runtime", from: "2.2.6"),
    ],
    targets: [
        .target(
            name: "UDF",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "Runtime", package: "Runtime"),
            ],
            path: "UDF"
        ),

        .target(
            name: "UDFSwiftTesting",
            dependencies: [
                .target(name: "UDF"),
            ],
            path: "UDFSwiftTesting"
        ),

        .testTarget(
            name: "SwiftUI-UDF-Tests",
            dependencies: [
                .target(name: "UDFSwiftTesting"),
            ]
        ),

        .testTarget(
            name: "SwiftUI-UDF-ConcurrencyTests",
            dependencies: [
                .target(name: "UDFSwiftTesting"),
            ]
        ),
    ]
)
