import Testing
@testable import OneTapTimerCore

struct DurationRuleTests {

    @Test func 範囲は10秒から1時間() {
        #expect(DurationRule.clamp(3) == 10)
        #expect(DurationRule.clamp(90) == 90)
        #expect(DurationRule.clamp(99_999) == 3600)
    }

    @Test func 十秒と一分で動く() {
        #expect(DurationRule.stepped(90, by: 10) == 100)
        #expect(DurationRule.stepped(90, by: -10) == 80)
        #expect(DurationRule.stepped(90, by: 60) == 150)
        #expect(DurationRule.stepped(90, by: -60) == 30)
    }

    @Test func 端では止まる() {
        #expect(DurationRule.stepped(10, by: -10) == 10)
        #expect(DurationRule.stepped(30, by: -60) == 10)
        #expect(DurationRule.stepped(3600, by: 10) == 3600)
        #expect(DurationRule.stepped(3590, by: 60) == 3600)
    }

    @Test func 十秒に乗っていない値でも十秒に乗って返る() {
        // つまみも＋−も10秒の倍数しか作らないので、ここへ来るのは古い保存くらい。乗ることだけ見る
        for v in [95, 3, 3599] {
            #expect(DurationRule.stepped(v, by: 10) % 10 == 0)
            #expect(DurationRule.stepped(v, by: -10) % 10 == 0)
        }
    }

    @Test func つまみの目盛りは十秒() {
        #expect(DurationRule.seconds(fromCrown: 9) == 90)
        #expect(DurationRule.seconds(fromCrown: 9.4) == 90)
        #expect(DurationRule.seconds(fromCrown: 9.6) == 100)
        #expect(DurationRule.seconds(fromCrown: 0) == 10)
        #expect(DurationRule.seconds(fromCrown: 999) == 3600)
        #expect(DurationRule.crown(fromSeconds: 90) == 9)
        #expect(DurationRule.crownRange == 1...360)
    }
}
