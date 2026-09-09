import SwiftUI
import OneTapTimerCore

/// 時間を合わせる部品。**大きな値と、同じ大きさの4つのボタン。**
///
/// 上の段が ±10秒（基本はこれで合わせる）、下の段が ±1分。
/// 大きさを揃えて2×2に並べると、どこを押しても外さない。
/// 決定のボタンは外側（Watch もシートも「完了」）が持つ。
/// Digital Crown も外側で付ける（`value` を書き換えればここは追従する）。
public struct DurationEditor: View {
    @Binding public var value: Int
    /// ボタン1つぶんの大きさ。4つとも同じ
    public var buttonSize: CGSize
    public var spacing: CGFloat
    public var valueSize: CGFloat
    public var onStep: (Bool) -> Void

    public init(value: Binding<Int>, buttonSize: CGSize, spacing: CGFloat, valueSize: CGFloat,
                onStep: @escaping (Bool) -> Void) {
        _value = value
        self.buttonSize = buttonSize; self.spacing = spacing; self.valueSize = valueSize
        self.onStep = onStep
    }

    public var body: some View {
        VStack(spacing: spacing) {
            valueText
                .padding(.bottom, spacing * 0.5)
                .accessibilityIdentifier("value")

            HStack(spacing: spacing) {
                StepButton(title: "−10", unit: "秒", size: buttonSize) { change(by: -DurationRule.fineStep) }
                    .accessibilityIdentifier("minus10")
                StepButton(title: "+10", unit: "秒", size: buttonSize) { change(by: DurationRule.fineStep) }
                    .accessibilityIdentifier("plus10")
            }
            HStack(spacing: spacing) {
                StepButton(title: "−1", unit: "分", size: buttonSize) { change(by: -DurationRule.coarseStep) }
                    .accessibilityIdentifier("minus60")
                StepButton(title: "+1", unit: "分", size: buttonSize) { change(by: DurationRule.coarseStep) }
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
    let step: () -> Void

    @State private var holding: Task<Void, Never>?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(title)
                .font(.system(size: size.height * 0.48, weight: .heavy, design: .rounded))
            Text(unit, bundle: .module)
                .font(.system(size: size.height * 0.29, weight: .semibold))
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(Color(hex: PaletteHex.ink))
        .frame(width: size.width, height: size.height)
        .background(RoundedRectangle(cornerRadius: size.height * 0.34, style: .continuous)
            .fill(Color.well.opacity(holding == nil ? 1 : 1.6)))
        .contentShape(Rectangle())
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


/// 設定画面の下段。**色の見本（丸）と「完了」（横長）。**
///
/// 色は押すたびに次の組へ。番号を丸の中に出すので、いま何番かが分かる。
/// 完了は残り幅いっぱいにして、いちばん押しやすい場所にする。
public struct SettingsFooter: View {
    public var theme: ThemeHex
    public var number: Int
    public var height: CGFloat
    public var spacing: CGFloat
    public var onColor: () -> Void
    public var onDone: () -> Void

    public init(theme: ThemeHex, number: Int, height: CGFloat, spacing: CGFloat,
                onColor: @escaping () -> Void, onDone: @escaping () -> Void) {
        self.theme = theme; self.number = number; self.height = height; self.spacing = spacing
        self.onColor = onColor; self.onDone = onDone
    }

    private var fill: LinearGradient {
        LinearGradient(colors: [Color(hex: theme.liquidTop), Color(hex: theme.liquidBottom)],
                       startPoint: .top, endPoint: .bottom)
    }

    public var body: some View {
        HStack(spacing: spacing) {
            Button(action: onColor) {
                ZStack {
                    Circle().fill(fill)
                    Text("\(number)")
                        .font(.system(size: height * 0.44, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color(hex: PaletteHex.ground))
                }
                .frame(width: height, height: height)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("色", bundle: .module))
            .accessibilityIdentifier("theme")

            Button(action: onDone) {
                Text("完了", bundle: .module)
                    .font(.system(size: height * 0.4, weight: .bold))
                    .tracking(1)
                    // 塗りが明るいので、文字は地の色（ほぼ黒）。こちらのほうが読める
                    .foregroundStyle(Color(hex: PaletteHex.ground))
                    .frame(maxWidth: .infinity, minHeight: height)
                    .background(Capsule().fill(fill))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("go")
        }
    }
}
