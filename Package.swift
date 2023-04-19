// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let package = Package(
    name: "GDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GDK",
            targets: ["GDK"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GDK",
            dependencies: ["GDKBinaries"],
            linkerSettings: [ .linkedLibrary("c++") ]
        ),
        .binaryTarget(
            name: "GDKBinaries",
            url: "https://github.com/angelix/gdk_ios/releases/download/0.0.61/gdk_ios_0.0.61.zip",
            checksum: "ddfc7b9fbf937f212d0f79ef4ec1113bd3e0ec6ec39baed986830a4499b67b82"
        ),
//       ,.binaryTarget(
//            name: "GDKBinaries",
//            path: "GDKBinaries.xcframework"
//        ),
    ]
)



