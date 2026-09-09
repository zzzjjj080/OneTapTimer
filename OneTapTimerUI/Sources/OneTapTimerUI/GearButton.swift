import SwiftUI
import OneTapTimerCore

/// 設定への入口。**上の中央に、時計のマークといまの長さ。** 押すと時間を変える画面へ。
///
/// 歯車だと「設定」にしか見えなかった。いまの長さ（`1:30`）を出しておけば
/// 「ここで時間を変える」と分かるし、押す的も大きい。
public struct SettingPill: View {
    public var skin: Skin
    public var duration: Int
    public var height: CGFloat
    public var action: () -> Void

    public init(skin: Skin, duration: Int, height: CGFloat, action: @escaping () -> Void) {
        self.skin = skin; self.duration = duration; self.height = height; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: height * 0.18) {
                Image(systemName: "timer")
                    .font(.system(size: height * 0.5, weight: .semibold))
                Text(TimeText.clock(Double(duration)))
                    .font(.system(size: height * 0.5, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(skin.glassInk)
            .padding(.horizontal, height * 0.5)
            .frame(height: height)
            .background(Capsule().fill(skin.glass))
            .overlay(Capsule().strokeBorder(skin.glassEdge, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("時間を変える", bundle: .module))
        .accessibilityIdentifier("gear")
    }
}
