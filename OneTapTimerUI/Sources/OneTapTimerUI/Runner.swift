import Foundation
import Observation
import WidgetKit
import OneTapTimerCore

/// 触覚。Watch と iPhone で鳴らし方が違うので、外から差し込む。
@MainActor
public protocol TimerHaptics: AnyObject {
    /// 走り出した
    func started()
    /// 終わった。**一度だけ。鳴り続けない。** 鳴り終わるまで返らない
    func finished() async
    /// ＋ − を1つ動かした
    func stepped(up: Bool)
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

    /// 腕を下ろして画面が暗くなった時刻。`.background` が来たときに、
    /// **クラウンで自分で出たのか、画面が消えただけなのか**を見分けるのに使う。
    private var inactiveSince: Date?

    /// `.inactive` になってからこれより速く `.background` まで来たら「自分で出た」とみなす。
    /// クラウンを押したときの切り替わりは 0.5 秒もかからない。
    /// 腕を下ろしたときは、暗い画面がしばらく続いてから消える。
    public static let deliberateLeaveWindow: TimeInterval = 1.5

    /// アプリの外から開いたか。**「開いたら始まる」はここでしか起きない。**
    /// 腕を下ろして上げただけ（`.inactive` → `.active`）で始まってしまうのを防ぐ。
    private var cameFromOutside = true

    public let notifier: EndScheduling
    public let gate = NotificationGate()
    /// 走っている間アプリを前面に留めるもの（Watch だけ。iPhone は nil）
    public var keeper: ForegroundKeeping? {
        didSet { wireKeeper() }
    }

    /// 終わって振動が鳴り終わってから ``closeDelay`` 秒おいて呼ぶ、**アプリを閉じる処理**。
    /// Watch だけが渡す（2026-09-15、本人の希望「鳴り終わって1秒くらいで閉じる」）。
    /// iPhone は渡さない。iPhone のアプリが自分で消えるのはクラッシュに見える
    public var closeAfterFinish: (() -> Void)?
    /// 鳴り終わってから閉じるまでの秒数
    var closeDelay: TimeInterval = 1.0

    private let haptics: TimerHaptics
    private let defaults: UserDefaults
    private var ticker: Task<Void, Never>?
    private var isActive = false

    private static let durationKey = SharedStore.durationKey
    private static let engineKey = SharedStore.engineKey

    public init(haptics: TimerHaptics, keeper: ForegroundKeeping? = nil,
                notifier: EndScheduling? = nil,
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

        // `didSet` は init の中では走らないので、ここで結び直す
        self.keeper = keeper
        wireKeeper()
    }

    private func wireKeeper() {
        keeper?.onChange = { [weak self] in self?.keeperChanged() }
        // クラウンで出るとセッションは「前面から外れた」で終わる。**これが一番確かな「出ていった」の合図。**
        // `.background` の時間差での見分け（enteredBackground）と二重に効かせておく
        keeper?.onUserLeft = { [weak self] in self?.leave() }
    }

    // MARK: - 画面の出入り

    /// 前に出た。**アプリの外から開いたときだけ、ここで始める。**
    public func activate(now: Date = .now) {
        isActive = true
        inactiveSince = nil
        gate.isForeground = true

        // 腕を下ろしている間に終わっていたぶんに追いつく。ここでは鳴らさない（通知が済ませている）
        _ = engine.advance(to: now)

        let opened = cameFromOutside
        cameFromOutside = false

        updateGate()

        if opened {
            // **外から開いたら必ず走り出す。** 終わったものもやめたものも、見せ直す意味がない。
            // 腕を上げただけ（`.inactive` → `.active`）はここへ来ないので、勝手には始まらない
            if engine.isFinished {
                start(now: now)
            } else {
                startTicking()
            }
        } else if !engine.isFinished {
            startTicking()
        }

        // 走っているのに前面を留められていなければ、見ているうちに張り直す。
        // セッションは前面にいる間しか始められない。途中で切れていたら、ここが取り返す機会
        if !engine.isFinished, keeper?.isKeeping == false {
            keeper?.begin()
        }
        persist()
    }

