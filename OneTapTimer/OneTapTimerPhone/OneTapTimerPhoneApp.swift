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
    @State private var runner = Runner(haptics: PhoneHaptics())
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            PhoneRootView()
                .environment(runner)
        }
        .onChange(of: phase, initial: true) { _, new in
            switch new {
            case .active:
                runner.activate()
                // 90秒眺めるものなので、その間は画面を消させない
                UIApplication.shared.isIdleTimerDisabled = true
            default:
                runner.deactivate()
                UIApplication.shared.isIdleTimerDisabled = false
            }
        }
    }
}
