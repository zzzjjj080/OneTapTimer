import Foundation

// タイマーの画面の見た目。**どの選択肢にも一意の番号を付ける。**
// 本人が見本表（`design/catalog-*.png`）を見て「K5 を消す」と番号で言えるようにするため。
//
// 決まり（STEPSKIN と同じ）
// - 頭の1〜2文字で種類が分かる
// - **番号は 1 から連番。抜けを作らない。** 足し引きしたらその種類ぜんぶを振り直す（テストで固定）
// - 保存は番号の文字（`Y1 C1 …`）。**知らない番号は既定に落ちるだけで落ちない**

/// 番号の付いた選択肢
public protocol NumberedChoice: CaseIterable, Identifiable, Hashable, Sendable where AllCases == [Self] {
    var code: String { get }
    var label: String { get }
    static var fallback: Self { get }
}

extension NumberedChoice {
    public var id: String { code }
    /// 保存された番号から戻す。消した番号・知らない番号は既定
    public static func from(code: String?) -> Self { allCases.first { $0.code == code } ?? fallback }
}

/// Y 減り方
public enum FaceStyle: NumberedChoice {
    /// 画面いっぱいの水が減る（1.0 からの形）
    case liquid
    /// 輪が減る
    case ring
    /// 細い棒が減る
    case bar
    /// 色の地が、終わりへ向かって薄れる
    case fade

    public var code: String {
        switch self { case .liquid: "Y1"; case .ring: "Y2"; case .bar: "Y3"; case .fade: "Y4" }
    }
    public var label: String {
        switch self { case .liquid: "水が減る"; case .ring: "輪が減る"; case .bar: "棒が減る"; case .fade: "色が薄れる" }
    }
    public static let fallback = FaceStyle.liquid
}

/// C 色。`ThemeHex.all` と同じ並び
public enum FaceColor: NumberedChoice {
    case teal, blue, indigo, purple, pink, red, orange, yellow, green, gray

    public var code: String {
        switch self {
        case .teal: "C1"; case .blue: "C2"; case .indigo: "C3"; case .purple: "C4"; case .pink: "C5"
        case .red: "C6"; case .orange: "C7"; case .yellow: "C8"; case .green: "C9"; case .gray: "C10"
        }
    }
    public var label: String { ThemeHex.at(number).name }
    /// `ThemeHex` の1始まりの番号
    public var number: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }
    public var theme: ThemeHex { ThemeHex.at(number) }
    public static let fallback = FaceColor.teal
}

/// G 塗り方
public enum FaceFill: NumberedChoice {
    case gradient, solid, deepening

    public var code: String {
        switch self { case .gradient: "G1"; case .solid: "G2"; case .deepening: "G3" }
    }
    public var label: String {
        switch self { case .gradient: "上下グラデ"; case .solid: "単色"; case .deepening: "進むほど濃く" }
    }
    public static let fallback = FaceFill.gradient
}

/// D 減る向き（水と棒のとき。輪は右回りで固定）
public enum FaceDirection: NumberedChoice {
    case down, up, left, right

    public var code: String {
        switch self { case .down: "D1"; case .up: "D2"; case .left: "D3"; case .right: "D4" }
    }
    public var label: String {
        switch self { case .down: "下へ"; case .up: "上へ"; case .left: "左へ"; case .right: "右へ" }
    }
    public static let fallback = FaceDirection.down
}

/// B 地の色
public enum FaceGround: NumberedChoice {
    case black, charcoal, deepColor, white

    public var code: String {
        switch self { case .black: "B1"; case .charcoal: "B2"; case .deepColor: "B3"; case .white: "B4" }
    }
    public var label: String {
        switch self { case .black: "黒"; case .charcoal: "濃い灰"; case .deepColor: "色の濃い側"; case .white: "白" }
    }
    public static let fallback = FaceGround.black
}

/// N 数字の出し方
public enum FaceDigits: NumberedChoice {
    /// 残りの秒だけ（`85`）と、下に小さく `1:25`
    case secondsWithClock
    /// 残りの秒だけ
    case secondsOnly
    /// `1:25` だけ
    case clockOnly
    /// 数字を出さない（形だけで見る）
    case none

