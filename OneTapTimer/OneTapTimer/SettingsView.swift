import SwiftUI
import WatchKit
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変える画面。**±10秒・±1分・完了の5つだけ。** Digital Crown は1目盛りが10秒。
///
/// やめるときはクラウンを押して文字盤へ戻る（裏へ回った時点で設定は閉じる）。
struct SettingsView: View {
    @Environment(Runner.self) private var runner

    @State private var draft: Int = DurationRule.standard
    /// Digital Crown は Double でしか回らない。**目盛り＝10秒**で持つ。
    /// 秒で持って by: 1 にすると、目盛りの触覚が1秒ごとに鳴って、回しても値が動かないように感じる
    @State private var crown: Double = DurationRule.crown(fromSeconds: DurationRule.standard)
    @FocusState private var focused: Bool

    private var screen: CGSize { WKInterfaceDevice.current().screenBounds.size }
    /// 40mm は詰める
    private var tiny: Bool { screen.height < 210 }
    /// 上に空ける高さ。ここにシステムの時計が出る
    private var clockReserve: CGFloat { tiny ? 20 : 26 }

    var body: some View {
        ZStack {
            Color(hex: PaletteHex.ground).ignoresSafeArea()

            VStack(spacing: 0) {
                DurationEditor(value: $draft,
                               fineSize: CGSize(width: tiny ? 66 : 78, height: tiny ? 38 : 44),
                               valueSize: tiny ? 32 : 40, labelSize: 11,
                               onStep: { up in
                                   runner.stepped(up: up)
                                   crown = DurationRule.crown(fromSeconds: draft)
                               })

                Spacer(minLength: 4)

                // 色。押すたびに 1→2→…→10→1。水の色で塗って、いまの番号を出す
                Button {
                    runner.cycleTheme()
                } label: {
                    HStack(spacing: 4) {
                        Text("色")
                        Text("\(runner.theme)").fontWeight(.heavy).monospacedDigit()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: PaletteHex.ground))
                    .frame(width: 72, height: tiny ? 24 : 28)
                    .background(Capsule().fill(
                        LinearGradient(colors: [Color(hex: runner.themeHex.liquidTop), Color(hex: runner.themeHex.liquidBottom)],
                                       startPoint: .top, endPoint: .bottom)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("theme")

                Spacer(minLength: 4)

                Button {
                    runner.apply(duration: draft)
                } label: {
                    Text("完了して戻る")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(0.5)
                        // 塗りがティールなので、文字は黒。こちらのほうが読める
                        .foregroundStyle(Color(hex: PaletteHex.ground))
                        .frame(maxWidth: .infinity, minHeight: tiny ? 30 : 34)
                        .background(Capsule().fill(Color(hex: runner.themeHex.liquidTop)))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("go")
            }
            .padding(.top, clockReserve)
            .padding(.horizontal, 12)
            .padding(.bottom, tiny ? 6 : 8)
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
