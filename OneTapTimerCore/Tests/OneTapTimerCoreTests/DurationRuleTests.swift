import Testing
@testable import OneTapTimerCore

struct DurationRuleTests {

    @Test func 範囲は10秒から1時間() {
        #expect(DurationRule.clamp(3) == 10)
        #expect(DurationRule.clamp(90) == 90)
        #expect(DurationRule.clamp(99_999) == 3600)
    }

    @Test func 刻みは長さで粗くなる() {
        #expect(DurationRule.stepSize(at: 10) == 10)
        #expect(DurationRule.stepSize(at: 299) == 10)
        #expect(DurationRule.stepSize(at: 300) == 30)
        #expect(DurationRule.stepSize(at: 1199) == 30)
        #expect(DurationRule.stepSize(at: 1200) == 60)
    }

    @Test func 上下は境目で刻みが切り替わる() {
        #expect(DurationRule.stepped(90, up: true) == 100)
        #expect(DurationRule.stepped(90, up: false) == 80)
        // 5:00 から下げたら 4:50。4:30 ではない
        #expect(DurationRule.stepped(300, up: false) == 290)
        #expect(DurationRule.stepped(300, up: true) == 330)
        #expect(DurationRule.stepped(1200, up: false) == 1170)
        #expect(DurationRule.stepped(1200, up: true) == 1260)
    }

    @Test func 端では止まる() {
        #expect(DurationRule.stepped(10, up: false) == 10)
        #expect(DurationRule.stepped(3600, up: true) == 3600)
        #expect(DurationRule.stepped(3595, up: true) == 3600)
    }

    @Test func 刻みに乗っていない値は刻みへ戻る() {
        // 古い保存などで 95 秒が来ても、上は 100、下は 90 に乗る
        #expect(DurationRule.stepped(95, up: true) == 100)
        #expect(DurationRule.stepped(95, up: false) == 90)
    }

    @Test func つまみの連続値は刻みに乗る() {
        #expect(DurationRule.snapped(93.4) == 90)
        #expect(DurationRule.snapped(96.0) == 100)
        #expect(DurationRule.snapped(314.0) == 300)
        #expect(DurationRule.snapped(316.0) == 330)
        #expect(DurationRule.snapped(2.0) == 10)
        #expect(DurationRule.snapped(9_999.0) == 3600)
    }

    @Test func プリセットは全部範囲内で刻みに乗っている() {
        for p in DurationRule.presets + DurationRule.presetsCompact {
            #expect(DurationRule.clamp(p) == p)
            #expect(DurationRule.snapped(Double(p)) == p)
        }
        #expect(DurationRule.presets.contains(DurationRule.standard))
    }
}
