// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchMusic",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "NotchMusic", targets: ["NotchMusic"])],
    dependencies: [
        // Keep public builds reproducible. Review and update this revision
        // deliberately together with Package.resolved.
        .package(
            url: "https://github.com/ejbills/mediaremote-adapter.git",
            revision: "5b6afde3f501a3da567e23bf7f23d562938a1809"
        )
    ],
    targets: [
        .executableTarget(
            name: "NotchMusic",
            dependencies: [.product(name: "MediaRemoteAdapter", package: "mediaremote-adapter")]
        )
    ]
)
