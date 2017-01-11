import PackageDescription

var package = Package(
  name: "TitanKituraAdapter",
  dependencies: [
    .Package(url: "https://github.com/bermudadigitalstudio/titan-core.git", majorVersion: 0, minor: 1),
    .Package(url: "https://github.com/IBM-Swift/Kitura-net.git", majorVersion: 1, minor: 4)
  ]
)
