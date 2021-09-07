// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-UDF",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "SwiftUI-UDF",
            targets: ["SwiftUI-UDF"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", .upToNextMajor(from: "0.0.7"))
//        .package(url: "https://github.com/wickwirew/Runtime", .upToNextMajor(from: "2.2.2"))
    ],
    targets: [
        .target(
            name: "SwiftUI-UDF",
            dependencies: [
                .product(name: "OrderedCollections", package: "swift-collections"),
                .target(name: "SwiftUI_UDF_Binary")
//                .product(name: "Runtime", package: "Runtime")
            ],
            path: "Sources"
        ),

        .binaryTarget(name: "SwiftUI_UDF_Binary", path: "Artifacts/SwiftUI_UDF_Binary.xcframework"),

        .testTarget(
            name: "SwiftUI-UDF-Tests",
            dependencies: [
//                .product(name: "Runtime", package: "Runtime"),
                .target(name: "SwiftUI-UDF")
            ]
        )
    ]
)
