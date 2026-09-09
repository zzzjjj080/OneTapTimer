import Foundation

/// アプリと文字盤のコンプリケーションで共有する保存先。
///
/// コンプリケーションは別のプロセスなので、素の `UserDefaults.standard` は読めない。
/// App Group のコンテナに置く。**キーの名前はコンプリケーション側と合わせること**
/// （拡張は `OneTapTimerUI` を読み込まず、同じキーを自前で読む）。
public enum SharedStore {
    public static let groupID = "group.com.zzzjjj080.OneTapTimer"

    /// 設定してある長さ（秒）
    public static let durationKey = "duration"
    /// いまのタイマー（`TimerEngine` の JSON）
    public static let engineKey = "engine"
    /// 色の組（1〜10）
    public static let themeKey = "theme"

    /// エンタイトルメントが無い環境（テストなど）では素の保存先に落とす
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }
}