    /// 腕を下ろした（画面が暗くなった）。**タイマーはそのまま。**
    ///
    /// 前面に留まれているなら、こちらのコードはまだ動くので時計も止めない。
    /// 留まれていないときだけ、終わりの合図を通知に任せる（`gate` を下ろす）。
    public func goIdle(now: Date = .now) {
        isActive = false
        if inactiveSince == nil { inactiveSince = now }
        updateGate()
        if keeper?.isKeeping != true { stopTicking() }
    }

    /// `.background` になった。**クラウンで出たのか、腕を下ろして画面が消えただけかを見分ける。**
    ///
    /// どちらも `.background` として届く。前は全部を「出た」とみなしていたので、
    /// 腕を下ろして画面が消えた瞬間（30秒ほど）にタイマーを止め、前面の留めも外していた。
    /// 留めが外れると watchOS はそのまま文字盤へ戻すので、「勝手に閉じられた」ように見えた。
    ///
    /// - 暗い画面が `deliberateLeaveWindow` 以上続いてから来た → 画面が消えただけ。**続ける**
    /// - 見ている状態から一気に来た → クラウン（またはほかのアプリ）。**止める**
    public func enteredBackground(now: Date = .now) {
        let dimmedFor = inactiveSince.map { now.timeIntervalSince($0) } ?? 0
        if dimmedFor >= Self.deliberateLeaveWindow {
            goIdle(now: now)
        } else {
            leave(now: now)
        }
    }

    /// アプリから出た（クラウンを押した／ほかのアプリへ移った）。**走っているものは止める。**
    ///
    /// 裏で動かすことは考えていない。出たあとに通知だけ鳴るのが一番困るので、
    /// タイマーも予約した通知も、ここで一緒に片付ける。
    ///
    /// **止める操作はこれ1つ。** 画面の長押しでも止められるようにしていたが、
    /// 長押しではアプリを閉じられない（watchOS に終了の API が無い）。
    /// クラウンなら「止めて文字盤へ」が一動作で済むので、そちらへ寄せた。
    public func leave(now: Date = .now) {
        isActive = false
        inactiveSince = nil
        cameFromOutside = true
        stopTicking()
        keeper?.end()
        updateGate()
        screen = .run
        if !engine.isFinished {
            engine.cancel(at: now)
        }
        notifier.cancel()
        updateGate()
        persist()
    }

    // MARK: - 操作

    /// 終わった画面（おわり／キャンセル）をタップした。**新しく始める。**
    /// 走っている最中のタップは何もしない（誤タップで最初に戻らないように）。
    public func startAgain(now: Date = .now) {
        guard engine.isFinished else { return }
        start(now: now)
    }

    /// 左上のボタン。**止める／続ける。** 終わっているときは何もしない。
    ///
    /// 止めている間に終わりの通知が鳴らないよう、予約は消す。続けるときに新しい終わる時刻で付け直す。
    /// 前面の留めは外さない（止めた画面を見ていられるように。上限は self-care の10分）。
    public func togglePause(now: Date = .now) {
        guard !engine.isFinished else { return }
        if engine.isPaused {
            engine.resume(at: now)
            notifier.schedule(endAt: engine.endAt, duration: engine.duration)
            haptics.stepped(up: true)
            if keeper?.isKeeping == false { keeper?.begin() }
            startTicking()
        } else {
            engine.pause(at: now)
            guard engine.isPaused else { return }
            notifier.cancel()
            stopTicking()
            haptics.stepped(up: false)
        }
        persist()
    }

    /// 色の組を次へ（10 の次は 1）。保存して、文字盤にも反映させる
    public func cycleTheme() {
        theme = ThemeHex.next(after: theme)
        defaults.set(theme, forKey: SharedStore.themeKey)
        haptics.stepped(up: true)
        reloadComplication()
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
        reloadComplication()
        screen = .run
        start(now: now)
    }

    // MARK: - 触覚の橋渡し

    public func stepped(up: Bool) { haptics.stepped(up: up) }

    // MARK: - 内部

