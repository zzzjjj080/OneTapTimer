import SwiftUI
import OneTapTimerCore

/// 大きさの調整。Watch と iPhone で数字の大きさだけ違う。
public struct FaceMetrics: Sendable {
    /// 大きい数字（秒だけ）
    public var main: CGFloat
    /// 下に添える小さい `1:33`／終わったときの「おわり」
    public var sub: CGFloat
    public var label: CGFloat
    public var gap: CGFloat

    public init(main: CGFloat, sub: CGFloat, label: CGFloat, gap: CGFloat) {
        self.main = main; self.sub = sub; self.label = label; self.gap = gap
    }

    public static let watch = FaceMetrics(main: 96, sub: 20, label: 13, gap: 0)
    public static let phone = FaceMetrics(main: 200, sub: 40, label: 22, gap: 4)
    /// 見本表の小さな絵
    public static let sample = FaceMetrics(main: 44, sub: 11, label: 8, gap: 0)

    /// 下端の「タップで始める」
    var hint: CGFloat { label * 0.85 }
    var hintBottom: CGFloat { label * 1.6 }
}

/// 画面そのもの。**減っていく形（水・輪・棒・色）と、真ん中の数字。**
///
/// 時刻を受け取って描くだけの純粋な絵。動かすのは呼び出し側の `TimelineView`。
/// 常時表示（腕を下ろした暗い画面）でも同じ絵を描く。watchOS はその絵を先の時刻ぶん先回りして描くので、
/// **ここでは日時から範囲を作らない**（`now...終了時刻` が逆向きになって落ちた。引き継ぎ書 4-135）。
///
/// 見た目は `FaceDesign`（番号付きの選択肢）で決まる。**iPhone で決めて Watch へ送る。**
public struct DrainFace: View {
    public var engine: TimerEngine
    public var now: Date
    public var design: FaceDesign
    public var metrics: FaceMetrics
    /// 減り方（水・輪・棒）を描くか。**選択肢の見本で「数字だけ」を見せるときに false**
    public var showsMeter: Bool
    /// 数字を描くか。**「形だけ」を見せるときに false**
    public var showsDigits: Bool

    public init(engine: TimerEngine, now: Date, design: FaceDesign, metrics: FaceMetrics,
                showsMeter: Bool = true, showsDigits: Bool = true) {
        self.engine = engine; self.now = now; self.design = design; self.metrics = metrics
        self.showsMeter = showsMeter; self.showsDigits = showsDigits
    }

    private var skin: Skin { Skin.of(engine, at: now, design: design) }
    /// 終わったら 0 で固定する。`now` が終了時刻のわずかに手前（描画の1コマ前）でも「1」と出さない。
    /// 止めたときは、次に始まる長さを出す
    private var remaining: Double {
        if engine.isCancelled { return Double(engine.duration) }
        return engine.isFinished ? 0 : engine.remaining(at: now)
    }
    private var fraction: Double {
        if engine.isCancelled { return 1 }
        return engine.isFinished ? 0 : engine.fraction(at: now)
    }
    private var isDone: Bool { engine.isFinished && !engine.isCancelled }

