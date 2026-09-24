import Testing
import Foundation
@testable import OneTapTimerUI

/// 投げ銭のうち、**StoreKit を呼ばずに確かめられるところ**だけ。
/// 購入そのもの（金額の表示・購入・承認待ち）は実機か Sandbox でしか通らない。
@MainActor
struct TipJarTests {
    private func freshDefaults(_ name: String) -> UserDefaults {
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test("杯数は端末の中から読む。消耗型は復元されないので、端末ごとの数になる")
    func cupsComeFromThisDevice() {
        let d = freshDefaults("tipjar.test.cups")
        #expect(TipJar(productID: "x", defaults: d).cups == 0)

        d.set(3, forKey: "tipjar.cups")
        #expect(TipJar(productID: "x", defaults: d).cups == 3)
    }

    @Test("お礼を閉じると元に戻る。もう一度送れる")
    func thanksGoesBackToIdle() {
        let jar = TipJar(productID: "x", defaults: freshDefaults("tipjar.test.state"))
        #expect(jar.state == .idle)
        jar.dismissThanks()
        #expect(jar.state == .idle)
    }

    @Test("製品IDは App Store Connect に作ったものと同じ")
    func productIDMatchesStore() {
        #expect(TipJar.oneTapTimer == "com.zzzjjj080.OneTapTimer.coffee")
    }
}
