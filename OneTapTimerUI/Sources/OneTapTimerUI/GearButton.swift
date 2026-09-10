import SwiftUI
import OneTapTimerCore

/// 時間を変える画面への入口。**上の中央に置く丸いボタン。**
///
/// 歯車だと「設定」にしか見えないので、ストップウォッチの絵にした。
/// **印は重ねない。** ＋− を足したら、小さい丸の中がうるさくなった。
/// 文字も入れない（何秒かは画面の真ん中に大きく出ているので、二度書く意味がない）。
public struct SettingButton: View {
    public var skin: Skin
    /// 丸の直径。指1本で押せるよう、Watch でも 40pt は取る
    public var size: CGFloat
    public var action: () -> Void

    public init(skin: Skin, size: CGFloat, action: @escaping () -> Void) {
        self.skin = skin; self.size = size; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(skin.glass)
                Image(systemName: "timer")
                    .font(.system(size: size * 0.52, weight: .medium))
                    .foregroundStyle(skin.glassInk)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("時間を変える", bundle: .module))
        .accessibilityIdentifier("gear")
    }
}
