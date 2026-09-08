import Testing
@testable import OneTapTimerCore

struct PaletteTests {

    @Test func 数字は水の上でも読める() {
        // 巨大な太字なので「大きい文字」の目安 3.0 で見る
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.liquidBottom) >= 3.0)
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.lastBottom) >= 3.0)
        #expect(PaletteHex.contrast(PaletteHex.ink, PaletteHex.ground) >= 4.5)
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
