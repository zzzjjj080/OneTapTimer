import SwiftUI

/// 設定へ入る歯車。**上部・左。時刻の左側で、画面の色に溶ける薄いガラスの円。**
///
/// 押しやすさのために丸そのものは大きめにし、目立たないのは色で作る。
public struct GearButton: View {
    public var skin: Skin
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
                Image(systemName: "gearshape.fill")
                    .font(.system(size: size * 0.5, weight: .semibold))
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
