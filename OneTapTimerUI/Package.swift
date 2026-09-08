// swift-tools-version: 6.0
import PackageDescription

// Watch と iPhone で同じ絵と同じ動きを使うための層。
// **色・水位の画面・設定の部品・通知・状態の持ち方をここに置く。**
// 両方に同じコードを持たせると、必ず片方だけ直してずれる。
// WatchKit にも UIKit にも依存させない（SwiftUI と UserNotifications だけ）。
let package = Package(
    name: "OneTapTimerUI",
    defaultLocalization: "ja",
    platforms: [.watchOS(.v11), .iOS(.v18), .macOS(.v14)],
    products: [.library(name: "OneTapTimerUI", targets: ["OneTapTimerUI"])],
    dependencies: [.package(path: "../OneTapTimerCore")],
    targets: [
        .target(name: "OneTapTimerUI",
                dependencies: [.product(name: "OneTapTimerCore", package: "OneTapTimerCore")],
                resources: [.process("Resources")]),
        .testTarget(name: "OneTapTimerUITests", dependencies: ["OneTapTimerUI"])
    ]
)
