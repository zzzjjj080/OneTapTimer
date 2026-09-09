import Testing
@testable import OneTapTimerCore

struct PaletteTests {

    @Test func 数字は水の上でも読める() {
        // 巨大な太字なので「大きい文字」の目安 3.0 で見る
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.liquidBottom) >= 3.0)
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.lastBottom) >= 3.0)
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.ground) >= 4.5)
    }

    @Test func 十色すべてで数字と終わりの文字が読める() {
        #expect(ThemeHex.all.count == 10)
        for t in ThemeHex.all {
            #expect(PaletteHex.contrast(PaletteHex.ink, t.liquidBottom) >= 3.0, "\(t.name) の水")
            #expect(PaletteHex.contrast(PaletteHex.ink, t.lastBottom) >= 3.0, "\(t.name) の終わり際")
            #expect(PaletteHex.contrast(t.doneInk, t.doneGround) >= 4.5, "\(t.name) の終わった画面")
            #expect(PaletteHex.contrast(t.doneInkDim, t.doneGround) >= 4.5, "\(t.name) の弱い文字")
            #expect(PaletteHex.contrast(PaletteHex.ground, t.liquidTop) >= 4.5, "\(t.name) のボタン（黒い文字）")
        }
        #expect(ThemeHex.next(after: 10) == 1)
        #expect(ThemeHex.next(after: 3) == 4)
        #expect(ThemeHex.at(99) == ThemeHex.all[0])
    }

    @Test func 終わった画面は本文の基準で読める() {
        #expect(PaletteHex.contrast(PaletteHex.doneInk, PaletteHex.doneGround) >= 4.5)
        #expect(PaletteHex.contrast(PaletteHex.doneInkDim, PaletteHex.doneGround) >= 4.5)
    }

    @Test func 設定の文字は地の上で読める() {
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.well) >= 4.5)
        #expect(PaletteHex.contrast(PaletteHex.ground, PaletteHex.accent) >= 4.5)  // 黒い文字を載せる
    }
}
