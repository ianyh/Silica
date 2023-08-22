// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Silica",
    defaultLocalization: "en",
    products: [
        .library(
            name: "Silica",
            targets: ["Silica"])
    ],
    targets: [
        .target(
            name: "Silica",
            path: "Silica",
            publicHeadersPath: "include")
    ]
)
