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
            // シミュレータで画面を撮るときは、通知まわりに一切触らない
            // （許可ダイアログが出ると、合成タップでは消せない。引き継ぎ書 4-24 / 4-107）
            if !skipsPermissionForChecking {
                // 前に出ている間は通知を出さない（自分で鳴らす）。裏では通知が鳴る
                UNUserNotificationCenter.current().delegate = runner.gate
                await runner.notifier.requestPermission()
            }
            await applyDebugStateIfAsked()
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
    /// **`activate()` より後に効かせる。** 画面が出るときの `scenePhase` の通知と
    /// この `.task` はどちらが先か決まっておらず、先に入れても新しいタイマーで上書きされる。
    private func applyDebugStateIfAsked() async {
        #if DEBUG
        guard let spec = ProcessInfo.processInfo.environment["OTT_STATE"] else { return }
        try? await Task.sleep(for: .milliseconds(400))
        runner.applyDebugState(spec)
        #endif
    }
}
