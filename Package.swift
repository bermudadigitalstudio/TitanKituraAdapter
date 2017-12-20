// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "TitanKituraAdapter",
    products: [
        .library(name: "TitanKituraAdapter", targets: ["TitanKituraAdapter"])
    ],
    dependencies: [
        .package(url: "https://github.com/bermudadigitalstudio/Titan.git", .exact( "0.9.0-beta.1")),
        .package(url: "https://github.com/IBM-Swift/Kitura-net.git", .upToNextMinor(from: "2.0.0"))
    ],
    targets: [
        .target(name:"TitanKituraAdapter", dependencies: ["TitanCore", "KituraNet"]),
        .testTarget(name: "TitanKituraAdapterTests", dependencies: ["TitanKituraAdapter"])
    ]
)

