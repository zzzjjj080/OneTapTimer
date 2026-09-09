import SwiftUI
import OneTapTimerCore

/// 時間を変える画面への入口。**上の中央に置く丸いボタン。**
///
/// 歯車だと「設定」にしか見えず、時間を変える場所だと分からなかった。
/// ストップウォッチの絵に**＋−の印**を重ねて、「この時間をいじる」ことを1つの絵で示す。
/// 文字は入れない（何秒かは画面の真ん中に大きく出ているので、二度書く意味がない）。
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
                Circle().strokeBorder(skin.glassEdge, lineWidth: 1)

                Image(systemName: "timer")
                    .font(.system(size: size * 0.46, weight: .semibold))
                    .foregroundStyle(skin.glassInk)

                // ＋− の印。地の色で縁取ってから重ねる。時計の絵と混ざらない
                Image(systemName: "plusminus")
                    .font(.system(size: size * 0.26, weight: .black))
                    .foregroundStyle(skin.isDone ? Color(hex: skin.theme.doneGround) : Color(hex: PaletteHex.ground))
                    .padding(size * 0.07)
                    .background(Circle().fill(skin.accent))
                    .offset(x: size * 0.3, y: size * 0.3)
            }
            .frame(width: size, height: size)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("時間を変える", bundle: .module))
        .accessibilityIdentifier("gear")
    }
}