    private func start(now: Date) {
        engine = TimerEngine(duration: duration, startedAt: now)
        haptics.started()
        // 前面に留まれなかったときの保険として、必ず予約しておく。
        // 留まれている間は ``gate`` が表示を抑えるので、二重には鳴らない
        notifier.schedule(endAt: engine.endAt, duration: duration)
        keeper?.begin()
        persist()
        startTicking()
    }

    /// 前面に留まれるかどうかが変わった。
    private func keeperChanged() {
        updateGate()
        if keeper?.isKeeping == true {
            startTicking()
        } else if !isActive {
            // 留まれなくなった。ここから先は通知が頼り
            stopTicking()
        }
    }

    /// 通知を出すかどうか。**自分で鳴らせるときだけ抑える。**
    private func updateGate() {
        gate.isForeground = isActive || keeper?.isKeeping == true
    }

    /// 終わりを捕まえるだけの時計。**画面の数字はここでは動かさない**（`TimelineView` が時刻から描く）。
    ///
    /// 終わるまで寝て、起きたら見る。0.2秒ごとに起こすと、1時間のタイマーで
    /// 18000回起きることになり、前面に留まっている間ずっと電池を使う。
    private func startTicking() {
        stopTicking()
        // 止めている間は終わりを待たない（続けたときに ``togglePause(now:)`` が動かし直す）
        guard !engine.isFinished, !engine.isPaused else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let left = self.engine.remaining(at: .now)
                // 長く寝すぎると、ずれたときに取り返せない。最大60秒で起きて測り直す
                try? await Task.sleep(for: .seconds(min(60, max(0.02, left))))
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
        // **終わったら、クラウンを押したのと同じところまで片付ける。**
        // 予約しておいた通知は、もう要らないのですぐ消す。
        notifier.cancel()
        persist()

        let finishedRun = engine.endAt
        Task { [weak self] in await self?.settleAfterFinish(run: finishedRun) }
        return true
    }

    /// 終わったあとの後始末。**鳴り終わるまで待ち、Watch なら1秒おいてアプリを閉じる。**
    ///
    /// **閉じるまで前面の留めを外さない。** 先に外すと、腕を下ろしている間はアプリが止められて
    /// 1秒後の「閉じる」が走らず、watchOS がいつもどおり文字盤へ戻すまで待たされる（「なかなか閉じない」）。
    /// 閉じる処理が無い（iPhone）なら、鳴り終わった時点で留めだけ外す。
    func settleAfterFinish(run: Date) async {
        await haptics.finished()
        // 鳴っている間に「おわり」をタップして次が始まっていたら、何もしない
        guard isSameFinishedRun(run) else { return }
        guard let close = closeAfterFinish else {
            keeper?.end()
            updateGate()
            return
        }
        try? await Task.sleep(for: .seconds(closeDelay))
        guard isSameFinishedRun(run) else { return }
        keeper?.end()
        updateGate()
        close()
    }

    /// 終わったのが、まだその回のままか（その後にタップで次が始まっていないか）
    private func isSameFinishedRun(_ run: Date) -> Bool {
        engine.isFinished && !engine.isCancelled && engine.endAt == run
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(engine) {
            defaults.set(data, forKey: Self.engineKey)
        }
    }

    /// 文字盤のコンプリケーションを描き直させる。
    ///
    /// **設定が変わったときだけ。** コンプリケーションが出しているのは
    /// 「設定してある秒数」と色の2つで、タイマーの進み具合では変わらない。
    /// 開始・終了のたびに呼ぶと、WidgetKit の描き直しの持ち分を無駄に使う。
    private func reloadComplication() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - 動作確認用

    #if DEBUG
    /// シミュレータで状態を直接出すための入口。**リリース構成には入らない。**
    ///
    ///     OTT_STATE=running:45   残り45秒で走っている
    ///     OTT_STATE=last:7       終わりが近い
    ///     OTT_STATE=done         終わった直後
    ///     OTT_STATE=paused:62    残り62秒で一時停止中
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
        case "paused":
            engine = TimerEngine(duration: duration, startedAt: now.addingTimeInterval(-(Double(duration) - n)))
            engine.pause(at: now)
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
