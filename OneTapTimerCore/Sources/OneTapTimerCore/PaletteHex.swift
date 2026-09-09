import Foundation

/// 色の数値。Watch と iPhone とアイコンで同じ値を使う。
///
/// 画面は3つの状態しか無い。**動いている／終わりが近い／終わった。**
/// 状態ごとに「水の色・地の色・数字の色」を組で持つ。
public enum PaletteHex {

    // 動いている：黒い地に、ティールの水
    public static let ground: UInt32 = 0x000000
    public static let liquidTop: UInt32 = 0x22B8AE
    public static let liquidBottom: UInt32 = 0x0F8A82
    public static let ink: UInt32 = 0xFFFFFF
    public static let inkDim: UInt32 = 0xB8E6E2

    // 終わりが近い：水が琥珀へ
    public static let lastTop: UInt32 = 0xF0961E
    public static let lastBottom: UInt32 = 0xC96A05

    // 終わった：画面が白く抜ける。遠目でも「済んだ」と分かる
    public static let doneGround: UInt32 = 0xE9F3F1
    public static let doneInk: UInt32 = 0x0D3A3B
    public static let doneInkDim: UInt32 = 0x3F6D6C

    // 設定画面の押せるもの
    public static let well: UInt32 = 0x122A2C
    public static let accent: UInt32 = 0x2BC2B7

    /// 2色を混ぜる。`t` が 0 なら a、1 なら b
    public static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func ch(_ shift: UInt32) -> UInt32 {
            let x = Double((a >> shift) & 0xFF), y = Double((b >> shift) & 0xFF)
            return UInt32((x + (y - x) * t).rounded()) & 0xFF
        }
        return (ch(16) << 16) | (ch(8) << 8) | ch(0)
    }

    // MARK: - コントラスト

    /// WCAG の相対輝度。
    public static func luminance(_ hex: UInt32) -> Double {
        func channel(_ v: UInt32) -> Double {
            let c = Double(v & 0xFF) / 255
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(hex >> 16) + 0.7152 * channel(hex >> 8) + 0.0722 * channel(hex)
    }

    /// コントラスト比。4.5 以上が本文、3.0 以上が大きい文字の目安。
    public static func contrast(_ a: UInt32, _ b: UInt32) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }
}
