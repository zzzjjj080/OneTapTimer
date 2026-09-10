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
    func cancelled() { log.append("cancel") }
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
final class SpyKeeper: ForegroundKeeping {
    var isKeeping = false
    var onChange: (() -> Void)?
    var begins = 0
    var ends = 0
    func begin() { begins += 1; isKeeping = true; onChange?() }
    func end() { if isKeeping { ends += 1 }; isKeeping = false; onChange?() }
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

    @Test func 腕を下ろして上げただけなら続き() {
        let h = SpyHaptics()
        let r = Runner(haptics: h, notifier: SpyScheduler(), defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.goIdle()
        r.activate(now: t0 + 40)
        #expect(r.engine.remaining(at: t0 + 40) == 50)
        #expect(h.log == ["start"])   // 始め直していない
    }

    @Test func クラウンで出たら止まって通知も消える() {
        let h = SpyHaptics(), s = SpyScheduler()
        let r = Runner(haptics: h, notifier: s, defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.leave(now: t0 + 30)
        #expect(r.engine.isCancelled)
        #expect(s.cancels == 1)
        #expect(h.log == ["start"])   // 出ていく人を震わせない
    }

    @Test func 出たあとに開き直したら待たずに始まる() {
        let h = SpyHaptics(), s = SpyScheduler(), d = fresh()
        let r = Runner(haptics: h, notifier: s, defaults: d, now: t0)
        r.activate(now: t0)
        r.leave(now: t0 + 30)
        r.activate(now: t0 + 35)
        #expect(!r.engine.isFinished)
        #expect(r.engine.remaining(at: t0 + 35) == 90)
        #expect(h.log == ["start", "start"])
    }

    @Test func 長押しでやめたあと腕を上げても始まらない() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.cancel(now: t0 + 10)
        r.goIdle()
        r.activate(now: t0 + 60)
        #expect(r.engine.isCancelled)   // 見ていただけ。始めない
    }

    @Test func 腕を下ろしている間に終わったらおわりのまま() {
        let h = SpyHaptics()
        let r = Runner(haptics: h, notifier: SpyScheduler(), defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.goIdle()
        // 腕を下ろしている間に終わり、10秒後に腕を上げた
        r.activate(now: t0 + 100)
        #expect(r.engine.isFinished)
        #expect(!r.engine.isCancelled)
        #expect(h.log == ["start"])   // 通知が鳴らしているので、ここでは鳴らさない
    }

    @Test func 終わってしばらく経って開いたら新しく始まる() {
        let d = fresh()
        let r1 = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        r1.activate(now: t0)
        r1.goIdle()
        let h = SpyHaptics(), s = SpyScheduler()
        let r2 = Runner(haptics: h, notifier: s, defaults: d, now: t0 + 600)
        r2.activate(now: t0 + 600)
        #expect(!r2.engine.isFinished)
        #expect(r2.engine.remaining(at: t0 + 600) == 90)
        #expect(h.log == ["start"])
        #expect(s.scheduled == [t0 + 690])
    }

    @Test func 走っている最中のタップは何もしない() {
        let h = SpyHaptics(), s = SpyScheduler()
        let r = Runner(haptics: h, notifier: s, defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.startAgain(now: t0 + 30)
        #expect(r.engine.remaining(at: t0 + 30) == 60)
        #expect(h.log == ["start"])
    }

    @Test func 終わった画面のタップで新しく始まる() {
        let h = SpyHaptics(), s = SpyScheduler(), d = fresh()
        let r = Runner(haptics: h, notifier: s, defaults: d, now: t0)
        r.activate(now: t0)
        r.cancel(now: t0 + 5)
        r.startAgain(now: t0 + 10)
        #expect(!r.engine.isFinished)
        #expect(r.engine.remaining(at: t0 + 10) == 90)
        #expect(s.scheduled.last == t0 + 100)
    }

    @Test func 色は順繰りで保存される() {
        let d = fresh()
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        #expect(r.theme == 1)
        for _ in 0..<10 { r.cycleTheme() }
        #expect(r.theme == 1)
        r.cycleTheme()
        #expect(r.theme == 2)
        let again = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: d, now: t0)
        #expect(again.theme == 2)
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

    @Test func 長押しで止めたら鳴らずに終わり扱い() {
        let h = SpyHaptics(), s = SpyScheduler()
        let r = Runner(haptics: h, notifier: s, defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.cancel(now: t0 + 20)
        #expect(r.engine.isCancelled)
        #expect(s.cancels == 1)
        #expect(h.log == ["start", "cancel"])
    }

    @Test func 設定を開いたまま出ていったら閉じる() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        r.activate(now: t0)
        r.openSettings()
        r.leave(now: t0 + 3)
        #expect(r.screen == .run)
    }

    @Test func 前面に留まれている間は通知を抑える() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        let k = SpyKeeper()
        r.keeper = k
        r.activate(now: t0)
        #expect(k.begins == 1)
        #expect(r.gate.isForeground)
        // 腕を下ろしても、留まれているなら通知は要らない
        r.goIdle()
        #expect(r.gate.isForeground)
        // 留まれなくなったら通知に任せる
        k.isKeeping = false
        k.onChange?()
        #expect(!r.gate.isForeground)
    }

    @Test func 出ていくときは前面の確保もやめる() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        let k = SpyKeeper()
        r.keeper = k
        r.activate(now: t0)
        r.leave(now: t0 + 10)
        #expect(k.ends == 1)
        #expect(!k.isKeeping)
        #expect(!r.gate.isForeground)
    }

    @Test func 長押しでやめたら前面の確保もやめる() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        let k = SpyKeeper()
        r.keeper = k
        r.activate(now: t0)
        r.cancel(now: t0 + 10)
        #expect(k.ends == 1)
    }

    @Test func 範囲外の設定は丸められる() {
        let r = Runner(haptics: SpyHaptics(), notifier: SpyScheduler(), defaults: fresh(), now: t0)
        r.apply(duration: 3, now: t0)
        #expect(r.duration == 10)
    }
}
