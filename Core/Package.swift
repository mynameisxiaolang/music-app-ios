// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YueYinCore",
    platforms: [.iOS(.v15), .macOS(.v13)],
    products: [
        .library(name: "YueYinCore", targets: ["YueYinCore"])
    ],
    targets: [
        .target(name: "YueYinCore"),
        .testTarget(name: "YueYinCoreTests", dependencies: ["YueYinCore"])
    ]
)
