import Foundation

/// タイマーの長さについての決まり。範囲・刻み・よく使う値。
///
/// 90秒を主に使うので、**そのあたりを10秒で合わせやすく**してある。
/// 長くなるほど刻みを粗くし、1時間まで無理なく回せるようにする。
public enum DurationRule {

    /// 秒。短すぎると合図の意味が無くなるので10秒から。
    public static let minimum = 10
    /// 秒。1時間まで。
    public static let maximum = 3600
    /// 初回の値。
    public static let standard = 90

    /// チップで1タップで選べる値。
    public static let presets = [30, 60, 90, 120, 180, 300, 600]

    /// 小さい画面（40mm など）で1行に収めるぶん。
    public static let presetsCompact = [30, 60, 90, 180]

    public static func clamp(_ seconds: Int) -> Int {
        min(maximum, max(minimum, seconds))
    }

    /// その値の**すぐ上**へ進むときの刻み。
    ///
    /// | 範囲 | 刻み |
    /// |---|---|
    /// | 〜5分 | 10秒 |
    /// | 5〜20分 | 30秒 |
    /// | 20分〜 | 1分 |
    public static func stepSize(at seconds: Int) -> Int {
        if seconds < 300 { return 10 }
        if seconds < 1200 { return 30 }
        return 60
    }

    /// 1つ上／下の値。**境目では下側の刻みで下がる。**
    /// 5:00 から下げたら 4:50 であって 4:30 ではない。
    public static func stepped(_ seconds: Int, up: Bool) -> Int {
        let v = clamp(seconds)
        if up {
            let s = stepSize(at: v)
            return clamp((v / s) * s + s)
        } else {
            let s = stepSize(at: v - 1)
            // 刻みに乗っていない値（保存が古いなど）は、まず下の刻みへ落とす
            let onGrid = ((v + s - 1) / s) * s
            return clamp(onGrid - s)
        }
    }

    /// Digital Crown の連続値を、刻みに乗せる。
    public static func snapped(_ raw: Double) -> Int {
        let v = Double(clamp(Int(raw.rounded())))
        let s = Double(stepSize(at: Int(v)))
        return clamp(Int((v / s).rounded() * s))
    }
}
