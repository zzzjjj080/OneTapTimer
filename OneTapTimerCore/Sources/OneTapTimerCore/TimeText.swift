import Foundation

/// 秒数を文字にする。
///
/// **切り上げる。** 開始直後に `1:30` と出て、1秒後に `1:29` へ落ちるのが正しい。
/// 切り捨てにすると開始した瞬間に `1:29` と出て、1秒損したように見える。
public enum TimeText {

    /// 浮動小数の誤差で `90.0000000001` のような値が来たときに `1:31` と出さないための余裕。
    private static let epsilon = 1e-6

    /// 切り上げた整数秒。
    public static func wholeSeconds(_ seconds: Double) -> Int {
        Int(ceil(max(0, seconds) - epsilon))
    }

    /// `m:ss`。1時間は `60:00`（時は出さない。最大が1時間なので桁を増やさない）。
    public static func clock(_ seconds: Double) -> String {
        let s = wholeSeconds(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// 1分を切ったら秒だけを出すか。
    public static func showsSecondsOnly(_ seconds: Double) -> Bool {
        wholeSeconds(seconds) < 60
    }

    /// 画面の大きい数字。**1分を切ったら秒だけ**（`45`）、それまでは `m:ss`。
    public static func display(_ seconds: Double) -> String {
        let s = wholeSeconds(seconds)
        return s < 60 ? String(s) : clock(seconds)
    }

    /// `1分30秒` `45秒` `10分` / 英語なら `1m30s` `45s` `10m`。設定の値やチップに使う。
    ///
    /// 数字の書式は String Catalog では拾えない。訳文の中に単位を混ぜると英語版に「分」が残る。
    /// **ここで言語ごとに組み立てる。**
    public static func brief(_ seconds: Int, locale: Locale = .current) -> String {
        let s = max(0, seconds)
        let m = s / 60, sec = s % 60
        let (mu, su) = units(for: locale)
        if m == 0 { return "\(sec)\(su)" }
        if sec == 0 { return "\(m)\(mu)" }
        return "\(m)\(mu)\(sec)\(su)"
    }

    private static func units(for locale: Locale) -> (String, String) {
        locale.language.languageCode == .japanese ? ("分", "秒") : ("m", "s")
    }
}
