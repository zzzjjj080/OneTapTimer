import SwiftUI
import OneTapTimerCore

/// 時間を合わせる部品。**大きな値をはさんで、上に ±60秒、下に ±10秒。**
///
/// 実機で触って、この並びに落ち着いた。粗いほうを上に置くと、
/// 「大きく動かしてから、下で細かく詰める」が上から下への動きになる。
/// 4つとも同じ大きさなので、どこを押しても外さない。
/// 単位は `s` に統一した（`10s` `60s` で通じるし、分と秒が混ざらない）。
/// 決定のボタンは外側（Watch もシートも「完了」）が持つ。
/// Digital Crown も外側で付ける（`value` を書き換えればここは追従する）。
///
/// **ボタンに色を付ける**（2026-09-13）。＋ は色の組の明るいほうに黒い文字、
/// − は濃いほうに白い文字。どちらも色の組の読みやすさのテストを通っている組み合わせ。
public struct DurationEditor: View {
    @Binding public var value: Int
    public var theme: ThemeHex
    /// ボタン1つぶんの大きさ。4つとも同じ
    public var buttonSize: CGSize
    public var spacing: CGFloat
    public var valueSize: CGFloat
    public var onStep: (Bool) -> Void

    public init(value: Binding<Int>, theme: ThemeHex, buttonSize: CGSize, spacing: CGFloat, valueSize: CGFloat,
                onStep: @escaping (Bool) -> Void) {
        _value = value
        self.theme = theme
        self.buttonSize = buttonSize; self.spacing = spacing; self.valueSize = valueSize
        self.onStep = onStep
    }

    public var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                StepButton(title: "−60", unit: TimeText.secondUnit(), size: buttonSize, fill: minusFill, text: minusText) { change(by: -DurationRule.coarseStep) }
                    .accessibilityIdentifier("minus60")
                StepButton(title: "+60", unit: TimeText.secondUnit(), size: buttonSize, fill: plusFill, text: plusText) { change(by: DurationRule.coarseStep) }
                    .accessibilityIdentifier("plus60")
            }

            valueText
                .accessibilityIdentifier("value")

            HStack(spacing: spacing) {
                StepButton(title: "−10", unit: TimeText.secondUnit(), size: buttonSize, fill: minusFill, text: minusText) { change(by: -DurationRule.fineStep) }
                    .accessibilityIdentifier("minus10")
                StepButton(title: "+10", unit: TimeText.secondUnit(), size: buttonSize, fill: plusFill, text: plusText) { change(by: DurationRule.fineStep) }
                    .accessibilityIdentifier("plus10")
            }
        }
    }

    private var plusFill: Color { Color(hex: theme.liquidTop) }
    private var plusText: Color { Color(hex: PaletteHex.ground) }
    private var minusFill: Color { Color(hex: theme.liquidBottom) }
    private var minusText: Color { Color(hex: PaletteHex.ink) }

    /// **大きく秒（`90`）、その下に小さく `1:30`。** 走っている画面と同じ並び。
    /// 数字の行は字の高さぶんに詰める（数字には下に伸びる部分が無い）。そのぶん字を大きくできる
    private var valueText: some View {
        VStack(spacing: 0) {
            Text("\(value)")
                .font(.system(size: valueSize, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color(hex: PaletteHex.ink))
                .contentTransition(.numericText())
                .frame(height: valueSize * 0.92)
            Text(TimeText.clock(Double(value)))
                .font(.system(size: valueSize * 0.3, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.65))
        }
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
    /// `s` だけ。訳す必要がないので素の文字で持つ
    let unit: String
    let size: CGSize
    let fill: Color
    let text: Color
    let step: () -> Void

    @State private var holding: Task<Void, Never>?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(title)
                .font(.system(size: size.height * 0.48, weight: .heavy, design: .rounded))
            Text(unit)
                .font(.system(size: size.height * 0.3, weight: .semibold))
                .foregroundStyle(text.opacity(0.7))
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(text)
        .frame(width: size.width, height: size.height)
        .background(RoundedRectangle(cornerRadius: size.height * 0.34, style: .continuous).fill(fill))
        // 押している間は少し明るく。押せていることが指の下でも分かる
        .brightness(holding == nil ? 0 : 0.15)
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
    /// ♡（投げ銭）。渡さなければ出さない
    public var onTip: (() -> Void)?

    public init(theme: ThemeHex, number: Int, height: CGFloat, spacing: CGFloat,
                onColor: @escaping () -> Void, onDone: @escaping () -> Void,
                onTip: (() -> Void)? = nil) {
        self.theme = theme; self.number = number; self.height = height; self.spacing = spacing
        self.onColor = onColor; self.onDone = onDone; self.onTip = onTip
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

            // **♡ は色の丸と同じ大きさで右端に。** 「完了」を真ん中に挟んで左右が釣り合う。
            // 塗らずに輪郭だけにしてあるのは、押してほしいのは「完了」だから
            if let onTip {
                Button(action: onTip) {
                    ZStack {
                        Circle().stroke(Color(hex: theme.liquidTop).opacity(0.75), lineWidth: max(1.5, height * 0.045))
                        Image(systemName: "heart.fill")
                            .font(.system(size: height * 0.38, weight: .semibold))
                            .foregroundStyle(Color(hex: theme.liquidTop))
                    }
                    .frame(width: height, height: height)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("気に入ったら", bundle: .module))
                .accessibilityIdentifier("tip")
            }
        }
    }
}
