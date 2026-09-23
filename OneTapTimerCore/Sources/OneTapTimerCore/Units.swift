import Foundation

/// 分と秒の短い単位。**`Tools-GenTranslations.py` が作る。手で直さない**
/// （直すのは `translations.json`）。
///
/// 文字列カタログは数字と混ぜた形を拾えないので、ここだけ表にしている。
public enum Units {

    /// 言語コード → (分, 秒)。
    public static let byLanguage: [String: (minute: String, second: String)] = [
        "en": ("m", "s"),
        "ja": ("分", "秒"),
        "zh-Hans": ("分", "秒"),
        "zh-Hant": ("分", "秒"),
        "ko": ("분", "초"),
        "es": ("m", "s"),
        "fr": ("m", "s"),
        "de": ("m", "s"),
        "it": ("m", "s"),
        "pt-BR": ("m", "s"),
        "ru": ("м", "с"),
        "ar": ("د", "ث"),
        "nl": ("m", "s"),
        "sv": ("m", "s"),
        "tr": ("dk", "sn"),
        "id": ("m", "d")
    ]

    /// 端末の言語に合う単位。知らない言語は英語（`m` / `s`）。
    /// 中国語は簡体字と繁体字で同じなので、地域までは見ない。
    public static func of(_ locale: Locale) -> (minute: String, second: String) {
        let code = locale.language.languageCode?.identifier ?? "en"
        if code == "zh" { return byLanguage["zh-Hans"] ?? ("m", "s") }
        return byLanguage[code] ?? byLanguage["en"]!
    }
}
