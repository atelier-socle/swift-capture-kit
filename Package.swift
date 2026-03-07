// swift-tools-version: 6.2

// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import PackageDescription

let package = Package(
    name: "swift-capture-kit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "CaptureKit",
            targets: ["CaptureKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        .target(
            name: "CaptureKit",
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "CaptureKitTests",
            dependencies: ["CaptureKit"]
        )
    ]
)
