import Foundation
import Testing
@testable import OneTapTimerCore

struct TimeTextTests {
    let ja = Locale(identifier: "ja_JP")
    let en = Locale(identifier: "en_US")

    @Test func 切り上げる() {
        #expect(TimeText.clock(90) == "1:30")
        #expect(TimeText.clock(89.2) == "1:30")
        #expect(TimeText.clock(89.0) == "1:29")
        #expect(TimeText.clock(0) == "0:00")
        #expect(TimeText.clock(90.0000000001) == "1:30")   // 誤差で 1:31 にしない
    }

    @Test func 一時間は時を出さない() {
        #expect(TimeText.clock(3600) == "60:00")
        #expect(TimeText.clock(3599.5) == "60:00")
    }

    @Test func 一分を切ったら秒だけ() {
        #expect(TimeText.display(90) == "1:30")
        #expect(TimeText.display(60) == "1:00")
        #expect(TimeText.display(59.9) == "1:00")   // 切り上げて60なので、まだ m:ss
        #expect(TimeText.display(59.0) == "59")
        #expect(TimeText.display(0.4) == "1")
        #expect(TimeText.display(0) == "0")
        #expect(TimeText.showsSecondsOnly(59.0))
        #expect(!TimeText.showsSecondsOnly(59.5))
    }

    @Test func 短い表記() {
        #expect(TimeText.brief(90, locale: ja) == "1分30秒")
        #expect(TimeText.brief(45, locale: ja) == "45秒")
        #expect(TimeText.brief(600, locale: ja) == "10分")
        #expect(TimeText.brief(3600, locale: ja) == "60分")
        #expect(TimeText.brief(90, locale: en) == "1m30s")
        #expect(TimeText.brief(45, locale: en) == "45s")
        #expect(TimeText.brief(600, locale: en) == "10m")
    }
}
