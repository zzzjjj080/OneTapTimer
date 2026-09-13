import WatchKit
import OneTapTimerUI

/// 走っている間、アプリを文字盤に戻させないための仕掛け。
///
/// **watchOS は放っておくと1分ほどで文字盤へ戻る。** 戻るとこちらのコードも止まるので、
/// 終わりの合図が通知頼りになり、実際に十数秒ずれた。
///
/// `WKExtendedRuntimeSession` を持っている間は、腕を下ろしても前面に留まり、
/// 触覚も自分で鳴らせる。**種別は `Info.plist` の `WKBackgroundModes` で決まる**（`self-care`）。
///
/// **self-care の上限は10分。**（WWDC 2019「Extended Runtime for watchOS Apps」。mindfulness が1時間）
/// 10分を超えるタイマーでは途中で留めが外れ、終わりの合図は予約しておいた通知が受け持つ。
///
/// **クラウンを押すと、セッションは「前面から外れた」（`.resignedFrontmost`）で終わる。**
/// 腕を下ろしただけなら画面が消えてもセッションは続く。この違いで「利用者が出ていった」を知る。
///
/// 始められなかった／途中で切れたときは黙って諦め、`isKeeping` を false にする。
/// 受け取った `Runner` が通知へ切り替える（**握り潰さず、必ず代わりを用意する**）。
@MainActor
final class FrontKeeper: NSObject, ForegroundKeeping, WKExtendedRuntimeSessionDelegate {

    private(set) var isKeeping = false
    var onChange: (() -> Void)?
    var onUserLeft: (() -> Void)?

    private var session: WKExtendedRuntimeSession?

    func begin() {
        // 終わったセッションを握ったままだと、二度と張れない。生きているときだけ何もしない
        if let s = session, s.state != .invalid { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        s.start()
        log("始める")
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
        Task { @MainActor in
            log("始まった")
            setKeeping(true)
        }
    }

    /// 上限が近い。ここで諦める。**この時点で通知へ切り替わる。**
    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in
            log("上限が近い")
            setKeeping(false)
        }
    }

    nonisolated func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                            didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                            error: Error?) {
        let ended = extendedRuntimeSession
        Task { @MainActor in
            log("終わった 理由=\(Self.describe(reason)) error=\(String(describing: error))")
            // 張り直したあとに古いセッションの終わりが遅れて届いても、新しい方を捨てない
            guard ended === session else { return }
            session = nil
            setKeeping(false)
            if reason == .resignedFrontmost {
                onUserLeft?()
            }
        }
    }

    // MARK: - 記録

    private static func describe(_ r: WKExtendedRuntimeSessionInvalidationReason) -> String {
        switch r {
        case .none: "none（自分で invalidate）"
        case .sessionInProgress: "sessionInProgress（ほかのセッションが動いている）"
        case .expired: "expired（上限）"
        case .resignedFrontmost: "resignedFrontmost（利用者が出ていった）"
        case .suppressedBySystem: "suppressedBySystem"
        case .error: "error"
        @unknown default: "unknown(\(r.rawValue))"
        }
    }

    private func log(_ message: String) {
        #if DEBUG
        print("[FrontKeeper] \(message)")
        #endif
    }
}
