// swift-tools-version:5.4
import PackageDescription
let package = Package(
    name: "Runtime",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "Runtime",
            targets: ["Runtime"]
        )
    ],
    targets: [
        .target(
            name: "Runtime",
            dependencies: ["CRuntime"],
            resources: [
                .process("CMakeLists.txt")
            ]
        ),
        .target(
            name: "CRuntime",
            dependencies: [],
            resources: [
                .process("CMakeLists.txt")
            ]
        )
    ]
)
