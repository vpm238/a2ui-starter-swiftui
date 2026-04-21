// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "A2UIStarter",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/vpm238/a2ui-swiftui.git", branch: "main"),
        .package(url: "https://github.com/vpm238/a2ui-skills-swiftui.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "A2UIStarter",
            dependencies: [
                .product(name: "A2UI", package: "a2ui-swiftui"),
                .product(name: "A2UISkills", package: "a2ui-skills-swiftui"),
            ],
            path: "Sources/A2UIStarter"
        ),
    ]
)
