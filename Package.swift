// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyUpdateKit",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftyUpdateKit",
            targets: ["SwiftyUpdateKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(
//            name: "SwiftyUpdateKit",
//            dependencies: [],
//            path: "Framework/Sources"),
//        .testTarget(
//            name: "SwiftyUpdateKitTests",
//            dependencies: ["SwiftyUpdateKit"],
//            path: "Framework/SwiftyUpdateKitTests",
//            exclude: ["Info.plist"]),
        .binaryTarget(
            name: "SwiftyUpdateKit",
            path: "Framework/SwiftyUpdateKit.xcframework"
        ),
    ]
)
