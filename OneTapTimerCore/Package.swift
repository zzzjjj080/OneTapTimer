// swift-tools-version: 6.0
import PackageDescription

// UI に依存しないロジック層。
// 「今が何時か」を渡したら「何秒残っていて、いま鳴らすべきか」が返るところまでをここで固める。
// Xcode を開かなくても `swift test` で回せる。
let package = Package(
    name: "OneTapTimerCore",
    platforms: [.watchOS(.v11), .iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "OneTapTimerCore", targets: ["OneTapTimerCore"])
    ],
    targets: [
        .target(name: "OneTapTimerCore"),
        .testTarget(name: "OneTapTimerCoreTests", dependencies: ["OneTapTimerCore"])
    ]
)
