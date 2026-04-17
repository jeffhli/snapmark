// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SnapMark",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "SnapMark",
            path: "Sources/SnapMark",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("CoreImage"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(
            name: "SnapMarkTests",
            dependencies: ["SnapMark"],
            path: "Tests/SnapMarkTests"
        ),
    ]
)
