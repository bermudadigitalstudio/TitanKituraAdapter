// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "TitanKituraAdapter",
    products: [
        .library(name: "TitanKituraAdapter", targets: ["TitanKituraAdapter"])
    ],
    dependencies: [
        .package(url: "https://github.com/bermudadigitalstudio/TitanCore.git", .branch("swift4")),
        .package(url: "https://github.com/IBM-Swift/Kitura-net.git", .upToNextMinor(from: "1.7.0"))
    ],
     targets:[
        .target(name:"TitanKituraAdapter", dependencies: ["TitanCore","KituraNet"]),
        .testTarget(name: "TitanKituraAdapterTests", dependencies: ["TitanKituraAdapter"])
    ]
)