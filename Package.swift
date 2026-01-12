// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "dgx-mcp",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "dgx-mcp",
            path: "Sources/dgx-mcp"
        )
    ]
)
