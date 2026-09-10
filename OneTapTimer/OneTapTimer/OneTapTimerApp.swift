import SwiftUI
import UserNotifications
import OneTapTimerUI

@main
struct OneTapTimerApp: App {
    @State private var runner = Runner(haptics: Haptics(), keeper: FrontKeeper())
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
