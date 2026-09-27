import Foundation
import OneTapTimerCore

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
    /// 色の組（1〜10）。**1.2 まで。**いまは `designKey` の中の `C…` を見る
    public static let themeKey = "theme"
    /// 見た目ひと組（`FaceDesign.text` の1行）
    public static let designKey = "design"
    /// その見た目を決めた時刻（iPhone と Watch で新しいほうを採る）
    public static let designAtKey = "designAt"

    /// エンタイトルメントが無い環境（テストなど）では素の保存先に落とす
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    // MARK: - 見た目

    /// 保存してある見た目。**無ければ、1.2 までの「色だけ」の設定から作る**（初めて開いた人も含めて既定に落ちる）
    public static func design(_ d: UserDefaults = SharedStore.defaults) -> FaceDesign {
        if let text = d.string(forKey: designKey) { return FaceDesign(text: text) }
        let old = d.integer(forKey: themeKey)
        let color = FaceColor.allCases.first { $0.number == old } ?? .fallback
        return FaceDesign(color: color)
    }

    /// 見た目を保存する。**文字盤の拡張も同じキーを読む**ので、書いたら描き直しを頼むこと
    public static func save(_ design: FaceDesign, at date: Date = .now,
                            to d: UserDefaults = SharedStore.defaults) {
        d.set(design.text, forKey: designKey)
        d.set(date, forKey: designAtKey)
        // 1.2 までのキーも合わせておく（古い拡張が残っていても色がずれない）
        d.set(design.color.number, forKey: themeKey)
    }

    /// 最後に見た目を決めた時刻
    public static func designUpdatedAt(_ d: UserDefaults = SharedStore.defaults) -> Date? {
        d.object(forKey: designAtKey) as? Date
    }
}
