import WatchKit
import OneTapTimerUI

/// 走っている間、アプリを文字盤に戻させないための仕掛け。
///
/// **watchOS は放っておくと1分ほどで文字盤へ戻る。** 戻るとこちらのコードも止まるので、
/// 終わりの合図が通知頼りになり、実際に十数秒ずれた。
///
/// `WKExtendedRuntimeSession` を持っている間は、腕を下ろしても前面に留まり、
/// 触覚も自分で鳴らせる。**種別は `Info.plist` の `WKBackgroundModes` で決まる**（`self-care`）。
/// 上限は1時間で、このアプリの最大値と同じ。
///
/// 始められなかった／途中で切れたときは黙って諦め、`isKeeping` を false にする。
/// 受け取った `Runner` が通知へ切り替える（**握り潰さず、必ず代わりを用意する**）。
@MainActor
final class FrontKeeper: NSObject, ForegroundKeeping, WKExtendedRuntimeSessionDelegate {

    private(set) var isKeeping = false
    var onChange: (() -> Void)?

    private var session: WKExtendedRuntimeSession?

    func begin() {
        guard session == nil else { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        s.start()
    }

    func end() {
        // 走っていないセッションに invalidate を呼んでも害は無い
        session?.invalidate()
        session = nil
        setKeeping(false)
    }

    private func setKeeping(_ value: Bool) {
        guard isKeeping != value else { return }
        isKeeping = value
        onChange?()
    }

    // MARK: - WKExtendedRuntimeSessionDelegate

    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in setKeeping(true) }
    }

    /// 上限が近い。ここで諦める。**この時点で通知へ切り替わる。**
    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in setKeeping(false) }
    }

    nonisolated func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                            didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                            error: Error?) {
        Task { @MainActor in
            #if DEBUG
            print("[FrontKeeper] 終了 reason=\(reason.rawValue) error=\(String(describing: error))")
            #endif
            session = nil
            setKeeping(false)
        }
    }
}
