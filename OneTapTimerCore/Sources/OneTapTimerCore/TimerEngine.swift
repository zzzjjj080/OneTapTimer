import Foundation

/// 起きたこと。画面と触覚へ流す。
public enum TimerEvent: Equatable, Sendable {
    case finished
}

/// タイマーの中身。**時刻を渡すと残りが返る**だけの値型。
///
/// `Timer` で1秒ずつ引かない。経過は常に「終わる時刻 − 今」で出す。
/// 画面が消えても、アプリが止められても、次に時刻を渡した瞬間に正しい値へ追いつく。
///
/// **一時停止できる**（2026-09-13 に足した。あまり使わないので、画面の左上に小さく置く）。
/// 止めている間は残り秒をそのまま持ち、続けるときに「今 ＋ 残り」を新しい終わる時刻にする。
public struct TimerEngine: Equatable, Sendable, Codable {

    /// 残りがこの秒数を切ったら「終わりが近い」色にする。
    public static let finalStretch: Double = 10
    /// これより短いタイマーでは「終わりが近い」を出さない。始まった瞬間から色が変わって意味が無い。
    public static let finalStretchNeeds = 20

    /// 秒。
    public let duration: Int
    public private(set) var endAt: Date
    public private(set) var finishedAt: Date?
    /// 長押しで止めた（時間が来て終わったのではない）
    public private(set) var isCancelled: Bool = false
    /// 一時停止中の残り秒。止めていなければ nil
    public private(set) var pausedRemaining: Double?

    public var isPaused: Bool { pausedRemaining != nil }

    public init(duration: Int, startedAt: Date) {
        self.duration = DurationRule.clamp(duration)
        self.endAt = startedAt.addingTimeInterval(TimeInterval(self.duration))
        self.finishedAt = nil
    }

    public var isFinished: Bool { finishedAt != nil }

    /// 途中で止める。「止めた時刻に終わった」ことにする。開き直したときの扱いは終了と同じ
    public mutating func cancel(at now: Date) {
        guard !isFinished else { return }
        finishedAt = now
        isCancelled = true
    }
    public var startAt: Date { endAt.addingTimeInterval(-TimeInterval(duration)) }

    /// 一時停止。**残り秒を持って止まる。** 終わっていたら、終わる時刻を過ぎていたら何もしない
    public mutating func pause(at now: Date) {
        guard !isFinished, !isPaused, endAt > now else { return }
        pausedRemaining = endAt.timeIntervalSince(now)
    }

    /// 続ける。**今から残り秒ぶん先を、新しい終わる時刻にする**
    public mutating func resume(at now: Date) {
        guard !isFinished, let r = pausedRemaining else { return }
        endAt = now.addingTimeInterval(r)
        pausedRemaining = nil
    }

    /// 残り秒。0未満にはならない。止めている間は止めたときの値のまま。
    public func remaining(at now: Date) -> Double {
        if let r = pausedRemaining { return r }
        return max(0, endAt.timeIntervalSince(now))
    }

    /// 残りの割合。1 → 0。水位に使う。
    public func fraction(at now: Date) -> Double {
        remaining(at: now) / Double(duration)
    }

    /// 終わりが近いか。
    public func isFinalStretch(at now: Date) -> Bool {
        guard !isFinished, duration > Self.finalStretchNeeds else { return false }
        let r = remaining(at: now)
        return r > 0 && r <= Self.finalStretch
    }

    /// 時計を進める。終わった瞬間に一度だけ `.finished` を返す。
    ///
    /// 終わった時刻は**本当に終わった時刻**（`endAt`）で記録する。
    /// 裏で止まっていて10分後に追いついた場合も、「10分前に終わった」が残る。
    /// 起動時に「終わってから間もないか」を見て、自動で次を始めるかを決めるため。
    public mutating func advance(to now: Date) -> [TimerEvent] {
        guard !isFinished, !isPaused, now >= endAt else { return [] }
        finishedAt = endAt
        return [.finished]
    }

    /// 同じ長さで最初から。
    public mutating func restart(at now: Date) {
        self = TimerEngine(duration: duration, startedAt: now)
    }

    // 保存済みの JSON に `isCancelled` や `pausedRemaining` が無くても読めるように
    private enum CodingKeys: String, CodingKey { case duration, endAt, finishedAt, isCancelled, pausedRemaining }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        duration = try c.decode(Int.self, forKey: .duration)
        endAt = try c.decode(Date.self, forKey: .endAt)
        finishedAt = try c.decodeIfPresent(Date.self, forKey: .finishedAt)
        isCancelled = try c.decodeIfPresent(Bool.self, forKey: .isCancelled) ?? false
        pausedRemaining = try c.decodeIfPresent(Double.self, forKey: .pausedRemaining)
    }

    /// 終わってからの経過。終わっていなければ nil。
    public func sinceFinished(at now: Date) -> TimeInterval? {
        finishedAt.map { now.timeIntervalSince($0) }
    }
}