    public var code: String {
        switch self {
        case .secondsWithClock: "N1"; case .secondsOnly: "N2"; case .clockOnly: "N3"; case .none: "N4"
        }
    }
    public var label: String {
        switch self {
        case .secondsWithClock: "秒＋時計"; case .secondsOnly: "秒だけ"; case .clockOnly: "時計だけ"; case .none: "出さない"
        }
    }
    public static let fallback = FaceDigits.secondsWithClock
}

/// S 数字の大きさ（基準に対する割合）
public enum FaceSize: NumberedChoice {
    case small, medium, large, huge

    public var code: String {
        switch self { case .small: "S1"; case .medium: "S2"; case .large: "S3"; case .huge: "S4" }
    }
    public var label: String {
        switch self { case .small: "小"; case .medium: "中"; case .large: "大"; case .huge: "特大" }
    }
    public var ratio: Double {
        switch self { case .small: 0.62; case .medium: 0.8; case .large: 1.0; case .huge: 1.18 }
    }
    public static let fallback = FaceSize.large
}

/// T 書体
public enum FaceTypeface: NumberedChoice {
    case rounded, standard, serif, monospaced

    public var code: String {
        switch self { case .rounded: "T1"; case .standard: "T2"; case .serif: "T3"; case .monospaced: "T4" }
    }
    public var label: String {
        switch self { case .rounded: "丸ゴシック"; case .standard: "標準"; case .serif: "明朝"; case .monospaced: "等幅" }
    }
    public static let fallback = FaceTypeface.rounded
}

/// F 文字の太さ
public enum FaceWeight: NumberedChoice {
    case light, medium, heavy

    public var code: String {
        switch self { case .light: "F1"; case .medium: "F2"; case .heavy: "F3" }
    }
    public var label: String {
        switch self { case .light: "細"; case .medium: "中"; case .heavy: "太" }
    }
    public static let fallback = FaceWeight.heavy
}

/// K 文字の色
public enum FaceInk: NumberedChoice {
    case white, dim, black, cream, colored

    public var code: String {
        switch self {
        case .white: "K1"; case .dim: "K2"; case .black: "K3"; case .cream: "K4"; case .colored: "K5"
        }
    }
    public var label: String {
        switch self {
        case .white: "白"; case .dim: "うすい白"; case .black: "黒"; case .cream: "クリーム"; case .colored: "色と同じ"
        }
    }
    public static let fallback = FaceInk.white
}

/// O 縁取り
public enum FaceOutline: NumberedChoice {
    case shadow, none, stroke

    public var code: String {
        switch self { case .shadow: "O1"; case .none: "O2"; case .stroke: "O3" }
    }
    public var label: String {
        switch self { case .shadow: "影"; case .none: "なし"; case .stroke: "黒ぶち" }
    }
    public static let fallback = FaceOutline.shadow
}

/// P 数字の置き場所
public enum FacePlace: NumberedChoice {
    case center, top, bottom

    public var code: String {
        switch self { case .center: "P1"; case .top: "P2"; case .bottom: "P3" }
    }
    public var label: String {
        switch self { case .center: "真ん中"; case .top: "上寄り"; case .bottom: "下寄り" }
    }
    public static let fallback = FacePlace.center
}

/// L 終わりが近いとき（残り10秒）
public enum FaceLast: NumberedChoice {
    case amber, same, red, blink

    public var code: String {
        switch self { case .amber: "L1"; case .same: "L2"; case .red: "L3"; case .blink: "L4" }
    }
    public var label: String {
        switch self { case .amber: "琥珀になる"; case .same: "変えない"; case .red: "赤になる"; case .blink: "点滅" }
    }
    public static let fallback = FaceLast.amber
}

/// E 終わった画面
public enum FaceDone: NumberedChoice {
    case bright, dark, filled

