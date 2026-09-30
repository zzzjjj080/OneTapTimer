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

    public init(design: Binding<FaceDesign>, duration: Int) {
        self._design = design; self.duration = duration
    }

    /// 作者の他のアプリ（App Store の開発者ページ）。
    /// **1.4 で投げ銭をやめ、その場所をここに替えた**（2026-09-30 本人決定）。
    /// 押すと App Store が開く。アプリ自身は通信しない
    static let otherApps = URL(string: "https://apps.apple.com/jp/developer/jin-nakamura/id6802013586")!

    public var body: some View {
        VStack(spacing: 0) {
            // **貼り付けたまま動かす。** 下を選んでもここは隠れない
            PreviewBar(design: design, duration: duration)

            ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing: 22) {
                    section("文字盤")
                    // **色は文字盤とアプリで共通。** 両方の並びに出す
                    // （文字盤の所に無いと「色は変えられない」と見える。2026-09-27 本人の指摘）
                    row("色", \.color, art: .swatch)
                    row("中身", \.dialContent, art: .dial)
                    row("絵", \.dialMark, art: .symbol)
                    row("輪", \.dialRing, art: .ring)
                    row("色の付け方", \.dialTint, art: .dial)
                    row("大きさ", \.dialSize, art: .dialNumber)
                    row("書体", \.dialTypeface, art: .dialNumber)

                    section("アプリの画面")
                    row("減り方", \.style, art: .meter)
                    row("色", \.color, art: .swatch)
                    row("数字", \.digits, art: .digits)
                    row("大きさ", \.size, art: .digits)
                    row("書体", \.typeface, art: .digits)
                    row("文字の太さ", \.weight, art: .digits)
                    row("縁取り", \.outline, art: .face)
                    row("置き場所", \.place, art: .placement)

                    Button { design = .standard } label: {
                        Text("はじめに戻す", bundle: .module)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: design.theme.liquidTop))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)

                    // **1行の控えめなリンク。** 押すと App Store の開発者ページが開く
                    Link(destination: Self.otherApps) {
                        HStack(spacing: 6) {
                            Text("作者の他のアプリ", bundle: .module)
                            Image(systemName: "arrow.up.forward")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.55))
                    }
                    .accessibilityIdentifier("otherApps")

                    Text(BuildStamp.text)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.35))
                        .accessibilityIdentifier("buildStamp")
                        .id("いちばん下")
                        .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .onAppear {
                #if DEBUG
                // 撮影用。**リリース構成には入らない**（`OTT_SHOT=face` でアプリの画面の並びまで送る）
                switch ProcessInfo.processInfo.environment["OTT_SHOT"] {
                case "face": scroll.scrollTo("アプリの画面", anchor: .top)
                case "bottom": scroll.scrollTo("いちばん下", anchor: .bottom)
                default: break
                }
                #endif
            }
            }
        }
        .background(Color(hex: PaletteHex.ground).ignoresSafeArea())
    }

    private func section(_ title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .id(title == "アプリの画面" ? "アプリの画面" : "文字盤")
            .font(.system(size: 13, weight: .bold))
            .tracking(1)
            .foregroundStyle(Color(hex: design.theme.liquidTop).opacity(0.9))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 6)
    }

    /// 1種類ぶんの横並び。**見本はその項目だけを描く**（2026-09-27 本人指示。
    /// 色なら色だけ、絵なら絵だけ。ほかの要素まで出ていると、どれを選んでいるのか分からない）
    private func row<T: NumberedChoice>(_ title: LocalizedStringKey,
                                        _ key: WritableKeyPath<FaceDesign, T>,
                                        art: ChipArt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title, bundle: .module)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.8))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(T.allCases) { choice in
                        Chip(design: changing(key, to: choice), code: choice.code, art: art,
                             chosen: design[keyPath: key] == choice, duration: duration) {
                            design[keyPath: key] = choice
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
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

/// 見本に何を描くか。**選んでいる項目だけを描く**（2026-09-27 本人指示）
enum ChipArt {
    /// 文字盤の丸ごと（中身・色の付け方）
    case dial
    /// 絵だけ
    case symbol
    /// 輪だけ
    case ring
    /// 色だけ
    case swatch
    /// 文字盤の数字だけ（大きさ・書体）
    case dialNumber
    /// アプリの画面の形だけ（減り方）
    case meter
    /// アプリの画面の数字だけ（数字・大きさ・書体・太さ・縁取り）
    case digits
    /// 画面の枠と、数字の置き場所
    case placement
    /// アプリの画面まるごと（縁取りは水の上でしか違いが見えない）
    case face

    /// 見本の形。丸か、画面（角の丸い長方形）か
    var isRound: Bool {
        switch self {
        case .dial, .symbol, .ring, .swatch, .dialNumber: true
        case .meter, .digits, .placement, .face: false
        }
    }
}

/// 選択肢ひとつ。**その項目だけの小さな見本と、番号。**
private struct Chip: View {
    let design: FaceDesign
    let code: String
    let art: ChipArt
    let chosen: Bool
    let duration: Int
    let tap: () -> Void

    /// 見本は「90秒のうち58秒残り」で止めて描く。**選択肢の絵は動かさない**（上の見本が動いている）
    private var engine: TimerEngine { TimerEngine(duration: 90, startedAt: Date(timeIntervalSince1970: 0)) }
    private var now: Date { Date(timeIntervalSince1970: 32) }

    private var accent: Color { Color(hex: design.theme.liquidTop) }
    /// 文字盤の地。**黒を敷く**（iPhone の明るい画面でも、文字盤での見え方に近づける）
    private var dialGround: Color { Color(hex: 0x0B2E30) }
    private static let round: CGFloat = 54
    private static let screen = CGSize(width: 54, height: 66)

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 4) {
                // **選んでいる印は見本の外側に描く。** 見本に重ねると、
                // 「輪なし（R1）」が輪に見えてしまう（2026-09-27 本人の指摘）
                picture
                    .padding(5)
                    .overlay {
                        if chosen {
                            if art.isRound {
                                Circle().strokeBorder(accent, lineWidth: 2.5)
                            } else {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(accent, lineWidth: 2.5)
                            }
                        }
                    }

                Text(code)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(chosen ? accent : Color(hex: PaletteHex.ink).opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("choice-\(code)")
        .accessibilityAddTraits(chosen ? [.isSelected] : [])
    }

    @ViewBuilder
    private var picture: some View {
        switch art {
        case .dial:
            inCircle { DialFace(design: design, duration: duration, diameter: Self.round) }

        case .symbol:
            inCircle {
                Image(systemName: design.dialMark.symbol)
                    .font(.system(size: Self.round * 0.42, weight: .semibold))
                    .foregroundStyle(accent)
            }

        case .ring:
            inCircle {
                DialRingArt(ring: design.dialRing, color: accent, diameter: Self.round)
            }

        case .swatch:
            // 色だけ。水の上端から下端までの塗りをそのまま出す
            Circle()
                .fill(LinearGradient(colors: [Color(hex: design.theme.liquidTop),
                                              Color(hex: design.theme.liquidBottom)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: Self.round, height: Self.round)

        case .dialNumber:
            inCircle { DialFace(design: numberOnly, duration: duration, diameter: Self.round) }

        case .meter:
            inScreen {
                DrainFace(engine: engine, now: now, design: design, metrics: .sample,
                          showsDigits: false)
            }

        case .face:
            inScreen { DrainFace(engine: engine, now: now, design: design, metrics: .sample) }

        case .digits, .placement:
            inScreen {
                DrainFace(engine: engine, now: now, design: design, metrics: .sample,
                          showsMeter: false)
            }
        }
    }

    private func inCircle(@ViewBuilder _ content: () -> some View) -> some View {
        ZStack {
            Circle().fill(dialGround)
            content()
        }
        .frame(width: Self.round, height: Self.round)
    }

    private func inScreen(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(width: Self.screen.width, height: Self.screen.height)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            // 画面の形が分かるよう、ごく薄い縁を内側に入れる（選んでいる印ではない）
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
    }

    /// 大きさ・書体の見本は**数字だけ**にする（絵も輪も描かない）
    private var numberOnly: FaceDesign {
        var d = design
        d.dialContent = .numberOnly
        d.dialRing = .none
        d.dialTint = .colored
        return d
    }

}
#endif
