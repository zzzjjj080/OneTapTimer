import SwiftUI
import UserNotifications
import OneTapTimerUI

struct RootView: View {
    @Environment(Runner.self) private var runner

    var body: some View {
        ZStack {
            switch runner.screen {
            case .run:      RunView().transition(.opacity)
            case .settings: SettingsView().transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: runner.screen)
        .task {
            // 前に出ている間は通知を出さない（自分で鳴らす）。裏では通知が鳴る
            UNUserNotificationCenter.current().delegate = runner.gate
            // シミュレータで画面を撮るときは、許可ダイアログを出させない（合成タップが届かない。引き継ぎ書 4-24）
            if !skipsPermissionForChecking { await runner.notifier.requestPermission() }
            applyDebugStateIfAsked()
        }
    }

    private var skipsPermissionForChecking: Bool {
        #if DEBUG
        ProcessInfo.processInfo.environment["OTT_SKIP_PERMISSION"] == "1"
        #else
        false
        #endif
    }

    /// シミュレータでの動作確認用の入口。**リリース構成には入らない。**
    ///
    ///     SIMCTL_CHILD_OTT_STATE="running:45" xcrun simctl launch <udid> com.zzzjjj080.OneTapTimer.watchkitapp
    private func applyDebugStateIfAsked() {
        #if DEBUG
        if let spec = ProcessInfo.processInfo.environment["OTT_STATE"] {
            runner.applyDebugState(spec)
        }
        #endif
    }
}
