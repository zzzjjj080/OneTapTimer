import SwiftUI
import WatchKit
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変える画面。**±60s ／ 値 ／ ±10s ／ 色と完了。**
///
/// Digital Crown は1目盛りが10秒。やめるときはクラウンを押して文字盤へ戻る。
struct SettingsView: View {
    @Environment(Runner.self) private var runner

    @State private var draft: Int = DurationRule.standard
    /// Digital Crown は Double でしか回らない。**目盛り＝10秒**で持つ。
    /// 秒で持って by: 1 にすると、目盛りの触覚が1秒ごとに鳴って、回しても値が動かないように感じる
    @State private var crown: Double = DurationRule.crown(fromSeconds: DurationRule.standard)
    @FocusState private var focused: Bool

    private var screen: CGSize { WKInterfaceDevice.current().screenBounds.size }
    private var h: CGFloat { screen.height }

    // **寸法は画面の高さの比で決める。** 40mm（197pt）から 49mm（251pt）までどれでも収まる。
    // 「40mm かそれ以外か」の2段で決めていたら、値を大きくしたとき 41〜44mm（215〜224pt）ではみ出す計算になった。
    // 足すと高さの 94% ほど：上の余白 11% ＋ ボタン 14.5%×3 ＋ 値 30% ＋ 間と下 9%
    // 上の余白を 7.5% にしたら、右上のシステムの時計が「+60s」のボタンに重なった

    /// 上に空ける高さ。ここにシステムの時計が出る
    private var clockReserve: CGFloat { h * 0.11 }
    private var sideInset: CGFloat { max(8, screen.width * 0.045) }
    private var gap: CGFloat { h * 0.02 }
    /// ボタン1つぶんの幅。2列に割る。**寸法はレイアウトに聞かず、画面の実寸から決める**（引き継ぎ書 4-62b）
    private var buttonSize: CGSize {
        CGSize(width: (screen.width - sideInset * 2 - gap) / 2, height: h * 0.145)
    }
    /// **今の設定値はなるべく大きく。** 画面の高さの 23.5%（46mm で 58pt。前は 36pt）
    private var valueSize: CGFloat { h * 0.235 }

    var body: some View {
        ZStack {
            Color(hex: PaletteHex.ground).ignoresSafeArea()

            VStack(spacing: gap) {
                DurationEditor(value: $draft, theme: runner.themeHex, buttonSize: buttonSize, spacing: gap,
                               valueSize: valueSize,
                               onStep: { up in
                                   runner.stepped(up: up)
                                   crown = DurationRule.crown(fromSeconds: draft)
                               })

                SettingsFooter(theme: runner.themeHex, number: runner.theme,
                               height: buttonSize.height, spacing: gap,
                               onColor: { runner.cycleTheme() },
                               onDone: { runner.apply(duration: draft) })
                    .padding(.top, gap * 0.4)
            }
            .padding(.top, clockReserve)
            .padding(.horizontal, sideInset)
            .padding(.bottom, h * 0.025)
        }
        .ignoresSafeArea()
        .focusable()
        .focused($focused)
        .digitalCrownRotation($crown,
                              from: DurationRule.crownRange.lowerBound,
                              through: DurationRule.crownRange.upperBound,
                              by: 1, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        // つまみ側からは10秒に乗せて受ける。つまみの値は書き戻さない（回している最中に引き戻される）
        .onChange(of: crown) { _, v in
            let s = DurationRule.seconds(fromCrown: v)
            if s != draft { draft = s }
        }
        .onAppear {
            draft = runner.duration
            crown = DurationRule.crown(fromSeconds: runner.duration)
            focused = true
        }
    }
}
