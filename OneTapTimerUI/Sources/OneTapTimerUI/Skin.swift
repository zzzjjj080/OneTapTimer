import SwiftUI
import OneTapTimerCore

/// 画面の色。**状態（走っている／終わりが近い／一時停止／終わった）× 見た目ひと組**で決まる。
///
/// 個々の場所で `if isDone { ... }` と書き分けると必ず抜けが出るので、
/// 状態ごとに「地・水・数字・弱い文字」を組で持たせる。
///
/// **1.3 で選べる項目を減らした**（2026-09-27 本人決定）。
/// 地は黒・水は上下グラデ・文字は白・終わりが近いと琥珀・終わったら白く抜ける、で固定。
public struct Skin: Sendable, Equatable {
    public enum State: Sendable { case running, finalStretch, paused, done }

    public var state: State
    public var design: FaceDesign
    public var theme: ThemeHex { design.theme }

    public init(state: State, design: FaceDesign) {
        self.state = state; self.design = design
    }

    /// **止めたときは `.done` にしない。** クラウンで出ていく瞬間に画面が白く光ってしまう。
    /// 止めた画面は「満タンで待っている」見た目にして、次に開いたときと地続きにする。
    public static func of(_ engine: TimerEngine, at now: Date, design: FaceDesign) -> Skin {
        if engine.isFinished && !engine.isCancelled { return Skin(state: .done, design: design) }
        if engine.isPaused { return Skin(state: .paused, design: design) }
        return Skin(state: engine.isFinalStretch(at: now) ? .finalStretch : .running, design: design)
    }

    public var isDone: Bool { state == .done }
    public var isPaused: Bool { state == .paused }

    // MARK: - 地

    /// 地の色（数値）。読みやすさの判定にも使うので、`Color` より先にこちらを決める
    public var groundHex: UInt32 { isDone ? theme.doneGround : PaletteHex.ground }

    public var ground: Color { Color(hex: groundHex) }

    // MARK: - 水（輪・棒も同じ色を使う）

    /// 水の上端。終わりが近いと琥珀（色の組によっては寒色）に変わる
    public var liquidTopHex: UInt32 {
        if isPaused { return PaletteHex.pausedTop }
        return state == .finalStretch ? theme.lastTop : theme.liquidTop
    }

    public var liquidBottomHex: UInt32 {
        if isPaused { return PaletteHex.pausedBottom }
        return state == .finalStretch ? theme.lastBottom : theme.liquidBottom
    }

    public var liquidTop: Color { Color(hex: liquidTopHex) }
    public var liquidBottom: Color { Color(hex: liquidBottomHex) }

    // MARK: - 文字

    /// 文字の色。終わった画面は明るいので、そこだけ濃い文字にする
    public var inkHex: UInt32 { isDone ? theme.doneInk : PaletteHex.ink }

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
