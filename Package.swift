// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "physics",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "physics",
            targets: ["physics"]),
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/MarkdownUI", from: "2.0.0"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift", from: "0.36.0"),
    ],
    targets: [
        .target(
            name: "physics",
            dependencies: [
                "MarkdownUI",
                .product(name: "AWSBedrockRuntime", package: "aws-sdk-swift"),
                .product(name: "AWSSTS", package: "aws-sdk-swift"),
            ]),
        .testTarget(
            name: "physicsTests",
            dependencies: ["physics"]),
    ]
)
