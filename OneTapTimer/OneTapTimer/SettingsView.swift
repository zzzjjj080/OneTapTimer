import SwiftUI
import WatchKit
import OneTapTimerCore
import OneTapTimerUI

/// 時間を変える画面。**同じ大きさの4つのボタン（±10秒・±1分）＋ 色 ＋ 完了。**
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
    /// 40mm は詰める
    private var tiny: Bool { screen.height < 210 }

    /// 上に空ける高さ。ここにシステムの時計が出る
    private var clockReserve: CGFloat { tiny ? 18 : 24 }
    private var sideInset: CGFloat { tiny ? 8 : 10 }
    private var gap: CGFloat { tiny ? 5 : 7 }
    /// ボタン1つぶんの幅。2列に割る。**寸法はレイアウトに聞かず、画面の実寸から決める**（引き継ぎ書 4-62b）
    private var buttonSize: CGSize {
        CGSize(width: (screen.width - sideInset * 2 - gap) / 2, height: tiny ? 34 : 40)
    }

    var body: some View {
        ZStack {
            Color(hex: PaletteHex.ground).ignoresSafeArea()

            VStack(spacing: gap) {
                DurationEditor(value: $draft, buttonSize: buttonSize, spacing: gap,
                               valueSize: tiny ? 32 : 38,
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
            .padding(.bottom, tiny ? 4 : 6)
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
