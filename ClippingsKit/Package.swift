// swift-tools-version: 5.9
import PackageDescription

// ClippingsKit — shared logic for the container app and the share extension.
//
// The package intentionally separates platform-agnostic logic (caption sorting,
// crop math, the data model) from Apple-only services (Vision OCR, ImageIO
// export). The agnostic logic compiles and unit-tests on any platform — including
// Linux CI — while the Apple-only code is guarded by `#if canImport(...)` so it
// simply drops out where the frameworks are unavailable.
let package = Package(
    name: "ClippingsKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "ClippingsKit", targets: ["ClippingsKit"])
    ],
    targets: [
        .target(
            name: "ClippingsKit"
        ),
        .testTarget(
            name: "ClippingsKitTests",
            dependencies: ["ClippingsKit"]
        )
    ]
)