    public var body: some View {
        ZStack {
            skin.ground

            if !isDone && showsMeter {
                Meter(fraction: fraction, skin: skin, design: design)
            }

            if showsDigits { digits }

            // 下端の案内
            if isDone && showsDigits {
                VStack {
                    Spacer()
                    Text("タップで始める", bundle: .module)
                        .font(.system(size: metrics.hint, weight: .medium))
                        .tracking(0.5)
                        .foregroundStyle(skin.inkDim.opacity(0.85))
                        .padding(.bottom, metrics.hintBottom)
                        .accessibilityIdentifier("hint")
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: skin)
    }

    // MARK: - 数字

    /// `1:25` は `85` より3桁ぶん長い。**同じ大きさで出すと切れる**ので、その形だけ縮める
    private var mainSize: CGFloat {
        metrics.main * design.size.ratio * (design.digits == .clockOnly ? 0.56 : 1)
    }
    private var subSize: CGFloat { metrics.sub * design.size.ratio }

    private var fontDesign: Font.Design {
        switch design.typeface {
        case .rounded: .rounded
        case .standard: .default
        case .serif: .serif
        case .monospaced: .monospaced
        }
    }

    private var fontWeight: Font.Weight {
        switch design.weight {
        case .light: .light
        case .medium: .semibold
        case .heavy: .heavy
        }
    }

    /// 大きく出す文字。`N3` は `1:25` を大きく出す
    private var mainText: String? {
        switch design.digits {
        case .secondsWithClock, .secondsOnly: TimeText.seconds(remaining)
        case .clockOnly: TimeText.clock(remaining)
        case .none: nil
        }
    }

    @ViewBuilder
    private var digits: some View {
        VStack(spacing: metrics.gap) {
            if let mainText {
                Text(mainText)
                    .font(.system(size: mainSize, weight: fontWeight, design: fontDesign))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(skin.ink)
                    .modifier(Edge(outline: design.outline, isDone: skin.isDone, ground: skin.ground))
                    .contentTransition(.numericText(countsDown: true))
                    // **回ごとに別の数字として扱う。** 前の回の「0」から新しい回の数字へ桁が回る途中で、
                    // 「0:10」のような半端な形が一瞬見えていた
                    .id(engine.endAt)
                    .accessibilityIdentifier("digits")
            }

            Group {
                if isDone {
                    Text("おわり", bundle: .module).tracking(1)
                } else if engine.isPaused {
                    // **止まっていることを、はっきり言葉で出す。** 水は灰色、左上のボタンは色つきの ▶
                    Label { Text("一時停止中", bundle: .module) } icon: { Image(systemName: "pause.fill") }
                } else if design.digits == .secondsWithClock {
                    Text(TimeText.clock(remaining)).monospacedDigit()
                }
            }
            .font(.system(size: subSize, weight: engine.isPaused ? .heavy : .semibold, design: fontDesign))
            .foregroundStyle(engine.isPaused ? skin.ink : skin.inkDim)
            .accessibilityIdentifier("sub")
        }
        // 下の小さい行と同じ高さを上にも取り、**大きい数字を画面のちょうど真ん中に置く**
        .padding(.top, subSize * 1.2 + metrics.gap)
        .padding(.horizontal, 12)
        .modifier(Place(place: design.place, inset: mainSize * 0.45))
    }
}

/// P 置き場所。上寄り・下寄りは、はみ出さないところまで
private struct Place: ViewModifier {
    let place: FacePlace
    let inset: CGFloat

    func body(content: Content) -> some View {
        switch place {
        case .center: content
        case .top: VStack { content.padding(.top, inset); Spacer(minLength: 0) }
        case .bottom: VStack { Spacer(minLength: 0); content.padding(.bottom, inset) }
        }
    }
}

/// O 縁取り。**黒ぶちは太い文字でしか効かない**ので、影と使い分ける
private struct Edge: ViewModifier {
    let outline: FaceOutline
    let isDone: Bool
    let ground: Color

    func body(content: Content) -> some View {
        switch outline {
        case .none:
            content
        case .shadow:
            // 影は小さく。ぼかしの大きい影は描き直すたびに重い（大きな数字だとなおさら）
            content.shadow(color: .black.opacity(isDone ? 0 : 0.22), radius: 2, y: 1)
        case .stroke:
            content
                .background(alignment: .center) {
                    // **`foregroundStyle` では黒くならない**（中の文字が自分の色を持っている）。
                    // 掛け算で黒へ落としてから、少し太らせて後ろに敷く
                    content.colorMultiply(.black).blur(radius: 1.1).scaleEffect(1.07)
                }
        }
    }
}

/// Y 減り方。**水・輪・棒・色が薄れる**の4つ。減るのは下へ、塗りは上下グラデで固定（1.3）。
///
/// `Canvas` は自分の大きさを知っているので `GeometryReader` に聞かずに済む
/// （watchOS では安全領域の扱いで高さが化ける）。
struct Meter: View {
    var fraction: Double
    var skin: Skin
    var design: FaceDesign

    private var f: Double { max(0, min(1, fraction)) }
    private var colors: [Color] { [skin.liquidTop, skin.liquidBottom] }

    var body: some View {
        switch design.style {
        case .liquid: liquid
        case .ring: ring
        case .bar: bar
        case .fade: fade
        }
    }

    /// 残っているぶんの四角（下から上へ減る）
    private func filled(in size: CGSize) -> CGRect {
        CGRect(x: 0, y: size.height * (1 - f), width: size.width, height: size.height * f)
    }

    private func shading(_ rect: CGRect) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: colors),
                        startPoint: CGPoint(x: rect.minX, y: rect.minY),
                        endPoint: CGPoint(x: rect.minX, y: rect.maxY))
    }

    // MARK: 水（Y1）

    private var liquid: some View {
        Canvas { ctx, size in
            guard f > 0 else { return }
            let rect = filled(in: size)
            ctx.fill(Path(rect), with: shading(rect))
            // 水面の光。面積の境目がはっきりする
            ctx.fill(Path(CGRect(x: 0, y: rect.minY, width: size.width, height: 1.5)),
                     with: .color(.white.opacity(0.55)))
        }
    }

    // MARK: 輪（Y2）

    private var ring: some View {
        Canvas { ctx, size in
            let side = min(size.width, size.height)
            let width = side * 0.11
            let box = CGRect(x: (size.width - side) / 2 + width / 2 + side * 0.06,
                             y: (size.height - side) / 2 + width / 2 + side * 0.06,
                             width: side * 0.88 - width, height: side * 0.88 - width)
            ctx.stroke(Path(ellipseIn: box), with: .color(skin.liquidTop.opacity(0.16)), lineWidth: width)
            guard f > 0 else { return }
            // 12時から右回りに減る
            var arc = Path()
            arc.addArc(center: CGPoint(x: box.midX, y: box.midY), radius: box.width / 2,
                       startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * f), clockwise: false)
            ctx.stroke(arc, with: .linearGradient(Gradient(colors: colors),
                                                  startPoint: CGPoint(x: box.midX, y: box.minY),
                                                  endPoint: CGPoint(x: box.midX, y: box.maxY)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
        }
    }

    // MARK: 棒（Y3）

    private var bar: some View {
        Canvas { ctx, size in
            let thickness = size.width * 0.22
            let long = size.height * 0.78
            let track = CGRect(x: (size.width - thickness) / 2, y: (size.height - long) / 2,
                               width: thickness, height: long)
            let radius = thickness / 2
            ctx.fill(Path(roundedRect: track, cornerRadius: radius),
                     with: .color(skin.liquidTop.opacity(0.16)))
            guard f > 0 else { return }
            let rect = filled(in: track.size).offsetBy(dx: track.minX, dy: track.minY)
            ctx.fill(Path(roundedRect: rect, cornerRadius: radius), with: shading(rect))
        }
    }

    // MARK: 色が薄れる（Y4）

    private var fade: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            ctx.opacity = 0.18 + 0.82 * f
            ctx.fill(Path(rect), with: shading(rect))
        }
    }
}
