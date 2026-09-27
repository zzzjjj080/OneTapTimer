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





// MARK: - 文字盤（コンプリケーション）
//
// **押すとアプリが開くだけの部品**だが、文字盤にはこれが出ているので、**見た目はここがいちばん目に入る。**
// 出せるのは「設定してある秒数」だけ（残り時間は出さない。アプリから出た時点で止まるため）。

/// W 中身
public enum DialContent: NumberedChoice {
    /// 絵の下に秒数（1.2 までと同じ）
    case markAndNumber
    /// 数字だけ大きく
    case numberOnly
    /// 数字と単位（`90s`）
    case numberAndUnit
    /// 絵だけ
    case markOnly

    public var code: String {
        switch self {
        case .markAndNumber: "W1"; case .numberOnly: "W2"
        case .numberAndUnit: "W3"; case .markOnly: "W4"
        }
    }
    public var label: String {
        switch self {
        case .markAndNumber: "絵と数字"; case .numberOnly: "数字だけ"
        case .numberAndUnit: "数字と単位"; case .markOnly: "絵だけ"
        }
    }
    public var showsNumber: Bool { self != .markOnly }
    public var showsMark: Bool { self == .markAndNumber || self == .markOnly }
    public static let fallback = DialContent.markAndNumber
}

/// I 絵
public enum DialMark: NumberedChoice {
    case stopwatch, timer, hourglass, bolt, drop

    public var code: String {
        switch self {
        case .stopwatch: "I1"; case .timer: "I2"; case .hourglass: "I3"
        case .bolt: "I4"; case .drop: "I5"
        }
    }
    public var label: String {
        switch self {
        case .stopwatch: "ストップウォッチ"; case .timer: "タイマー"; case .hourglass: "砂時計"
        case .bolt: "稲妻"; case .drop: "しずく"
        }
    }
    /// SF Symbols の名前。**watchOS 11 に無い記号を選ばない**（出ないと四角が出る）
    public var symbol: String {
        switch self {
        case .stopwatch: "stopwatch"; case .timer: "timer"; case .hourglass: "hourglass"
        case .bolt: "bolt.fill"; case .drop: "drop.fill"
        }
    }
    public static let fallback = DialMark.stopwatch
}

/// R 輪（丸い枠の中の縁取り）
public enum DialRing: NumberedChoice {
    case none, thin, thick, dotted

    public var code: String {
        switch self { case .none: "R1"; case .thin: "R2"; case .thick: "R3"; case .dotted: "R4" }
    }
    public var label: String {
        switch self { case .none: "なし"; case .thin: "細い輪"; case .thick: "太い輪"; case .dotted: "点線" }
    }
    public static let fallback = DialRing.none
}

/// V 色の付け方
public enum DialTint: NumberedChoice {
    /// 文字も絵も色つき
    case colored
    /// 白（文字盤の色に任せる）
    case plain
    /// 中を色で塗りつぶし、文字は黒
    case filled

    public var code: String {
        switch self { case .colored: "V1"; case .plain: "V2"; case .filled: "V3" }
    }
    public var label: String {
        switch self { case .colored: "色つき"; case .plain: "白"; case .filled: "塗りつぶし" }
    }
    public static let fallback = DialTint.colored
}

/// U 文字の大きさ（文字盤の中）
public enum DialSize: NumberedChoice {
    case small, medium, large

    public var code: String {
        switch self { case .small: "U1"; case .medium: "U2"; case .large: "U3" }
    }
    public var label: String {
        switch self { case .small: "小"; case .medium: "中"; case .large: "大" }
    }
    public var ratio: Double {
        switch self { case .small: 0.78; case .medium: 1.0; case .large: 1.22 }
    }
    public static let fallback = DialSize.medium
}

/// J 書体（文字盤の中）
public enum DialTypeface: NumberedChoice {
    case rounded, standard, monospaced

    public var code: String {
        switch self { case .rounded: "J1"; case .standard: "J2"; case .monospaced: "J3" }
    }
    public var label: String {
        switch self { case .rounded: "丸ゴシック"; case .standard: "標準"; case .monospaced: "等幅" }
    }
    public static let fallback = DialTypeface.rounded
}

/// 見た目ひと組。**iPhone で決めて、Watch へ送る。**
public struct FaceDesign: Codable, Equatable, Sendable {
    // 走っている画面（アプリ）
    public var style: FaceStyle
    public var color: FaceColor
    public var digits: FaceDigits
    public var size: FaceSize
    public var typeface: FaceTypeface
    public var weight: FaceWeight
    public var outline: FaceOutline
    public var place: FacePlace

    // 文字盤（コンプリケーション）。**本人がいちばん見るのはこちら**
    public var dialContent: DialContent
    public var dialMark: DialMark
    public var dialRing: DialRing
    public var dialTint: DialTint
    public var dialSize: DialSize
    public var dialTypeface: DialTypeface

    public init(style: FaceStyle = .fallback, color: FaceColor = .fallback,
                digits: FaceDigits = .fallback, size: FaceSize = .fallback,
                typeface: FaceTypeface = .fallback, weight: FaceWeight = .fallback,
                outline: FaceOutline = .fallback, place: FacePlace = .fallback,
                dialContent: DialContent = .fallback, dialMark: DialMark = .fallback,
                dialRing: DialRing = .fallback, dialTint: DialTint = .fallback,
                dialSize: DialSize = .fallback, dialTypeface: DialTypeface = .fallback) {
        self.style = style; self.color = color; self.digits = digits; self.size = size
        self.typeface = typeface; self.weight = weight; self.outline = outline; self.place = place
        self.dialContent = dialContent; self.dialMark = dialMark; self.dialRing = dialRing
        self.dialTint = dialTint; self.dialSize = dialSize; self.dialTypeface = dialTypeface
    }

    /// 1.2 までの見た目（色だけ選べた頃）と同じ組み合わせ
    public static let standard = FaceDesign()

    /// 1行で表す（例：`Y1 C1 N1 S3 T1 F3 O1 P1 W1 I1 R1 V1 U2 J1`）
    public var text: String {
        [style.code, color.code, digits.code, size.code, typeface.code, weight.code,
         outline.code, place.code,
         dialContent.code, dialMark.code, dialRing.code, dialTint.code, dialSize.code,
         dialTypeface.code].joined(separator: " ")
    }

    /// 1行から戻す。**知らない番号は既定に落とす**（選択肢を消しても壊れない）
    public init(text: String) {
        let codes = Set(text.split(separator: " ").map(String.init))
        func pick<T: NumberedChoice>(_ t: T.Type) -> T {
            T.allCases.first { codes.contains($0.code) } ?? .fallback
        }
        self.init(style: pick(FaceStyle.self), color: pick(FaceColor.self),
                  digits: pick(FaceDigits.self), size: pick(FaceSize.self),
                  typeface: pick(FaceTypeface.self), weight: pick(FaceWeight.self),
                  outline: pick(FaceOutline.self), place: pick(FacePlace.self),
                  dialContent: pick(DialContent.self), dialMark: pick(DialMark.self),
                  dialRing: pick(DialRing.self), dialTint: pick(DialTint.self),
                  dialSize: pick(DialSize.self), dialTypeface: pick(DialTypeface.self))
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
