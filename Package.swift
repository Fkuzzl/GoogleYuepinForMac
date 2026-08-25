// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GoogleYuepinForMac",
    platforms: [.macOS("15.0")],
    products: [
        .library(name: "GoogleYuepinCore", targets: ["GoogleYuepinCore"]),
    ],
    targets: [
        .target(
            name: "GoogleYuepinCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "GoogleYuepinCoreTests",
            dependencies: ["GoogleYuepinCore"],
            resources: [.process("Fixtures")]
        ),
    ]
)
