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

    func finished() {
        running?.cancel()
        running = Task { @MainActor in
            notice.notificationOccurred(.success)
            notice.prepare()
            try? await Task.sleep(for: .milliseconds(260))
            for _ in 0..<2 {
                guard !Task.isCancelled else { return }
                heavy.impactOccurred(intensity: 1.0)
                heavy.prepare()
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    func stepped(up: Bool) {
        soft.impactOccurred(intensity: up ? 0.8 : 0.6)
        soft.prepare()
    }

    func picked() {
        rigid.impactOccurred(intensity: 0.9)
        rigid.prepare()
    }
}
