// **iPhone だけの画面。** Watch には見た目を変える操作を置かない（画面が狭い）
#if os(iOS)
import SwiftUI
import OneTapTimerCore

/// 見た目を決める画面（iPhone だけ）。
///
/// **選択肢は文字で説明しない。小さな見本と番号（`Y2` など）で並べる。**
/// 16言語ぶんの説明文を持たずに済み、本人とのやり取りも番号でできる
/// （見本表 `design/catalog-*.png` と同じ番号）。
///
/// 選んだ瞬間に保存して Apple Watch へ送る。**「送る」ボタンは置かない**
/// （押し忘れたまま閉じられるより、常に最新が向こうにあるほうがよい）。
public struct DesignEditor: View {
    @Binding public var design: FaceDesign
    /// 見本に出す状態。終わりが近いとき（L）・終わった画面（E）は、その状態にしないと違いが見えない
    @State private var preview: PreviewState = .running
    public var onTip: (() -> Void)?

    public init(design: Binding<FaceDesign>, onTip: (() -> Void)? = nil) {
        self._design = design; self.onTip = onTip
    }

    enum PreviewState: CaseIterable, Hashable {
        case running, last, done

        var title: LocalizedStringResource {
            switch self {
            case .running: "走っている"
            case .last: "残り10秒"
            case .done: "終わった"
            }
        }

        /// 見本の中身。**終わった見本は `advance` を通す**（渡しただけでは走ったままになる）。
        /// 終わりが近い見本は30秒のタイマーにする（90秒だと水が残らず、20秒以下だと「終わりが近い」が無い）
        func engine(at now: Date) -> TimerEngine {
            switch self {
            case .running: return TimerEngine(duration: 90, startedAt: now.addingTimeInterval(-32))
            case .last: return TimerEngine(duration: 30, startedAt: now.addingTimeInterval(-23))
            case .done:
                var e = TimerEngine(duration: 90, startedAt: now.addingTimeInterval(-91))
                _ = e.advance(to: now)
                return e
            }
        }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                WatchPreview(design: design, state: preview)

                Picker("見本", selection: $preview) {
                    ForEach(PreviewState.allCases, id: \.self) { s in
                        Text(s.title).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                rows

                Button {
                    design = .standard
                } label: {
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
            .padding(.top, 12)
        }
        .background(Color(hex: PaletteHex.ground).ignoresSafeArea())
    }

    /// 並び順は「形 → 色 → 数字 → 仕上げ」。よく変えるものを上に置く
    @ViewBuilder
    private var rows: some View {
        row("減り方", \.style)
        row("色", \.color)
        row("塗り方", \.fill)
        row("向き", \.direction)
        row("地の色", \.ground)
        row("数字", \.digits)
        row("大きさ", \.size)
        row("書体", \.typeface)
        row("文字の太さ", \.weight)
        row("文字の色", \.ink)
        row("縁取り", \.outline)
        row("置き場所", \.place)
        row("終わりが近いとき", \.last)
        row("終わった画面", \.done)
        row("目盛り", \.ticks)
    }

    /// 1種類ぶんの横並び。**見本はその項目だけを差し替えたもの**（ほかはいまの設定のまま）
    private func row<T: NumberedChoice>(_ title: LocalizedStringKey,
                                        _ key: WritableKeyPath<FaceDesign, T>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title, bundle: .module)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.8))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 10) {
                    ForEach(T.allCases) { choice in
                        Chip(design: changing(key, to: choice), code: choice.code,
                             chosen: design[keyPath: key] == choice, state: preview) {
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

/// 選択肢ひとつ。**小さな見本と番号。**
private struct Chip: View {
    let design: FaceDesign
    let code: String
    let chosen: Bool
    let state: DesignEditor.PreviewState
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(spacing: 4) {
                TimelineView(.periodic(from: .now, by: 0.5)) { t in
                    DrainFace(engine: state.engine(at: t.date), now: t.date,
                              design: design, metrics: .sample)
                }
                .frame(width: 54, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(chosen ? Color(hex: design.theme.liquidTop) : .white.opacity(0.12),
                                      lineWidth: chosen ? 2.5 : 1)
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
}

/// いま選んでいる見た目を、Apple Watch の画面の形で大きく出す
private struct WatchPreview: View {
    let design: FaceDesign
    let state: DesignEditor.PreviewState

    var body: some View {
        VStack(spacing: 8) {
            TimelineView(.animation(minimumInterval: 1.0 / 20, paused: state == .done)) { t in
                DrainFace(engine: state.engine(at: t.date), now: t.date, design: design,
                          metrics: FaceMetrics(main: 96, sub: 20, label: 13, gap: 0))
            }
            .frame(width: 180, height: 220)
            // Apple Watch の画面に見立てる。**縁は塗りで作る**
            // （細い線だと、水の色が明るいときに縁が消えて画面の形が分からなくなる）
            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: 48, style: .continuous)
                    .fill(Color(white: 0.17))
                    .overlay {
                        RoundedRectangle(cornerRadius: 48, style: .continuous)
                            .strokeBorder(Color(white: 0.32), lineWidth: 1)
                    }
            }
            .accessibilityIdentifier("preview")

            Text(design.text)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.35))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("designCode")
        }
    }
}
#endif
