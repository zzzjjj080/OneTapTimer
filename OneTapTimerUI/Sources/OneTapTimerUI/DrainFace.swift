import SwiftUI
import OneTapTimerCore

/// 大きさの調整。Watch と iPhone で数字の大きさだけ違う。
public struct FaceMetrics: Sendable {
    public var digits: CGFloat
    public var digitsShort: CGFloat
    public var label: CGFloat
    public var gap: CGFloat

    public init(digits: CGFloat, digitsShort: CGFloat, label: CGFloat, gap: CGFloat) {
        self.digits = digits; self.digitsShort = digitsShort; self.label = label; self.gap = gap
    }

    public static let watch = FaceMetrics(digits: 66, digitsShort: 96, label: 12, gap: 6)
    public static let phone = FaceMetrics(digits: 128, digitsShort: 200, label: 20, gap: 12)

    /// 下端の「長押しでキャンセル」
    var hint: CGFloat { label * 0.85 }
    var hintBottom: CGFloat { label * 1.6 }
}

/// 画面そのもの。**水位が下がり、真ん中に残りの数字。**
///
/// 時刻を受け取って描くだけの純粋な絵。動かすのは呼び出し側の `TimelineView`。
/// 常時表示（Always-On）のときは `liveDigits` に false を渡すと、
/// 数字の描画をシステム（`Text(timerInterval:)`）に任せる。
/// アプリのコードが動かなくても数字が進むのはこちらだけ。
public struct DrainFace: View {
    public var engine: TimerEngine
    public var now: Date
    public var theme: ThemeHex
    public var metrics: FaceMetrics
    public var liveDigits: Bool

    public init(engine: TimerEngine, now: Date, theme: ThemeHex, metrics: FaceMetrics,
                liveDigits: Bool = true) {
        self.engine = engine; self.now = now; self.theme = theme; self.metrics = metrics
        self.liveDigits = liveDigits
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
    private var secondsOnly: Bool { engine.isFinished || TimeText.showsSecondsOnly(remaining) }

    public var body: some View {
        ZStack {
            skin.ground

            Liquid(fraction: fraction, top: skin.liquidTop, bottom: skin.liquidBottom)

            // **走っている間は数字だけ。** 「のこり」も「秒」も要らない。
            // 何も添えないぶん、数字が画面のちょうど真ん中に来る
            VStack(spacing: metrics.gap) {
                digits
                    .font(.system(size: secondsOnly ? metrics.digitsShort : metrics.digits,
                                  weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(skin.ink)
                    .shadow(color: .black.opacity(skin.isDone ? 0 : 0.25), radius: 10, y: 2)
                    .contentTransition(.numericText(countsDown: true))
                    .accessibilityIdentifier("digits")

                if let label {
                    Text(label, bundle: .module)
                        .font(.system(size: metrics.label, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(skin.inkDim)
                        .accessibilityIdentifier("label")
                }
            }
            .padding(.horizontal, 12)

            // 下端の案内
            if let hint {
                VStack {
                    Spacer()
                    Text(hint, bundle: .module)
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

    @ViewBuilder
    private var digits: some View {
        if engine.isCancelled || liveDigits || engine.isFinished {
            Text(TimeText.display(remaining))
        } else {
            // システムが描く。書式は `m:ss` 固定（1分を切っても `0:45`）。
            // 常時表示の暗い画面でだけ使うので、そこは目をつぶる
            Text(timerInterval: now...engine.endAt, pauseTime: nil, countsDown: true, showsHours: false)
        }
    }

    /// 添える文字。**走っている間は出さない。** 終わったときだけ。
    private var label: LocalizedStringKey? {
        (engine.isFinished && !engine.isCancelled) ? "おわり" : nil
    }

    private var hint: LocalizedStringKey? {
        (engine.isFinished && !engine.isCancelled) ? "タップで始める" : nil
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
