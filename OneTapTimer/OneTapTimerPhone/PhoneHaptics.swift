import UIKit
import OneTapTimerUI

/// iPhone の触覚。**Watch とは作りが違う。**
///
/// iOS には `intensity` がある。指定しないと端末側の判断で弱まり、初回は遅れて鳴るので、
/// `prepare()` と `intensity` を必ず明示する（引き継ぎ書 4-29）。
@MainActor
final class PhoneHaptics: TimerHaptics {

    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notice = UINotificationFeedbackGenerator()
    private var running: Task<Void, Never>?

    init() { heavy.prepare(); soft.prepare(); rigid.prepare(); notice.prepare() }

    func started() {
        running?.cancel()
        heavy.impactOccurred(intensity: 1.0)
        heavy.prepare()
    }

    /// 終わりの合図。**一続きの長く強い振動を、一度だけ**（Watch と揃える）。
    /// 鳴り終わるまで返らない。
    func finished() async {
        running?.cancel()
        let burst = Task { @MainActor in
            for i in 0..<30 {
                guard !Task.isCancelled else { return }
                heavy.impactOccurred(intensity: 1.0)
                heavy.prepare()
                if i < 29 { try? await Task.sleep(for: .milliseconds(80)) }
            }
        }
        running = burst
        await burst.value
    }

    func stepped(up: Bool) {
        soft.impactOccurred(intensity: up ? 0.8 : 0.6)
        soft.prepare()
    }
}
