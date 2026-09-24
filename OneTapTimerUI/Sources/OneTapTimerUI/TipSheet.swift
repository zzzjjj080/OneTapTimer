import SwiftUI
import OneTapTimerCore

/// 投げ銭（コーヒーを奢る）の画面。**設定のいちばん下の ♡ から開く。**
///
/// Watch の画面は狭いので、**金額は1つだけ**（App Store が返す表示価格をそのまま出す。
/// 国によって通貨も額も変わるので、アプリ側で「¥200」と決め打ちしない）。
/// 送っても機能は変わらない。消耗型なので何度でも送れる。
///
/// 「寄付」「Donation」とは書かない（慈善団体への寄付は Apple の扱いが別）。
public struct TipSheet: View {
    @Bindable private var tipJar: TipJar
    private let theme: ThemeHex
    private let onClose: () -> Void

    public init(tipJar: TipJar, theme: ThemeHex, onClose: @escaping () -> Void) {
        self._tipJar = Bindable(tipJar); self.theme = theme; self.onClose = onClose
    }

    private var fill: LinearGradient {
        LinearGradient(colors: [Color(hex: theme.liquidTop), Color(hex: theme.liquidBottom)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// 撮影・確認用の見本。**DEBUG 構成にしか無い**（`OTT_TIP_SAMPLE=¥200`）。
    /// App Store Connect 側に製品を作る前でも、画面の形を確かめられる
    private var samplePrice: String? {
        #if DEBUG
        ProcessInfo.processInfo.environment["OTT_TIP_SAMPLE"]
        #else
        nil
        #endif
    }

    public var body: some View {
        ZStack {
            Color(hex: PaletteHex.ground).ignoresSafeArea()
            VStack(spacing: 10) {
                switch tipJar.state {
                case .thanks:
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(hex: theme.liquidTop))
                    Text("ありがとうございます", bundle: .module)
                        .font(.system(size: 15, weight: .semibold))
                        .multilineTextAlignment(.center)
                    close
                case .failed:
                    Text("うまくいきませんでした", bundle: .module)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.7))
                        .multilineTextAlignment(.center)
                    close
                case .unavailable where samplePrice == nil:
                    Text("いまは受け付けられません", bundle: .module)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.7))
                        .multilineTextAlignment(.center)
                    close
                case .loading, .purchasing:
                    ProgressView().tint(Color(hex: theme.liquidTop))
                default:
                    offer
                }
            }
            .padding(.horizontal, 12)
        }
        // 右から左の言語では、システムが出す閉じる「×」が右上へ回ってシステム時刻に少し重なる。
        // これはシート自体の作りで、layoutDirection を固定しても動かない（純正アプリでも同じ）
        .task { await tipJar.load() }
        // 買えた瞬間だけ鳴らす（承認待ちが後から通ったときもここを通る）
        .sensoryFeedback(.success, trigger: tipJar.cups)
    }

    private var offer: some View {
        VStack(spacing: 10) {
            Text("気に入ったら", bundle: .module)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.8))
                .multilineTextAlignment(.center)

            Button {
                Task { await tipJar.tip() }
            } label: {
                VStack(spacing: 1) {
                    Text("コーヒーを奢る", bundle: .module)
                        .font(.system(size: 15, weight: .bold))
                    if let price = tipJar.displayPrice ?? samplePrice {
                        Text(price)
                            .font(.system(size: 12, weight: .semibold))
                            .monospacedDigit()
                            .opacity(0.8)
                    }
                }
                .foregroundStyle(Color(hex: PaletteHex.ground))
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(Capsule().fill(fill))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("tipBuy")

            if tipJar.cups > 0 {
                // 消耗型は復元されない。**この端末での回数**だとはっきり書く
                Text("この端末で \(tipJar.cups)", bundle: .module)
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(Color(hex: PaletteHex.ink).opacity(0.4))
            }
        }
    }

    private var close: some View {
        Button(action: {
            tipJar.dismissThanks()
            onClose()
        }) {
            Text("閉じる", bundle: .module)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: theme.liquidTop))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tipClose")
    }
}
