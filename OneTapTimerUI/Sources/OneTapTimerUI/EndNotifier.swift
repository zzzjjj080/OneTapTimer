import Foundation
import UserNotifications

/// 腕を下ろしている間の合図。
///
/// アプリが前に出ていれば自分で触覚を鳴らす。裏に回っているときは鳴らせないので、
/// **終わる時刻をあらかじめ通知として登録しておく。** 通知は一度だけ震えて、それで終わり。
///
/// 二重に知らせないよう、前に出ているときは ``NotificationGate`` が表示を抑える。
/// 終わりの合図を予約するもの。テストでは偽物を差す
@MainActor
public protocol EndScheduling: AnyObject {
    func requestPermission() async
    func schedule(endAt: Date, duration: Int)
    func cancel()
}

@MainActor
public final class EndNotifier: EndScheduling {

    public private(set) var isAllowed = false
    private let center = UNUserNotificationCenter.current()
    private let id = "end"

    public init() {}

    public func requestPermission() async {
        do {
            isAllowed = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            isAllowed = false
        }
    }

    /// 終わる時刻に1回。前の登録は消す。
    ///
    /// **許可が下りていないなら、登録そのものをしない。**
    /// watchOS は許可を聞いていない状態で `add` すると、そこで許可ダイアログを出す。
    /// 画面を撮っている最中に出られると、以後どの画面も撮れなくなる（引き継ぎ書 4-107）。
    /// 許可が無ければどのみち鳴らないので、黙って何もしないのが正しい。
    public func schedule(endAt: Date, duration: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard isAllowed else { return }
        let after = endAt.timeIntervalSinceNow
        guard after > 0.5 else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "おわり", bundle: .module)
        content.body = TimeTextBridge.brief(duration)
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: after, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    public func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}

/// 前に出ている間は通知を出さない。そのときは ``Runner`` が自分で鳴らす。
///
/// `UNUserNotificationCenter.delegate` に据える。**起動時に1回だけ。**
public final class NotificationGate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    /// 画面が前に出ているか。scenePhase から更新する
    public var isForeground = false

    public override init() { super.init() }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        isForeground ? [] : [.banner, .sound]
    }
}

import OneTapTimerCore
enum TimeTextBridge {
    static func brief(_ seconds: Int) -> String { TimeText.brief(seconds) }
}


/// 何もしない予約係。**画面を撮るときだけ差し替える。**
///
/// watchOS のシミュレータは、通知まわりのどこかに触れると許可ダイアログを出すことがある。
/// 一度出ると、合成タップでは消せず（引き継ぎ書 4-24）、以後どの画面も撮れない。
/// 撮影中は `UNUserNotificationCenter` に一切触らないのが確実。
public final class SilentNotifier: EndScheduling {
    public init() {}
    public func requestPermission() async {}
    public func schedule(endAt: Date, duration: Int) {}
    public func cancel() {}
}
