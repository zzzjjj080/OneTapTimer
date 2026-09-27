// **iPhone だけの画面。** Watch には見た目を変える操作を置かない（画面が狭い）
#if os(iOS)
import SwiftUI
import OneTapTimerCore

/// 見た目を決める画面（iPhone だけ）。
///
/// **選択肢は文字で説明しない。小さな見本と番号（`W2` など）で並べる。**
/// 16言語ぶんの説明文を持たずに済み、本人とのやり取りも番号でできる
/// （見本表 `design/catalog-*.png` と同じ番号）。
///
/// 上の見本は**画面に貼り付けて動かし続ける**（2026-09-27 本人指示）。
/// 下を選びながら、その場で変わるのが見える。**60秒から0秒まで減って、また60秒に戻る。**
///
/// 選んだ瞬間に保存して Apple Watch へ送る。**「送る」ボタンは置かない**
/// （押し忘れたまま閉じられるより、常に最新が向こうにあるほうがよい）。
public struct DesignEditor: View {
    @Binding public var design: FaceDesign
    /// 見本に出す秒数（設定してある長さ）。文字盤の見本に出る
    public var duration: Int
    public var onTip: (() -> Void)?

    public init(design: Binding<FaceDesign>, duration: Int, onTip: (() -> Void)? = nil) {
        self._design = design; self.duration = duration; self.onTip = onTip
    }

    public var body: some View {
        VStack(spacing: 0) {
            // **貼り付けたまま動かす。** 下を選んでもここは隠れない
            PreviewBar(design: design, duration: duration)

            ScrollView {
                VStack(spacing: 22) {
                    section("文字盤")
                    // **色は文字盤とアプリで共通。** 両方の並びに出す
                    // （文字盤の所に無いと「色は変えられない」と見える。2026-09-27 本人の指摘）
                    row("色", \.color, dial: true)
                    row("中身", \.dialContent)
                    row("絵", \.dialMark)
                    row("輪", \.dialRing)
                    row("色の付け方", \.dialTint)
                    row("大きさ", \.dialSize)
                    row("書体", \.dialTypeface)

                    section("アプリの画面")
                    row("減り方", \.style)
                    row("色", \.color)
                    row("数字", \.digits)
                    row("大きさ", \.size)
                    row("書体", \.typeface)
                    row("文字の太さ", \.weight)
                    row("縁取り", \.outline)
                    row("置き場所", \.place)

                    Button { design = .standard } label: {
                        Text("はじめに戻す", bundle: .module)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: design.theme.liquidTop))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    if let onTip {
                        Button(action: onTip) {
                            Image(systemName: "heart")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color(hex: design.theme.liquidTop))
                                .frame(width: 52, height: 40)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("tip")
                    }

                    Text(BuildStamp.text)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.35))
                        .accessibilityIdentifier("buildStamp")
                        .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
        }
        .background(Color(hex: PaletteHex.ground).ignoresSafeArea())
    }

    private func section(_ title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.system(size: 13, weight: .bold))
            .tracking(1)
            .foregroundStyle(Color(hex: design.theme.liquidTop).opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 6)
    }

    /// 1種類ぶんの横並び。**見本はその項目だけを差し替えたもの**（ほかはいまの設定のまま）。
    /// `dial` を渡すと、その並びの見本を文字盤の丸で描く（色のように両方に出る項目のため）
    private func row<T: NumberedChoice>(_ title: LocalizedStringKey,
                                        _ key: WritableKeyPath<FaceDesign, T>,
                                        dial: Bool? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title, bundle: .module)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.8))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(T.allCases) { choice in
                        Chip(design: changing(key, to: choice), code: choice.code,
                             chosen: design[keyPath: key] == choice,
                             dial: dial ?? Self.isDial(key), duration: duration) {
                            design[keyPath: key] = choice
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    /// 文字盤の項目かどうか。見本の絵を丸にするか、画面にするかを決める
    private static func isDial<T>(_ key: WritableKeyPath<FaceDesign, T>) -> Bool {
        [\FaceDesign.dialContent as PartialKeyPath<FaceDesign>, \FaceDesign.dialMark,
         \FaceDesign.dialRing, \FaceDesign.dialTint, \FaceDesign.dialSize,
         \FaceDesign.dialTypeface].contains(key as PartialKeyPath<FaceDesign>)
    }

    /// いまの設定の、その項目だけを差し替えたもの
    private func changing<T>(_ key: WritableKeyPath<FaceDesign, T>, to value: T) -> FaceDesign {
        var d = design
        d[keyPath: key] = value
        return d
    }
}

/// 上に貼り付ける見本。**文字盤の丸とアプリの画面を並べ、いつも動いている。**
private struct PreviewBar: View {
    let design: FaceDesign
    let duration: Int

    /// 見本の周期。**60秒から0秒まで減って、また60秒に戻る**（2026-09-27 本人指示）
    static let loop: Double = 60

    /// いま何秒目か。時計から割り出すので、画面を作り直しても飛ばない
    private func engine(at now: Date) -> TimerEngine {
        let phase = now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Self.loop)
        return TimerEngine(duration: Int(Self.loop), startedAt: now.addingTimeInterval(-phase))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { t in
            HStack(spacing: 18) {
                // 文字盤（丸）。実寸に近い大きさで、黒い地に置く
                ZStack {
                    Circle().fill(Color(hex: 0x0B2E30))
                    DialFace(design: design, duration: duration, diameter: 62)
                }
                .frame(width: 62, height: 62)
                .accessibilityIdentifier("dialPreview")

                // アプリの画面（Apple Watch の形）
                DrainFace(engine: engine(at: t.date), now: t.date, design: design,
                          metrics: FaceMetrics(main: 52, sub: 12, label: 8, gap: 0))
                    .frame(width: 74, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(4)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color(white: 0.17))
                    }
                    .accessibilityIdentifier("preview")

                Text(design.text)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.4))
                    .lineLimit(4)
                    .accessibilityIdentifier("designCode")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(hex: 0x0A0A0A))
        .overlay(alignment: .bottom) {
            Rectangle().fill(.white.opacity(0.10)).frame(height: 1)
        }
    }
}

