import Foundation

/// 長さの決まり。**10秒〜60分。刻みは 10秒と 1分の2つだけ。**
///
/// 最初は長さによって刻みを変え、よく使う値のチップも置いていたが、
/// 実機で触って「＋−だけでよい。10秒と1分の2種類」に落ち着いた。
public enum DurationRule {
    public static let minimum = 10
    public static let maximum = 3600
    /// 初期値。90秒ばかり使うのでこれ
    public static let standard = 90

    /// 細かいほう。基本はこれで合わせる
    public static let fineStep = 10
    /// 粗いほう
    public static let coarseStep = 60

    public static func clamp(_ seconds: Int) -> Int {
        min(maximum, max(minimum, seconds))
    }

    /// `by` 秒ぶん動かす（1:30 に +1分 なら 2:30。分の切れ目には寄せない）。
    /// 10秒に乗っていない値（古い保存など）が来ても、返す値は10秒に乗せる。
    public static func stepped(_ seconds: Int, by: Int) -> Int {
        let moved = Double(seconds + by) / Double(fineStep)
        let snapped = by >= 0 ? moved.rounded(.up) : moved.rounded(.down)
        return clamp(Int(snapped) * fineStep)
    }

    /// Digital Crown の1目盛りは10秒。目盛りの数 ⇄ 秒。
    public static func seconds(fromCrown detents: Double) -> Int {
        clamp(Int(detents.rounded()) * fineStep)
    }

    public static func crown(fromSeconds seconds: Int) -> Double {
        Double(clamp(seconds)) / Double(fineStep)
    }

    /// 目盛りの範囲（1 = 10秒 … 360 = 60分）
    public static var crownRange: ClosedRange<Double> {
        Double(minimum / fineStep)...Double(maximum / fineStep)
    }
}
