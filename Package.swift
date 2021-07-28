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
    dependencies: [],
    targets: [
        .target(
            name: "SwiftUI-UDF",
            dependencies: [
                .target(name: "SwiftUI_UDF_Binary")
            ],
            path: "Sources"
        ),

        .binaryTarget(name: "SwiftUI_UDF_Binary", path: "Artifacts/SwiftUI_UDF_Binary.xcframework")
    ]
)
