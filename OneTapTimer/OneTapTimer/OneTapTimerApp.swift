import SwiftUI
import UserNotifications
import OneTapTimerUI

@main
struct OneTapTimerApp: App {
    @State private var runner = Runner(haptics: Haptics())
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(runner)
        }
        // 前に出たら始める。裏へ回ったら時計を止めて、通知に任せる。
        .onChange(of: phase, initial: true) { _, new in
            switch new {
            case .active: runner.activate()
            default: runner.deactivate()
            }
        }
    }
}
