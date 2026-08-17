// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchMusic",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "NotchMusic", targets: ["NotchMusic"])],
    dependencies: [
        .package(url: "https://github.com/ejbills/mediaremote-adapter.git", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "NotchMusic",
            dependencies: [.product(name: "MediaRemoteAdapter", package: "mediaremote-adapter")]
        )
    ]
)
