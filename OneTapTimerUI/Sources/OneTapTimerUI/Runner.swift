import Foundation
import Observation
import WidgetKit
import OneTapTimerCore

/// 触覚。Watch と iPhone で鳴らし方が違うので、外から差し込む。
@MainActor
public protocol TimerHaptics: AnyObject {
    /// 走り出した
    func started()
    /// 終わった。**一度だけ。鳴り続けない**
    func finished()
    /// ＋ − を1つ動かした
    func stepped(up: Bool)
    /// 長押しで止めた
    func cancelled()
}

/// 画面と ``TimerEngine`` をつなぐところ。Watch と iPhone で同じ。
///
/// **開いたら始まる。** 走っている最中に開いたなら続き。終わってから間もないなら
/// 「おわり」を見せる。それ以外は新しく始める。
///
/// 秒の数字は画面側の `TimelineView` が時刻から描く。ここが持つのは
/// 「どの画面か」「エンジンの中身」だけで、1秒に何度も動く値は持たない。
@MainActor
@Observable
public final class Runner {

    public enum Screen: Equatable { case run, settings }

    public private(set) var screen: Screen = .run
    public private(set) var engine: TimerEngine
    /// 設定してある長さ（秒）。次に始めるときの値
    public private(set) var duration: Int
    /// 色の組の番号（1〜10）
    public private(set) var theme: Int
    public var themeHex: ThemeHex { ThemeHex.at(theme) }

    /// 終わってからこの秒数のあいだに開き直したときは、始めずに「おわり」を見せる。
    /// 腕を上げて終わりを確かめただけで、次の90秒が走り出さないように。
    public static let doneGrace: TimeInterval = 30

    /// アプリの外から開いたか。**「開いたら始まる」はここでしか起きない。**
    /// 腕を下ろして上げただけ（`.inactive` → `.active`）で始まってしまうのを防ぐ。
    private var cameFromOutside = true

    public let notifier: EndScheduling
    public let gate = NotificationGate()

    private let haptics: TimerHaptics
    private let defaults: UserDefaults
    private var ticker: Task<Void, Never>?
    private var isActive = false

    private static let durationKey = SharedStore.durationKey
    private static let engineKey = SharedStore.engineKey

    public init(haptics: TimerHaptics, notifier: EndScheduling? = nil,
                defaults: UserDefaults = SharedStore.defaults, now: Date = .now) {
        self.haptics = haptics
        self.notifier = notifier ?? EndNotifier()
        self.defaults = defaults

        let saved = defaults.integer(forKey: Self.durationKey)
        let d = saved == 0 ? DurationRule.standard : DurationRule.clamp(saved)
        duration = d
        let t = defaults.integer(forKey: SharedStore.themeKey)
        theme = (1...ThemeHex.all.count).contains(t) ? t : 1

        // 前回の続き。プロセスが落とされていても、終わる時刻はここから戻る
        if let data = defaults.data(forKey: Self.engineKey),
           let e = try? JSONDecoder().decode(TimerEngine.self, from: data) {
            engine = e
        } else {
            // 初めて。「ずっと前に終わっている」ことにしておくと、前に出た瞬間に ``activate`` が始める。
            // ここで走らせてしまうと、触覚も通知の予約も通らないまま動き出す（テストで見つけた）
            var e = TimerEngine(duration: d, startedAt: .distantPast)
            _ = e.advance(to: now)
            engine = e
        }
    }

    // MARK: - 画面の出入り

    /// 前に出た。**アプリの外から開いたときだけ、ここで始める。**
    public func activate(now: Date = .now) {
        isActive = true
        gate.isForeground = true

        // 腕を下ろしている間に終わっていたぶんに追いつく。ここでは鳴らさない（通知が済ませている）
        _ = engine.advance(to: now)

        let opened = cameFromOutside
        cameFromOutside = false

        if opened {
            if engine.isCancelled {
                // やめたものを見せ直しても仕方がない。開いた ＝ 始めたい
                start(now: now)
            } else if engine.isFinished, (engine.sinceFinished(at: now) ?? .infinity) > Self.doneGrace {
                start(now: now)
            } else if !engine.isFinished {
                startTicking()
            }
        } else if !engine.isFinished {
            startTicking()
        }
        persist()
    }

    /// 腕を下ろした（画面が暗くなった）。**タイマーはそのまま。**
    ///
    /// この間はこちらのコードが動かないので、終わりの合図は通知に任せる
    /// （`gate` を下ろすと、前に出ていないものとして通知が鳴る）。
    public func goIdle() {
        isActive = false
        gate.isForeground = false
        stopTicking()
    }

