import SwiftUI
import UIKit
import OneTapTimerUI

/// iPhone 側のアプリ。
///
/// **なぜ存在するか。** Xcode は watchOS のアーカイブを App Store へ出せないので、
/// iOS アプリを配信の器にして、その中に Watch アプリを入れている。
/// ただし器として空にはしない。**同じワンタップタイマーを iPhone でも使えるようにしてある。**
/// 動きは `OneTapTimerUI` の `Runner` を Watch と共有している。
@main
struct OneTapTimerPhoneApp: App {
    @State private var runner = OneTapTimerPhoneApp.makeRunner()

    /// 画面を撮るときは、通知に触らない作りへ差し替える。**リリース構成には入らない。**
    private static func makeRunner() -> Runner {
        #if DEBUG
        if ProcessInfo.processInfo.environment["OTT_SKIP_PERMISSION"] == "1" {
            return Runner(haptics: PhoneHaptics(), notifier: SilentNotifier())
        }
        #endif
        return Runner(haptics: PhoneHaptics())
    }
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            PhoneRootView()
                .environment(runner)
        }
        // Watch と同じ。**出ていったら止める。裏では動かさない。**
        .onChange(of: phase, initial: true) { _, new in
            switch new {
            case .active:
                runner.activate()
                // 90秒眺めるものなので、その間は画面を消させない
                UIApplication.shared.isIdleTimerDisabled = true
            case .background:
                runner.leave()
                UIApplication.shared.isIdleTimerDisabled = false
            default:
                runner.goIdle()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
}
