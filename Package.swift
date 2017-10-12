// swift-tools-version:3.1

import PackageDescription

var package = Package(
  name: "TitanKituraAdapter",
  dependencies: [
    .Package(url: "https://github.com/bermudadigitalstudio/TitanCore.git", majorVersion: 0, minor: 4),
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", majorVersion: 1, minor: 7)
  ]
)
