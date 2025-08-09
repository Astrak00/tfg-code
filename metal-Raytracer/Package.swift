// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MetalRaytracer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "metal-raytracer", targets: ["MetalRaytracer"])
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "MetalRaytracer",
            path: "Sources/MetalRaytracer"
        )
    ]
)


