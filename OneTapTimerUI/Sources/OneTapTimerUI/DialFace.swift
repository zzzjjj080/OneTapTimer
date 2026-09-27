import SwiftUI
import OneTapTimerCore

/// 文字盤（コンプリケーション）の丸の中身。**アプリの見本と、文字盤の本体で同じものを描く。**
///
/// 出すのは「設定してある秒数」だけ。**残り時間は出さない**（アプリから出た時点で止まるので、
/// 文字盤を見ているときに走っていることはあり得ない。1.0.1 で一度出して、古い値が残って見えた）。
///
/// **`GeometryReader` を使わない。** コンプリケーションの枠は極端に小さく、
/// 測らせると 0 や NaN が返って描画ごと落ちることがある。寸法は直径から決め打ちで割り出す。
public struct DialFace: View {
    public var design: FaceDesign
    /// 設定してある秒数
    public var duration: Int
    /// 丸の直径。文字盤の実寸は 42pt ほど
    public var diameter: CGFloat
    /// 文字盤が単色に着色されるとき（`.accented` など）は false。色を乗せずに白で描く
    public var fullColor: Bool

    public init(design: FaceDesign, duration: Int, diameter: CGFloat, fullColor: Bool = true) {
        self.design = design; self.duration = duration
        self.diameter = diameter; self.fullColor = fullColor
    }

    private var accent: Color { fullColor ? Color(hex: design.theme.liquidTop) : .white }

    /// V 色の付け方。塗りつぶしのときだけ、中の文字を地の色にする
    private var inkColor: Color {
        switch design.dialTint {
        case .colored: fullColor ? accent : .white
        case .plain: .white
        case .filled: fullColor ? Color(hex: PaletteHex.ground) : .black
        }
    }

    private var fontDesign: Font.Design {
        switch design.dialTypeface {
        case .rounded: .rounded
        case .standard: .default
        case .monospaced: .monospaced
        }
    }

    /// 数字の大きさ。**絵と並べるときは小さく、数字だけなら大きく**
    private var numberSize: CGFloat {
        let base: CGFloat = design.dialContent == .markAndNumber ? 0.36 : 0.52
        return diameter * base * design.dialSize.ratio
    }

    private var markSize: CGFloat {
        let base: CGFloat = design.dialContent == .markOnly ? 0.52 : 0.30
        return diameter * base * design.dialSize.ratio
    }

    public var body: some View {
        ZStack {
            if design.dialTint == .filled {
                Circle().fill(fullColor ? accent : Color.white)
            }
            DialRingArt(ring: design.dialRing, color: fullColor ? accent : .white,
                        diameter: diameter, dimmed: !fullColor)
            VStack(spacing: -diameter * 0.02) {
                if design.dialContent.showsMark {
                    Image(systemName: design.dialMark.symbol)
                        .font(.system(size: markSize, weight: .semibold))
                        .foregroundStyle(inkColor)
                        .widgetAccentable()
                }
                if design.dialContent.showsNumber {
                    HStack(alignment: .firstTextBaseline, spacing: diameter * 0.02) {
                        Text("\(duration)")
                            .font(.system(size: numberSize, weight: .heavy, design: fontDesign))
                            .monospacedDigit()
                        if design.dialContent == .numberAndUnit {
                            Text(Units.of(.current).second)
                                .font(.system(size: numberSize * 0.5, weight: .semibold, design: fontDesign))
                        }
                    }
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(inkColor)
                }
            }
            .padding(.horizontal, diameter * 0.12)
        }
        .frame(width: diameter, height: diameter)
    }

}

/// R 輪だけ。**選択肢の見本では、輪のほかに何も描かない**
/// （2026-09-27 本人指示。数字や絵まで出ていると、どれを選んでいるのか分からない）。
///
/// 太さは実寸（直径42pt）で見て、細い＝2pt・太い＝4pt になる比にしてある。
public struct DialRingArt: View {
    public var ring: DialRing
    public var color: Color
    public var diameter: CGFloat
    public var dimmed: Bool

    public init(ring: DialRing, color: Color, diameter: CGFloat, dimmed: Bool = false) {
        self.ring = ring; self.color = color; self.diameter = diameter; self.dimmed = dimmed
    }

    private var stroke: Color { color.opacity(dimmed ? 0.55 : 0.85) }

    public var body: some View {
        switch ring {
        case .none:
            EmptyView()
        case .thin:
            Circle().strokeBorder(stroke, lineWidth: diameter * 0.048)
        case .thick:
            Circle().strokeBorder(stroke, lineWidth: diameter * 0.095)
        case .dotted:
            Circle().strokeBorder(stroke, style: StrokeStyle(lineWidth: diameter * 0.07,
                                                             dash: [diameter * 0.09, diameter * 0.07]))
        }
    }
}
