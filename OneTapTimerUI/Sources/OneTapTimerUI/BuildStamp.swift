import Foundation

/// 実機に入っている版の印。**設定画面のいちばん下に小さく出す。**
///
/// 「実機に入れて」と言われても、画面から版が分からないと入れ替わったか確かめようがない
/// （引き継ぎ書 4-145）。印は手で増やさず、インストール用スクリプトが
/// `OTT_BUILD_STAMP` としてビルドのたびに渡す。
public enum BuildStamp {
    /// 例：`1.0.1 (5) · b53 09/16 12:34`。Xcode から直接ビルドしたときは版番号だけ
    public static var text: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        let stamp = (info?["OTTBuildStamp"] as? String) ?? ""
        return stamp.isEmpty ? "\(version) (\(build))" : "\(version) (\(build)) · \(stamp)"
    }
}