/// 選択肢ひとつ。**小さな見本と番号。**
private struct Chip: View {
    let design: FaceDesign
    let code: String
    let chosen: Bool
    /// 文字盤の項目なら丸を、アプリの項目なら画面を描く
    let dial: Bool
    let duration: Int
    let tap: () -> Void

    /// 見本は「90秒のうち58秒残り」で止めて描く。**選択肢の絵は動かさない**（上の見本が動いている）
    private var engine: TimerEngine {
        TimerEngine(duration: 90, startedAt: Date(timeIntervalSince1970: 0))
    }
    private var now: Date { Date(timeIntervalSince1970: 32) }

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 4) {
                Group {
                    if dial {
                        ZStack {
                            Circle().fill(Color(hex: 0x0B2E30))
                            DialFace(design: design, duration: duration, diameter: 54)
                        }
                        .frame(width: 54, height: 54)
                    } else {
                        DrainFace(engine: engine, now: now, design: design, metrics: .sample)
                            .frame(width: 54, height: 66)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .overlay {
                    Group {
                        if dial {
                            Circle().strokeBorder(borderColor, lineWidth: chosen ? 2.5 : 1)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(borderColor, lineWidth: chosen ? 2.5 : 1)
                        }
                    }
                }

                Text(code)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(chosen ? Color(hex: design.theme.liquidTop)
                                            : Color(hex: PaletteHex.ink).opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("choice-\(code)")
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }

    private var borderColor: Color {
        chosen ? Color(hex: design.theme.liquidTop) : .white.opacity(0.12)
    }
}
#endif
