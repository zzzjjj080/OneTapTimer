#if canImport(WatchConnectivity)
import Foundation
import OneTapTimerCore
import WatchConnectivity

/// 見た目を iPhone から Apple Watch へ送る。
///
/// **App Group は同じ端末の中だけ**なので、iPhone で決めた見た目は Watch には届かない。
/// `updateApplicationContext` は**最新の1件だけ**が残り、相手が次に起きたときに届く（溜まらない）。
///
/// 決めるのは iPhone だけ（Watch には見た目を変える操作が無い）。それでも**時刻を一緒に送り、
/// 新しいほうを採る**：Watch を先に起こしてから iPhone を開いた、のような順番でも古い設定に戻らない。
public final class DesignSync: NSObject, WCSessionDelegate, @unchecked Sendable {
    public static let shared = DesignSync()

    static let designField = "design"
    static let atField = "designAt"

    private var defaults: UserDefaults = SharedStore.defaults
    /// 受け取って保存したあとに呼ばれる（画面と文字盤の描き直し）
    public var onApply: (@Sendable (FaceDesign) -> Void)?

    /// アプリが立ち上がったら呼ぶ。**Watch 側でも呼ぶ**（受け取る側も繋いでおかないと届かない）
    public func start(defaults: UserDefaults = SharedStore.defaults,
                      onApply: (@Sendable (FaceDesign) -> Void)? = nil) {
        self.defaults = defaults
        self.onApply = onApply
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// 相手へ送る。**届くのは相手が次に起きたとき**（すぐとは限らない）
    public func send(_ design: FaceDesign, at date: Date = .now) {
        SharedStore.save(design, at: date, to: defaults)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        try? session.updateApplicationContext([Self.designField: design.text, Self.atField: date])
    }

    /// 相手のほうが後に決めていれば取り込む
    private func receive(_ context: [String: Any]) {
        guard let text = context[Self.designField] as? String else { return }
        let at = context[Self.atField] as? Date ?? .now
        if let mine = SharedStore.designUpdatedAt(defaults), mine > at { return }
        let design = FaceDesign(text: text)
        SharedStore.save(design, at: at, to: defaults)
        onApply?(design)
    }

    // MARK: WCSessionDelegate

    public func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                        error: Error?) {
        // 起きた時点で溜まっている1件を取り込む（受け取りの通知より先に来ることがある）
        if !session.receivedApplicationContext.isEmpty { receive(session.receivedApplicationContext) }
    }

    public func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        receive(context)
    }

    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    public func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}
#endif
