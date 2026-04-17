// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SnapMark",
    platforms: [.macOS(.v14)],
    targets: [
        // Library target containing all app logic (testable)
        .target(
            name: "SnapMarkLib",
            path: "Sources/SnapMark",
            exclude: ["main.swift"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreImage"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        // Executable target (thin wrapper)
        .executableTarget(
            name: "SnapMark",
            dependencies: ["SnapMarkLib"],
            path: "Sources/SnapMarkApp",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        // Test runner executable
        .executableTarget(
            name: "SnapMarkTests",
            dependencies: ["SnapMarkLib"],
            path: "Tests/SnapMarkTests",
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
    ]
)