    /// アプリから出た（クラウンを押した／ほかのアプリへ移った）。**走っているものは止める。**
    ///
    /// 裏で動かすことは考えていない。出たあとに通知だけ鳴るのが一番困るので、
    /// タイマーも予約した通知も、ここで一緒に片付ける。
    public func leave(now: Date = .now) {
        isActive = false
        gate.isForeground = false
        cameFromOutside = true
        stopTicking()
        screen = .run
        if !engine.isFinished {
            engine.cancel(at: now)
        }
        notifier.cancel()
        persist()
    }

    // MARK: - 操作

    /// 終わった画面（おわり／キャンセル）をタップした。**新しく始める。**
    /// 走っている最中のタップは何もしない（誤タップで最初に戻らないように）。
    public func startAgain(now: Date = .now) {
        guard engine.isFinished else { return }
        start(now: now)
    }

    /// 色の組を次へ（10 の次は 1）。保存して、文字盤にも反映させる
    public func cycleTheme() {
        theme = ThemeHex.next(after: theme)
        defaults.set(theme, forKey: SharedStore.themeKey)
        haptics.stepped(up: true)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 画面を長押しした。**止める。** 開き直したら、待たずに新しく始まる
    public func cancel(now: Date = .now) {
        guard !engine.isFinished else { return }
        engine.cancel(at: now)
        stopTicking()
        notifier.cancel()
        haptics.cancelled()
        persist()
    }

    public func openSettings() {
        screen = .settings
    }

    public func closeSettings() {
        screen = .run
    }

    /// 設定を決めた。保存して、その長さで最初から
    public func apply(duration new: Int, now: Date = .now) {
        duration = DurationRule.clamp(new)
        defaults.set(duration, forKey: Self.durationKey)
        screen = .run
        start(now: now)
    }

    // MARK: - 触覚の橋渡し

    public func stepped(up: Bool) { haptics.stepped(up: up) }

    // MARK: - 内部

    private func start(now: Date) {
        engine = TimerEngine(duration: duration, startedAt: now)
        haptics.started()
        notifier.schedule(endAt: engine.endAt, duration: duration)
        persist()
        if isActive { startTicking() }
    }

    private func startTicking() {
        stopTicking()
        guard !engine.isFinished else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let left = self.engine.remaining(at: .now)
                // 終わる直前まで寝て、終わりの瞬間だけ細かく見る
                try? await Task.sleep(for: .seconds(min(0.2, max(0.02, left))))
                guard !Task.isCancelled else { return }
                if self.tick() { return }
            }
        }
    }

    private func stopTicking() {
        ticker?.cancel()
        ticker = nil
    }

    /// 終わったら true。
    private func tick() -> Bool {
        let events = engine.advance(to: .now)
        guard events.contains(.finished) else { return false }
        haptics.finished()
        persist()
        return true
    }

    /// 保存して、文字盤のコンプリケーションに描き直させる（設定した秒数と、走っているかを出している）
    private func persist() {
        if let data = try? JSONEncoder().encode(engine) {
            defaults.set(data, forKey: Self.engineKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 動作確認用

    #if DEBUG
    /// シミュレータで状態を直接出すための入口。**リリース構成には入らない。**
    ///
    ///     OTT_STATE=running:45   残り45秒で走っている
    ///     OTT_STATE=last:7       終わりが近い
    ///     OTT_STATE=done         終わった直後
    ///     OTT_STATE=cancelled    長押しで止めた直後
    ///     OTT_STATE=settings     設定を開いた
    public func applyDebugState(_ spec: String, now: Date = .now) {
        let parts = spec.split(separator: ":")
        let n = parts.count > 1 ? Double(parts[1]) ?? 0 : 0
        switch parts.first.map(String.init) {
        case "running", "last":
            engine = TimerEngine(duration: duration, startedAt: now.addingTimeInterval(-(Double(duration) - n)))
            notifier.cancel()
            startTicking()
        case "done":
            engine = TimerEngine(duration: duration, startedAt: now.addingTimeInterval(-Double(duration)))
            _ = engine.advance(to: now)
            notifier.cancel()
            stopTicking()
        case "cancelled":
            engine = TimerEngine(duration: duration, startedAt: now.addingTimeInterval(-20))
            engine.cancel(at: now)
            notifier.cancel()
            stopTicking()
        case "settings":
            screen = .settings
        default:
            break
        }
        persist()
    }
    #endif
}
