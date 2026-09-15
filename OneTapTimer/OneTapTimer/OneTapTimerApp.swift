import SwiftUI
import UserNotifications
import OneTapTimerUI

@main
struct OneTapTimerApp: App {
    @State private var runner = OneTapTimerApp.makeRunner()

    /// 画面を撮るときは、通知にも前面を留めるセッションにも触らない（`OTT_SKIP_PERMISSION=1`）。
    ///
    /// **`WKExtendedRuntimeSession` を始めると、通知の許可ダイアログが出る**（self-care は
    /// 利用者へ知らせる前提の仕組みなので、通知の許可を求めてくる）。
    /// 一度出ると合成タップでは消せず、以後どの画面も撮れない（引き継ぎ書 4-24 / 4-107）。
    /// **リリース構成には入らない。**
    private static func makeRunner() -> Runner {
        #if DEBUG
        if ProcessInfo.processInfo.environment["OTT_SKIP_PERMISSION"] == "1" {
            return Runner(haptics: Haptics(), notifier: SilentNotifier())
        }
        #endif
        let runner = Runner(haptics: Haptics(), keeper: FrontKeeper())
        // 終わって振動が鳴り終わったら、1秒おいてアプリを閉じる（本人の希望）。
        // watchOS には「文字盤へ戻す」呼び出しが無いので、**プロセスを終える。終えると文字盤が出る。**
        // Apple は自分で閉じるアプリを勧めていない（落ちたように見える）ので、審査メモに意図を書く
        runner.closeAfterFinish = { exit(0) }
        return runner
    }
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(runner)
        }
        // **3つを区別する。**
        // active     … 見ている。開いた瞬間ならここで走り出す
        // inactive   … 腕を下ろして画面が暗い。タイマーはそのまま
        // background … **2通りある。** クラウンで出たなら止める。腕を下ろしていて画面が消えただけなら続ける
        //              （見分けは Runner.enteredBackground。暗い画面が続いたあとかどうかで決める）
        .onChange(of: phase, initial: true) { _, new in
            switch new {
            case .active:     runner.activate()
            case .inactive:   runner.goIdle()
            case .background: runner.enteredBackground()
            @unknown default: runner.goIdle()
            }
        }
    }
}
