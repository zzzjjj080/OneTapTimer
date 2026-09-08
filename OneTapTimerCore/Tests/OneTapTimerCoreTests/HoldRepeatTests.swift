import Testing
@testable import OneTapTimerCore

struct HoldRepeatTests {
    @Test func 一つだけ動かすなら待ちは無い() {
        #expect(HoldRepeat.duration(steps: 1) == 0)
    }
    @Test func 押し続けると速くなる() {
        #expect(HoldRepeat.interval(after: 0) > HoldRepeat.interval(after: 30))
        // 90秒 → 10分 は 10秒刻みで 21 + 30秒刻みで 10 = 31 歩。5秒以内で届く
        #expect(HoldRepeat.duration(steps: 31) < 5)
    }
}
