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
            dependencies: ["GDKBinaries"]),
        .binaryTarget(
            name: "GDKBinaries",
            url: "https://github.com/angelix/gdk_ios/releases/download/release_0.0.58.post2/gdk_swift_release_0.0.58.post2.zip",
            checksum: "9a119631bf28ce7d36bdc1c5f4ecd98a068d91cc0ba4996ee0a904e94f3a7318"
        ),
//       ,.binaryTarget(
//            name: "GDKBinaries",
//            path: "GDKBinaries.xcframework"
//        ),
    ]
)



