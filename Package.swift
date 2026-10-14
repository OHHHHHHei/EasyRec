// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EasyRec",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "EasyRec", targets: ["EasyRec"])],
    targets: [.executableTarget(name: "EasyRec")],
    swiftLanguageModes: [.v5]
)
