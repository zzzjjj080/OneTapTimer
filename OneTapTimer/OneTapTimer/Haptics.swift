import WatchKit
import OneTapTimerUI

/// 触覚。**アプリの触覚はここに全部集める。**
///
/// watchOS には iPhone の `intensity` に当たるものが無い。強さは種類と回数と間隔でしか作れない。
///
/// | 場面 | 触覚 |
/// |---|---|
/// | 走り出した | `.start` |
/// | 終わった | `.notification` を 90ms おきに ×28（約2.5秒）。**一続きの長く強い振動を一度だけ。鳴り続けない** |
/// | ＋ − | `.click`（`.stop` は二重に震えるので使わない。何十回も押す） |
///
/// **止めたときは鳴らさない。** 出ていく人を震わせても意味がない。
@MainActor
final class Haptics: TimerHaptics {

    private var running: Task<Void, Never>?

    func started() {
        running?.cancel()
        WKInterfaceDevice.current().play(.start)
    }

    /// 終わりの合図の回数。**ここを増やすと長くなる。**
    ///
    /// 2026-09-13：×9（約1秒）では「もっと強く長く」と言われ、×28（約2.5秒）にした。
    /// watchOS には強さの指定が無いので、**強さも長さも回数と間隔で作る。**
    private static let finishTaps = 28
    /// 間隔。**空けすぎると別々の合図に、詰めすぎると取りこぼして短く感じる。**
    /// 区切りタイマーで 110ms が「1発ずつ分かる」境目だった。それより少し詰めて、つながって聞こえるようにする
    private static let finishGap = Duration.milliseconds(90)

    /// 終わりの合図。**一続きの長く強い振動を、一度だけ。**
    ///
    /// 前は ×3 → 間 → `.success` だったが、途中の間で「2回鳴った」ように感じられた。
    /// 間を無くして回数を増やし、1つの長い振動にまとめた。
    ///
    /// **鳴り終わるまで返らない。** 呼ぶ側はこれを待ってから前面を留めるのをやめる。
    /// 先にやめると、腕を下ろしている間はアプリが止められて、途中から鳴らなくなる。
    func finished() async {
        running?.cancel()
        let burst = Task {
            for i in 0..<Self.finishTaps {
                guard !Task.isCancelled else { return }
                WKInterfaceDevice.current().play(.notification)
                if i < Self.finishTaps - 1 { try? await Task.sleep(for: Self.finishGap) }
            }
            // 最後の1発が鳴り終わるまで
            try? await Task.sleep(for: .milliseconds(250))
        }
        running = burst
        await burst.value
    }

    func stepped(up: Bool) {
        WKInterfaceDevice.current().play(.click)
    }
}
