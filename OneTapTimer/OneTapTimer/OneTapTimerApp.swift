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
        return Runner(haptics: Haptics(), keeper: FrontKeeper())
    }
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(runner)
        }
        // **3つを区別する。**
        // active   … 見ている。開いた瞬間ならここで走り出す
        // inactive … 腕を下ろして画面が暗い。タイマーはそのまま、合図は通知に任せる
        // background … クラウンを押して出た。**走っているものは止める**（裏では動かさない）
        .onChange(of: phase, initial: true) { _, new in
            switch new {
            case .active:     runner.activate()
            case .inactive:   runner.goIdle()
            case .background: runner.leave()
            @unknown default: runner.goIdle()
            }
        }
    }
}
