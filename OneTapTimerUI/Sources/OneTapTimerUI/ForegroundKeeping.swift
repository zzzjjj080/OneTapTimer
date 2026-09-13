import Foundation

/// 走っている間、アプリを前面に留めておく仕掛け。
///
/// **watchOS は放っておくと1分ほどで文字盤に戻る。** 戻ると画面が消えるだけでなく、
/// こちらのコードも止まるので、終わりの合図を通知に頼ることになり、数秒〜十数秒ずれる。
///
/// 中身は Watch 側の `WKExtendedRuntimeSession`。iPhone には要らないので、
/// ここでは口だけ決めておく（`OneTapTimerUI` は WatchKit に依存させない）。
@MainActor
public protocol ForegroundKeeping: AnyObject {
    /// いま前面に留まれているか。**留まれている間は、終わりの合図を自分で鳴らせる。**
    var isKeeping: Bool { get }
    /// 留まれるかどうかが変わったときに呼ぶ
    var onChange: (() -> Void)? { get set }
    /// **利用者が自分で出ていった**と、セッションの終わり方から分かったときに呼ぶ
    /// （クラウンを押した／ほかのアプリへ移った）。腕を下ろしただけでは呼ばない
    var onUserLeft: (() -> Void)? { get set }
    /// 最後に起きたこと（動作確認用。画面に出して、留めが効いているかを実機で見る）
    var lastEvent: String { get }
    func begin()
    func end()
}

public extension ForegroundKeeping {
    var lastEvent: String { "" }
}
