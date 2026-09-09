import Foundation

/// 色の組。設定の「色」ボタンで 1〜10 を順繰りに切り替える。
///
/// 水（走っている）・終わった画面・終わりが近い色を1組で持つ。
/// 数字は白で載せるので、**水の下端は白が読める暗さ**にする（テストで見る）。
/// 終わりが近い色は、水と見分けがつく色相にする（暖色の組では寒色にする）。
public struct ThemeHex: Sendable, Equatable {
    public let name: String
    public let liquidTop: UInt32
    public let liquidBottom: UInt32
    public let doneGround: UInt32
    public let doneInk: UInt32
    public let lastTop: UInt32
    public let lastBottom: UInt32

    static let amberTop: UInt32 = 0xF0961E
    static let amberBottom: UInt32 = 0xC96A05

    public static let all: [ThemeHex] = [
        ThemeHex(name: "ティール", liquidTop: 0x22B8AE, liquidBottom: 0x0F8A82, doneGround: 0xE9F3F1, doneInk: 0x0D3A3B, lastTop: amberTop, lastBottom: amberBottom),
        ThemeHex(name: "ブルー",   liquidTop: 0x3B9DF0, liquidBottom: 0x1867B8, doneGround: 0xEAF2FB, doneInk: 0x0F2E52, lastTop: amberTop, lastBottom: amberBottom),
        ThemeHex(name: "インディゴ", liquidTop: 0x6C7BEA, liquidBottom: 0x3F4BB5, doneGround: 0xEEF0FB, doneInk: 0x232A63, lastTop: amberTop, lastBottom: amberBottom),
        ThemeHex(name: "パープル", liquidTop: 0xA56BE8, liquidBottom: 0x6E3DB0, doneGround: 0xF3EEFB, doneInk: 0x3A1F60, lastTop: amberTop, lastBottom: amberBottom),
        ThemeHex(name: "ピンク",   liquidTop: 0xF06AA8, liquidBottom: 0xB83A73, doneGround: 0xFBEEF4, doneInk: 0x5A1A38, lastTop: amberTop, lastBottom: amberBottom),
        ThemeHex(name: "レッド",   liquidTop: 0xF0605A, liquidBottom: 0xB02E29, doneGround: 0xFBEEED, doneInk: 0x5A1614, lastTop: 0x22B8AE, lastBottom: 0x0F8A82),
        ThemeHex(name: "オレンジ", liquidTop: 0xF5923A, liquidBottom: 0xC25E0C, doneGround: 0xFBF0E6, doneInk: 0x5A2C08, lastTop: 0x22B8AE, lastBottom: 0x0F8A82),
        ThemeHex(name: "イエロー", liquidTop: 0xE6C02A, liquidBottom: 0x9E7F06, doneGround: 0xFBF6E3, doneInk: 0x4F3F05, lastTop: 0x3B9DF0, lastBottom: 0x1867B8),
        ThemeHex(name: "グリーン", liquidTop: 0x4FC46A, liquidBottom: 0x1F8A38, doneGround: 0xECF7EE, doneInk: 0x143F1E, lastTop: amberTop, lastBottom: amberBottom),
        ThemeHex(name: "グレー",   liquidTop: 0xA9B0B8, liquidBottom: 0x5F6770, doneGround: 0xF0F1F3, doneInk: 0x2A2E33, lastTop: amberTop, lastBottom: amberBottom),
    ]

    /// 1始まりの番号。範囲外なら 1
    public static func at(_ number: Int) -> ThemeHex {
        (1...all.count).contains(number) ? all[number - 1] : all[0]
    }

    /// 次の番号（10 の次は 1）
    public static func next(after number: Int) -> Int {
        number >= all.count || number < 1 ? 1 : number + 1
    }

    /// 終わった画面の弱い文字。濃い文字を薄める
    public var doneInkDim: UInt32 { PaletteHex.mix(doneInk, doneGround, 0.22) }
}
