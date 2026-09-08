import WatchKit
import OneTapTimerUI

/// 触覚。**アプリの触覚はここに全部集める。**
///
/// watchOS には iPhone の `intensity` に当たるものが無い。強さは種類と回数と間隔でしか作れない。
///
/// | 場面 | 触覚 |
/// |---|---|
/// | 走り出した | `.start` |
/// | 終わった | `.notification` ×3 → 間 → `.success`。**これで終わり。鳴り続けない** |
/// | ＋ − | `.start` / `.stop`（合図より弱く。何十回も押す） |
/// | チップ | `.click` |
@MainActor
final class Haptics: TimerHaptics {

    private var running: Task<Void, Never>?

    func started() {
        running?.cancel()
        WKInterfaceDevice.current().play(.start)
    }

    func finished() {
        running?.cancel()
        running = Task {
            for i in 0..<3 {
                guard !Task.isCancelled else { return }
                WKInterfaceDevice.current().play(.notification)
                if i < 2 { try? await Task.sleep(for: .milliseconds(110)) }
            }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            WKInterfaceDevice.current().play(.success)
        }
    }

    func stepped(up: Bool) {
        WKInterfaceDevice.current().play(up ? .start : .stop)
    }

    func picked() {
        WKInterfaceDevice.current().play(.click)
    }
}