    public var code: String {
        switch self { case .bright: "E1"; case .dark: "E2"; case .filled: "E3" }
    }
    public var label: String {
        switch self { case .bright: "白く抜ける"; case .dark: "暗いまま"; case .filled: "色で埋める" }
    }
    public static let fallback = FaceDone.bright
}

/// M 目盛り
public enum FaceTicks: NumberedChoice {
    case none, quarters, tenths

    public var code: String {
        switch self { case .none: "M1"; case .quarters: "M2"; case .tenths: "M3" }
    }
    public var label: String {
        switch self { case .none: "なし"; case .quarters: "4つ"; case .tenths: "10個" }
    }
    public static let fallback = FaceTicks.none
}

/// 見た目ひと組。**iPhone で決めて、Watch へ送る。**
public struct FaceDesign: Codable, Equatable, Sendable {
    public var style: FaceStyle
    public var color: FaceColor
    public var fill: FaceFill
    public var direction: FaceDirection
    public var ground: FaceGround
    public var digits: FaceDigits
    public var size: FaceSize
    public var typeface: FaceTypeface
    public var weight: FaceWeight
    public var ink: FaceInk
    public var outline: FaceOutline
    public var place: FacePlace
    public var last: FaceLast
    public var done: FaceDone
    public var ticks: FaceTicks

    public init(style: FaceStyle = .fallback, color: FaceColor = .fallback, fill: FaceFill = .fallback,
                direction: FaceDirection = .fallback, ground: FaceGround = .fallback,
                digits: FaceDigits = .fallback, size: FaceSize = .fallback,
                typeface: FaceTypeface = .fallback, weight: FaceWeight = .fallback,
                ink: FaceInk = .fallback, outline: FaceOutline = .fallback, place: FacePlace = .fallback,
                last: FaceLast = .fallback, done: FaceDone = .fallback, ticks: FaceTicks = .fallback) {
        self.style = style; self.color = color; self.fill = fill; self.direction = direction
        self.ground = ground; self.digits = digits; self.size = size; self.typeface = typeface
        self.weight = weight; self.ink = ink; self.outline = outline; self.place = place
        self.last = last; self.done = done; self.ticks = ticks
    }

    /// 1.1 までの見た目（色だけ選べた頃）と同じ組み合わせ
    public static let standard = FaceDesign()

    /// 1行で表す（例：`Y1 C1 G1 D1 B1 N1 S3 T1 F3 K1 O1 P1 L1 E1 M1`）
    public var text: String {
        [style.code, color.code, fill.code, direction.code, ground.code, digits.code, size.code,
         typeface.code, weight.code, ink.code, outline.code, place.code, last.code, done.code,
         ticks.code].joined(separator: " ")
    }

    /// 1行から戻す。**知らない番号は既定に落とす**（選択肢を消しても壊れない）
    public init(text: String) {
        let codes = Set(text.split(separator: " ").map(String.init))
        func pick<T: NumberedChoice>(_ t: T.Type) -> T {
            T.allCases.first { codes.contains($0.code) } ?? .fallback
        }
        self.init(style: pick(FaceStyle.self), color: pick(FaceColor.self), fill: pick(FaceFill.self),
                  direction: pick(FaceDirection.self), ground: pick(FaceGround.self),
                  digits: pick(FaceDigits.self), size: pick(FaceSize.self),
                  typeface: pick(FaceTypeface.self), weight: pick(FaceWeight.self),
                  ink: pick(FaceInk.self), outline: pick(FaceOutline.self), place: pick(FacePlace.self),
                  last: pick(FaceLast.self), done: pick(FaceDone.self), ticks: pick(FaceTicks.self))
    }

    /// 色の組。水・終わりが近い色・終わった画面はここから取る
    public var theme: ThemeHex { color.theme }
}

// **保存も送信も1行の文字（`Y1 C1 …`）で行う。**
// 項目ごとの JSON にすると、選択肢を足したときに古い端末で復号が丸ごと失敗する。
// 文字なら、知らない番号はその項目だけ既定へ落ちる
extension FaceDesign {
    public init(from decoder: Decoder) throws {
        self.init(text: try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(text)
    }
}
