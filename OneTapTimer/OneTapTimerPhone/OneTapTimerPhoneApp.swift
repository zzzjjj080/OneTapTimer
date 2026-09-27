import SwiftUI
import UIKit
import OneTapTimerCore
import OneTapTimerUI

/// iPhone 側のアプリ。**Apple Watch のタイマーの見た目を決める器**（1.3 から）。
///
/// **なぜ存在するか。** Xcode は watchOS のアーカイブを App Store へ出せないので、
/// iOS アプリを配信の器にしている（引き継ぎ書 4-91）。
/// 1.2 までは iPhone でも同じタイマーが動いたが、**1.3 で外した**（2026-09-27 本人決定）。
/// 狭い Watch の画面に設定を積むより、iPhone で選んで送るほうが手が早い。
@main
struct OneTapTimerPhoneApp: App {
    @State private var runner = Runner(haptics: PhoneHaptics(), notifier: SilentNotifier())

    var body: some Scene {
        WindowGroup {
            PhoneRootView()
                .environment(runner)
                .task {
                    let r = runner
                    // 受け取る側にもなる（Watch から届くことは無いが、繋いでおかないと送れない）
                    DesignSync.shared.start { design in
                        Task { @MainActor in r.apply(design: design) }
                    }
                }
        }
    }
}
