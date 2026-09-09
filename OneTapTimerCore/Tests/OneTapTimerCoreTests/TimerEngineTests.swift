import Foundation
import Testing
@testable import OneTapTimerCore

struct TimerEngineTests {
    let t0 = Date(timeIntervalSince1970: 1_000_000)

    @Test func 残りは終わる時刻との差() {
        let e = TimerEngine(duration: 90, startedAt: t0)
        #expect(e.remaining(at: t0) == 90)
        #expect(e.remaining(at: t0 + 30) == 60)
        #expect(e.remaining(at: t0 + 90) == 0)
        #expect(e.remaining(at: t0 + 500) == 0)
        #expect(e.startAt == t0)
    }

    @Test func 割合は1から0へ() {
        let e = TimerEngine(duration: 100, startedAt: t0)
        #expect(e.fraction(at: t0) == 1)
        #expect(abs(e.fraction(at: t0 + 25) - 0.75) < 1e-9)
        #expect(e.fraction(at: t0 + 100) == 0)
    }

    @Test func 終わった瞬間に一度だけ知らせる() {
        var e = TimerEngine(duration: 90, startedAt: t0)
        #expect(e.advance(to: t0 + 89.9).isEmpty)
        #expect(e.advance(to: t0 + 90) == [.finished])
        #expect(e.isFinished)
        #expect(e.finishedAt == t0 + 90)
        #expect(e.advance(to: t0 + 91).isEmpty)          // 二度は鳴らさない
    }

    @Test func 裏で止まっていても追いつく() {
        var e = TimerEngine(duration: 90, startedAt: t0)
        // 10分後にいきなり時刻が来ても、終わりの合図は1回
        #expect(e.advance(to: t0 + 600) == [.finished])
        // 終わった時刻は「追いついた時刻」ではなく本当の終了時刻
        #expect(e.finishedAt == t0 + 90)
        #expect(e.sinceFinished(at: t0 + 630) == 540)
    }

    @Test func 最初からで同じ長さのまま新しくなる() {
        var e = TimerEngine(duration: 90, startedAt: t0)
        _ = e.advance(to: t0 + 90)
        e.restart(at: t0 + 200)
        #expect(!e.isFinished)
        #expect(e.duration == 90)
        #expect(e.remaining(at: t0 + 200) == 90)
        #expect(e.sinceFinished(at: t0 + 300) == nil)
    }

    @Test func 終わりが近いのは最後の10秒だけ() {
        let e = TimerEngine(duration: 90, startedAt: t0)
        #expect(!e.isFinalStretch(at: t0 + 79))
        #expect(e.isFinalStretch(at: t0 + 80))
        #expect(e.isFinalStretch(at: t0 + 89.5))
        #expect(!e.isFinalStretch(at: t0 + 90))       // 0 は「終わった」。近いではない
    }

    @Test func 短いタイマーでは終わりが近いを出さない() {
        let e = TimerEngine(duration: 20, startedAt: t0)
        #expect(!e.isFinalStretch(at: t0 + 15))
        let f = TimerEngine(duration: 30, startedAt: t0)
        #expect(f.isFinalStretch(at: t0 + 25))
    }

    @Test func 範囲外の長さは丸められる() {
        #expect(TimerEngine(duration: 1, startedAt: t0).duration == 10)
        #expect(TimerEngine(duration: 9_999, startedAt: t0).duration == 3600)
    }

    @Test func 途中で止めたら止めた時刻に終わったことになる() {
        var e = TimerEngine(duration: 90, startedAt: t0)
        e.cancel(at: t0 + 20)
        #expect(e.isFinished)
        #expect(e.isCancelled)
        #expect(e.finishedAt == t0 + 20)
        #expect(e.advance(to: t0 + 90).isEmpty)      // 時間が来ても鳴らさない
        e.restart(at: t0 + 100)
        #expect(!e.isCancelled)
        #expect(!e.isFinished)
    }

    @Test func 古い保存にisCancelledが無くても読める() throws {
        let json = #"{"duration":90,"endAt":700000000,"finishedAt":null}"#.data(using: .utf8)!
        let e = try JSONDecoder().decode(TimerEngine.self, from: json)
        #expect(e.duration == 90)
        #expect(!e.isCancelled)
    }

    @Test func 保存して戻せる() throws {
        var e = TimerEngine(duration: 90, startedAt: t0)
        _ = e.advance(to: t0 + 90)
        let data = try JSONEncoder().encode(e)
        let back = try JSONDecoder().decode(TimerEngine.self, from: data)
        #expect(back == e)
        #expect(back.isFinished)
    }
}
