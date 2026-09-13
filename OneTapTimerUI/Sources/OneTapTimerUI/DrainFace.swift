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

    /// 下端の「タップで始める」
    var hint: CGFloat { label * 0.85 }
    var hintBottom: CGFloat { label * 1.6 }
}

/// 画面そのもの。**水位が下がり、真ん中に残りの秒を大きく、その下に `1:33` を小さく。**
///
/// 時刻を受け取って描くだけの純粋な絵。動かすのは呼び出し側の `TimelineView`。
/// 常時表示（腕を下ろした暗い画面）でも同じ絵を描く。watchOS はその絵を先の時刻ぶん先回りして描くので、
/// **ここでは日時から範囲を作らない**（`now...終了時刻` が逆向きになって落ちた。引き継ぎ書 4-135）。
public struct DrainFace: View {
    public var engine: TimerEngine
    public var now: Date
    public var theme: ThemeHex
    public var metrics: FaceMetrics

    public init(engine: TimerEngine, now: Date, theme: ThemeHex, metrics: FaceMetrics) {
        self.engine = engine; self.now = now; self.theme = theme; self.metrics = metrics
    }

    private var skin: Skin { Skin.of(engine, at: now, theme: theme) }
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

            Liquid(fraction: fraction, top: skin.liquidTop, bottom: skin.liquidBottom)

            VStack(spacing: metrics.gap) {
                Text(TimeText.seconds(remaining))
                    .font(.system(size: metrics.main, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .foregroundStyle(skin.ink)
                    // 影は小さく。ぼかしの大きい影は描き直すたびに重い（大きな数字だとなおさら）
                    .shadow(color: .black.opacity(skin.isDone ? 0 : 0.22), radius: 2, y: 1)
                    .contentTransition(.numericText(countsDown: true))
                    // **回ごとに別の数字として扱う。** 前の回の「0」から新しい回の数字へ桁が回る途中で、
                    // 「0:10」のような半端な形が一瞬見えていた
                    .id(engine.endAt)
                    .accessibilityIdentifier("digits")

                Group {
                    if isDone {
                        Text("おわり", bundle: .module).tracking(1)
                    } else {
                        Text(TimeText.clock(remaining)).monospacedDigit()
                    }
                }
                .font(.system(size: metrics.sub, weight: .semibold, design: .rounded))
                .foregroundStyle(skin.inkDim)
                .accessibilityIdentifier("sub")
            }
            // 下の小さい行と同じ高さを上にも取り、**大きい数字を画面のちょうど真ん中に置く**
            .padding(.top, metrics.sub * 1.2 + metrics.gap)
            .padding(.horizontal, 12)

            // 下端の案内
            if isDone {
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
}

/// 下から溜まった水。**測らない。** `Canvas` は自分の大きさを知っているので、
/// `GeometryReader` に聞かずに済む（watchOS では安全領域の扱いで高さが化ける）。
struct Liquid: View {
    var fraction: Double
    var top: Color
    var bottom: Color

    var body: some View {
        Canvas { ctx, size in
            let h = size.height * max(0, min(1, fraction))
            guard h > 0 else { return }
            let rect = CGRect(x: 0, y: size.height - h, width: size.width, height: h)
            ctx.fill(Path(rect),
                     with: .linearGradient(Gradient(colors: [top, bottom]),
                                           startPoint: CGPoint(x: 0, y: rect.minY),
                                           endPoint: CGPoint(x: 0, y: size.height)))
            // 水面の光。面積の境目がはっきりする
            ctx.fill(Path(CGRect(x: 0, y: rect.minY, width: size.width, height: 1.5)),
                     with: .color(.white.opacity(0.55)))
        }
    }
}
