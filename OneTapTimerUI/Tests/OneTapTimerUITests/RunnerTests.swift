import Foundation
import Testing
import OneTapTimerCore
@testable import OneTapTimerUI

@MainActor
final class SpyHaptics: TimerHaptics {
    var log: [String] = []
    func started() { log.append("start") }
    func finished() { log.append("finish") }
    func stepped(up: Bool) { log.append(up ? "up" : "down") }
    func picked() { log.append("pick") }
}

@MainActor
final class SpyScheduler: EndScheduling {
    var scheduled: [Date] = []
    var cancels = 0
    func requestPermission() async {}
    func schedule(endAt: Date, duration: Int) { scheduled.append(endAt) }
    func cancel() { cancels += 1 }
}

@MainActor
struct RunnerTests {
    let t0 = Date(timeIntervalSince1970: 2_000_000)

    private func fresh() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func 初回は開いた瞬間に90秒で走り出す() {
        let h = SpyHaptics(), s = SpyScheduler(), d = fresh()
        let r = Runner(haptics: h, notifier: s, defaults: d, now: t0)
        r.activate(now: t0)
        #expect(r.duration == 90)
        #expect(!r.engine.isFinished)
        #expect(r.engine.remaining(at: t0) == 90)
        #expect(h.log == ["start"])
        #expect(s.scheduled == [t0 + 90])
    }

    @Test func 走っている最中に開き直したら続き() {
        let d = fresh()
        let r1 = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        r1.activate(now: t0)
        r1.deactivate()
        // プロセスが落ちて、40秒後に開き直した
        let h = SpyHaptics()
        let r2 = Runner(haptics: h, notifier: SpyScheduler(), defaults: d, now: t0 + 40)
        r2.activate(now: t0 + 40)
        #expect(r2.engine.remaining(at: t0 + 40) == 50)
        #expect(h.log.isEmpty)   // 始め直していない
    }

    @Test func 終わった直後に開いたらおわりのまま() {
        let d = fresh()
        let r1 = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        r1.activate(now: t0)
        r1.deactivate()
        // 裏で終わって、10秒後に腕を上げた
        let h = SpyHaptics()
        let r2 = Runner(haptics: h, notifier: SpyScheduler(), defaults: d, now: t0 + 100)
        r2.activate(now: t0 + 100)
        #expect(r2.engine.isFinished)
        #expect(h.log.isEmpty)   // 通知が鳴らしているので、ここでは鳴らさない
    }

    @Test func 終わってしばらく経って開いたら新しく始まる() {
        let d = fresh()
        let r1 = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        r1.activate(now: t0)
        r1.deactivate()
        let h = SpyHaptics(), s = SpyScheduler()
        let r2 = Runner(haptics: h, notifier: s, defaults: d, now: t0 + 600)
        r2.activate(now: t0 + 600)
        #expect(!r2.engine.isFinished)
        #expect(r2.engine.remaining(at: t0 + 600) == 90)
        #expect(h.log == ["start"])
        #expect(s.scheduled == [t0 + 690])
    }

    @Test func タップで最初から() {
        let h = SpyHaptics(), s = SpyScheduler()
        let r = Runner(haptics: h, notifier: s, defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.restart(now: t0 + 30)
        #expect(r.engine.remaining(at: t0 + 30) == 90)
        #expect(h.log == ["start", "start"])
        #expect(s.scheduled.last == t0 + 120)
    }

    @Test func 設定を決めたら保存されて次回もその長さ() {
        let d = fresh()
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        r.activate(now: t0)
        r.openSettings()
        #expect(r.screen == .settings)
        r.apply(duration: 180, now: t0 + 5)
        #expect(r.screen == .run)
        #expect(r.engine.duration == 180)
        #expect(r.engine.remaining(at: t0 + 5) == 180)

        let again = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0 + 9999)
        #expect(again.duration == 180)
    }

    @Test func 範囲外の設定は丸められる() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        r.apply(duration: 3, now: t0)
        #expect(r.duration == 10)
    }
}
