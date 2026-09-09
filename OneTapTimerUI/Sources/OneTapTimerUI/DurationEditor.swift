import SwiftUI
import OneTapTimerCore

/// 時間を合わせる部品。大きな値と、**±10秒（大きめ）・±1分（小さめ）の4つだけ。**
///
/// チップも「開始」も付けない。決定のボタンは外側（Watch は「完了して戻る」、iPhone はシート）が持つ。
/// Digital Crown も外側で付ける（`value` を書き換えればここは追従する）。
public struct DurationEditor: View {
    @Binding public var value: Int
    /// ±10秒 のボタンの大きさ。±1分 はこれより一回り小さい
    public var fineSize: CGSize
    public var valueSize: CGFloat
    public var labelSize: CGFloat
    public var onStep: (Bool) -> Void

    public init(value: Binding<Int>, fineSize: CGSize, valueSize: CGFloat, labelSize: CGFloat,
                onStep: @escaping (Bool) -> Void) {
        _value = value
        self.fineSize = fineSize; self.valueSize = valueSize; self.labelSize = labelSize
        self.onStep = onStep
    }

    private var coarseSize: CGSize { CGSize(width: fineSize.width * 0.9, height: fineSize.height * 0.72) }

    public var body: some View {
        VStack(spacing: fineSize.height * 0.18) {
            valueText
                .accessibilityIdentifier("value")

            // 10秒。基本はこれで合わせるので、大きく・上に
            HStack(spacing: fineSize.width * 0.18) {
                StepButton(title: "−10", unit: "秒", size: fineSize, bold: true) { change(by: -DurationRule.fineStep) }
                    .accessibilityIdentifier("minus10")
                StepButton(title: "+10", unit: "秒", size: fineSize, bold: true) { change(by: DurationRule.fineStep) }
                    .accessibilityIdentifier("plus10")
            }
            // 1分。たまに使う
            HStack(spacing: fineSize.width * 0.18) {
                StepButton(title: "−1", unit: "分", size: coarseSize, bold: false) { change(by: -DurationRule.coarseStep) }
                    .accessibilityIdentifier("minus60")
                StepButton(title: "+1", unit: "分", size: coarseSize, bold: false) { change(by: DurationRule.coarseStep) }
                    .accessibilityIdentifier("plus60")
            }
        }
    }

    /// `1分30秒` の「1」と「30」を大きく、単位を小さく。
    private var valueText: some View {
        let m = value / 60, s = value % 60
        let big = Font.system(size: valueSize, weight: .heavy, design: .rounded)
        let small = Font.system(size: valueSize * 0.38, weight: .semibold)
        return HStack(alignment: .firstTextBaseline, spacing: 1) {
            if m > 0 {
                Text("\(m)").font(big)
                Text("分", bundle: .module).font(small)
            }
            if s > 0 || m == 0 {
                Text(m > 0 ? String(format: "%02d", s) : "\(s)").font(big)
                Text("秒", bundle: .module).font(small)
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(Color(hex: PaletteHex.ink))
        .contentTransition(.numericText())
        .animation(.snappy(duration: 0.2), value: value)
    }

    private func change(by: Int) {
        let v = DurationRule.stepped(value, by: by)
        guard v != value else { return }
        value = v
        onStep(by > 0)
    }
}

/// ＋ − のボタン。**押している間、動き続ける。**
///
/// `Button` ではなく長押しで受けている。`Button` は指を離したときにしか呼ばれないので、
/// 押しっぱなしを拾えない。`pressing:` なら押した瞬間と離した瞬間の両方が来る。
struct StepButton: View {
    let title: String
    let unit: LocalizedStringKey
    let size: CGSize
    let bold: Bool
    let step: () -> Void

    @State private var holding: Task<Void, Never>?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(title)
                .font(.system(size: size.height * (bold ? 0.5 : 0.46), weight: .heavy, design: .rounded))
            Text(unit, bundle: .module)
                .font(.system(size: size.height * 0.3, weight: .semibold))
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(Color(hex: PaletteHex.ink))
        .frame(width: size.width, height: size.height)
        .background(Capsule().fill(Color.well.opacity(holding == nil ? 1 : 1.6)))
        .contentShape(Capsule())
        // 押し続けても `perform` が呼ばれないよう、長い時間を指定しておく。
        .onLongPressGesture(minimumDuration: 3600, pressing: { pressing in
            if pressing { begin() } else { end() }
        }, perform: {})
        .onDisappear { end() }
    }

    private func begin() {
        end()
        step()
        holding = Task { @MainActor in
            try? await Task.sleep(for: .seconds(HoldRepeat.delay))
            var done = 0
            while !Task.isCancelled {
                step()
                try? await Task.sleep(for: .seconds(HoldRepeat.interval(after: done)))
                done += 1
            }
        }
    }

    private func end() {
        holding?.cancel()
        holding = nil
    }
}
