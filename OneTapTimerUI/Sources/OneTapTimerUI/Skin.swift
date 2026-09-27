import SwiftUI
import OneTapTimerCore

/// 画面の色。**状態（走っている／終わりが近い／一時停止／終わった）× 見た目ひと組**で決まる。
///
/// 個々の場所で `if isDone { ... }` と書き分けると必ず抜けが出るので、
/// 状態ごとに「地・水・数字・弱い文字」を組で持たせる。
///
/// **読めない組み合わせは作らせない。** 地が明るいのに白い文字、のような選び方をされたら、
/// ここでコントラストを見て濃い文字に落とす（選択肢そのものは残す。4.5 を下回らないようにする）。
public struct Skin: Sendable, Equatable {
    public enum State: Sendable { case running, finalStretch, paused, done }

    public var state: State
    public var design: FaceDesign
    /// 点滅（L4）のための「いま光っているか」。時刻から決めて渡す
    public var blinkOn: Bool

    public var theme: ThemeHex { design.theme }

    public init(state: State, design: FaceDesign, blinkOn: Bool = true) {
        self.state = state; self.design = design; self.blinkOn = blinkOn
    }

    /// **止めたときは `.done` にしない。** クラウンで出ていく瞬間に画面が白く光ってしまう。
    /// 止めた画面は「満タンで待っている」見た目にして、次に開いたときと地続きにする。
    public static func of(_ engine: TimerEngine, at now: Date, design: FaceDesign) -> Skin {
        let blink = Int(now.timeIntervalSinceReferenceDate * 2) % 2 == 0
        if engine.isFinished && !engine.isCancelled { return Skin(state: .done, design: design) }
        if engine.isPaused { return Skin(state: .paused, design: design, blinkOn: blink) }
        return Skin(state: engine.isFinalStretch(at: now) ? .finalStretch : .running,
                    design: design, blinkOn: blink)
    }

    public var isDone: Bool { state == .done }
    public var isPaused: Bool { state == .paused }

    // MARK: - 地

    /// 地の色（数値）。読みやすさの判定にも使うので、`Color` より先にこちらを決める
    public var groundHex: UInt32 {
        if isDone {
            switch design.done {
            case .bright: return theme.doneGround
            case .dark: return PaletteHex.ground
            case .filled: return theme.liquidBottom
            }
        }
        switch design.ground {
        case .black: return PaletteHex.ground
        case .charcoal: return 0x1C1C1E
        case .deepColor: return PaletteHex.mix(theme.liquidBottom, 0x000000, 0.62)
        case .white: return 0xF2F2F5
        }
    }

    public var ground: Color { Color(hex: groundHex) }

    // MARK: - 水（輪・棒も同じ色を使う）

    /// 水の上端。終わりが近いときの見せ方（L）はここで効かせる
    public var liquidTopHex: UInt32 {
        if isPaused { return PaletteHex.pausedTop }
        guard state == .finalStretch else { return theme.liquidTop }
        switch design.last {
        case .amber: return theme.lastTop
        case .same: return theme.liquidTop
        case .red: return 0xF0473F
        case .blink: return blinkOn ? theme.liquidTop : PaletteHex.mix(theme.liquidTop, groundHex, 0.75)
        }
    }

    public var liquidBottomHex: UInt32 {
        if isPaused { return PaletteHex.pausedBottom }
        guard state == .finalStretch else { return theme.liquidBottom }
        switch design.last {
        case .amber: return theme.lastBottom
        case .same: return theme.liquidBottom
        case .red: return 0xB31B15
        case .blink: return blinkOn ? theme.liquidBottom : PaletteHex.mix(theme.liquidBottom, groundHex, 0.75)
        }
    }

    public var liquidTop: Color { Color(hex: liquidTopHex) }
    public var liquidBottom: Color { Color(hex: liquidBottomHex) }

    /// 塗り方（G）。進み具合で濃さを変えるものがあるので、割合を受け取る
    public func liquidGradient(fraction: Double) -> LinearGradient {
        let colors: [Color]
        switch design.fill {
        case .gradient: colors = [liquidTop, liquidBottom]
        case .solid: colors = [liquidTop, liquidTop]
        case .deepening:
            // 残りが少ないほど濃く。終わりに向かって沈んでいく感じにする
            let t = 1 - max(0, min(1, fraction))
            let top = PaletteHex.mix(liquidTopHex, liquidBottomHex, t)
            colors = [Color(hex: top), liquidBottom]
        }
        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - 文字

    /// 選ばれた文字の色（数値）。**地に対して薄すぎるときは濃い文字に落とす**
    public var inkHex: UInt32 {
        let picked: UInt32 = {
            if isDone && design.done == .bright { return theme.doneInk }
            switch design.ink {
            case .white: return PaletteHex.ink
            case .dim: return PaletteHex.mix(PaletteHex.ink, groundHex, 0.28)
            case .black: return 0x101014
            case .cream: return 0xF3E5C4
            case .colored: return theme.liquidTop
            }
        }()
        if PaletteHex.contrast(picked, groundHex) >= 3.0 { return picked }
        // 読めないときだけ、明るい地なら濃い文字・暗い地なら白い文字へ
        return PaletteHex.luminance(groundHex) > 0.4 ? theme.doneInk : PaletteHex.ink
    }

    public var ink: Color { Color(hex: inkHex) }

    /// 添えの小さい文字
    public var inkDim: Color {
        Color(hex: PaletteHex.mix(inkHex, groundHex, 0.3))
    }

    /// ボタンなどの強調色。色の組の明るいほう
    public var accent: Color { Color(hex: theme.liquidTop) }

    /// 設定への入口の丸。地に溶ける薄いガラス
    private var onLightGround: Bool { PaletteHex.luminance(groundHex) > 0.4 }

    public var glass: Color {
        onLightGround ? Color(hex: theme.doneInk).opacity(0.08) : .white.opacity(0.14)
    }

    public var glassEdge: Color {
        onLightGround ? Color(hex: theme.doneInk).opacity(0.14) : .white.opacity(0.18)
    }

    public var glassInk: Color {
        onLightGround ? Color(hex: theme.doneInkDim) : .white.opacity(0.8)
    }
}

extension Color {
    public init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// 設定画面の押せるもの（色の組に関わらず同じ）
    public static let well = Color(hex: PaletteHex.well)
}
