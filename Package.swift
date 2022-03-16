// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "PrettyBytes",
  products: [
    .library(name: "PrettyBytes", targets: ["PrettyBytes"]),
  ],
  targets: [
    .target(
      name: "PrettyBytes",
      dependencies: []),
    .testTarget(
      name: "PrettyBytesTests",
      dependencies: ["PrettyBytes"]),
  ]
)
