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
    /// **見た目の丸より外側まで押せる幅。** 丸の周りのこの幅も押したことになる。
    /// 置く側は、見た目の位置がずれないよう、この幅ぶん外側へ寄せて置く
    public var hitPadding: CGFloat
    public var action: () -> Void

    public init(skin: Skin, size: CGFloat, hitPadding: CGFloat = 0, action: @escaping () -> Void) {
        self.skin = skin; self.size = size; self.hitPadding = hitPadding; self.action = action
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
            .padding(hitPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("時間を変える", bundle: .module))
        .accessibilityIdentifier("gear")
    }
}

/// 一時停止のボタン。**左上に小さく**（あまり使わない）。
///
/// 走っている間は、設定の入口と同じ目立たない丸に ⏸。
/// **止めている間は、色を塗った丸に ▶。** 灰色になった水と並んで、止まっていると一目で分かる。
public struct PauseButton: View {
    public var skin: Skin
    public var isPaused: Bool
    public var size: CGFloat
    /// 見た目の丸より外側まで押せる幅（``SettingButton/hitPadding`` と同じ考え方）
    public var hitPadding: CGFloat
    public var action: () -> Void

    public init(skin: Skin, isPaused: Bool, size: CGFloat, hitPadding: CGFloat = 0, action: @escaping () -> Void) {
        self.skin = skin; self.isPaused = isPaused; self.size = size; self.hitPadding = hitPadding; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(isPaused ? skin.accent : skin.glass)
                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: size * 0.4, weight: .bold))
                    // 塗った丸の上は地の色（ほぼ黒）。明るい色の上ではこちらが読める
                    .foregroundStyle(isPaused ? Color(hex: PaletteHex.ground) : skin.glassInk)
                    .offset(x: isPaused ? size * 0.03 : 0)   // ▶ は見た目の重心が左に寄るので少し右へ
            }
            .frame(width: size, height: size)
            .padding(hitPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isPaused ? "再開" : "一時停止", bundle: .module))
        .accessibilityIdentifier("pause")
    }
}

