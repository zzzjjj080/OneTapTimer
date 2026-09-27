import Foundation
import SwiftUI
import Testing
import OneTapTimerCore
@testable import OneTapTimerUI

/// 常時表示では watchOS が先の時刻の絵を先回りして描く。
/// エンジンがまだ終わっていないのに、描く時刻だけが終了時刻を越えることがある。
/// 実機で 90秒のタイマーが30秒ほどで落ちていた（DrainFace.swift の `now...endAt` が逆向き）。
@MainActor
struct DrainFaceTests {
    let t0 = Date(timeIntervalSince1970: 5_000_000)

    @Test func 常時表示で終了時刻を過ぎた時刻を描いても落ちない() {
        let engine = TimerEngine(duration: 90, startedAt: t0)   // まだ終わっていない
        #expect(!engine.isFinished)
        for later in [30.0, 89.0, 90.0, 90.5, 120.0, 600.0] {
            let face = DrainFace(engine: engine, now: t0 + later, design: FaceDesign.standard,
                                 metrics: .watch)
            _ = face.body
        }
    }

    @Test func 見ている画面でも終了時刻を過ぎた時刻を描いても落ちない() {
        let engine = TimerEngine(duration: 10, startedAt: t0)
        for later in [0.0, 9.9, 10.0, 11.0] {
            _ = DrainFace(engine: engine, now: t0 + later, design: FaceDesign(color: .blue),
                          metrics: .watch).body
        }
    }

    @Test("どの見た目の組み合わせでも描ける（形・向き・数字・置き場所）")
    func everyDesignDraws() {
        let engine = TimerEngine(duration: 90, startedAt: t0)
        for style in FaceStyle.allCases {
            for direction in FaceDirection.allCases {
                for digits in FaceDigits.allCases {
                    for place in FacePlace.allCases {
                        let d = FaceDesign(style: style, direction: direction, digits: digits, place: place)
                        _ = DrainFace(engine: engine, now: t0 + 45, design: d, metrics: .watch).body
                    }
                }
            }
        }
    }

    @Test("地が明るいときに白い文字を選んでも、読める濃さに落ちる")
    func inkStaysReadable() {
        for ink in FaceInk.allCases {
            let design = FaceDesign(ground: .white, ink: ink)
            let skin = Skin(state: .running, design: design)
            #expect(PaletteHex.contrast(skin.inkHex, skin.groundHex) >= 3.0, "\(ink.code) が読めない")
        }
        // 終わった画面（白く抜ける）でも同じ
        for ink in FaceInk.allCases {
            let skin = Skin(state: .done, design: FaceDesign(ink: ink))
            #expect(PaletteHex.contrast(skin.inkHex, skin.groundHex) >= 3.0, "\(ink.code) が読めない")
        }
    }
}
