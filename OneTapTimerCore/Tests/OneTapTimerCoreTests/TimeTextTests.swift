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

    @Test func 大きい数字はいつも秒だけ() {
        #expect(TimeText.seconds(90) == "90")
        #expect(TimeText.seconds(89.2) == "90")      // 切り上げ
        #expect(TimeText.seconds(89.0) == "89")
        #expect(TimeText.seconds(3600) == "3600")
        #expect(TimeText.seconds(0.4) == "1")
        #expect(TimeText.seconds(0) == "0")
        #expect(TimeText.seconds(90.0000000001) == "90")
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

    @Test("単位は言語ごとに変わる。知らない言語は英語に落ちる")
    func briefInManyLanguages() {
        #expect(TimeText.brief(90, locale: Locale(identifier: "ko_KR")) == "1분30초")
        #expect(TimeText.brief(90, locale: Locale(identifier: "ru_RU")) == "1м30с")
        #expect(TimeText.brief(45, locale: Locale(identifier: "tr_TR")) == "45sn")
        #expect(TimeText.brief(90, locale: Locale(identifier: "zh_Hans_CN")) == "1分30秒")
        #expect(TimeText.brief(90, locale: Locale(identifier: "zh_Hant_TW")) == "1分30秒")
        // 訳を持たない言語（フィンランド語）は英語と同じ
        #expect(TimeText.brief(90, locale: Locale(identifier: "fi_FI")) == "1m30s")
        #expect(TimeText.secondUnit(locale: Locale(identifier: "ja_JP")) == "秒")
    }

    @Test("画面に出る言語ぶんの単位がそろっている")
    func unitsCoverEveryLanguage() {
        for lang in ["en", "ja", "zh-Hans", "zh-Hant", "ko", "es", "fr", "de",
                     "it", "pt-BR", "ru", "ar", "nl", "sv", "tr", "id"] {
            #expect(Units.byLanguage[lang] != nil, "\(lang) の単位が無い")
        }
    }
}
