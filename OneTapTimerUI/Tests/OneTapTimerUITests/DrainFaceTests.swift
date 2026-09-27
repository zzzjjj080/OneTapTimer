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

    @Test("どの見た目の組み合わせでも描ける（形・数字・大きさ・置き場所）")
    func everyDesignDraws() {
        let engine = TimerEngine(duration: 90, startedAt: t0)
        for style in FaceStyle.allCases {
            for digits in FaceDigits.allCases {
                for size in FaceSize.allCases {
                    for place in FacePlace.allCases {
                        let d = FaceDesign(style: style, digits: digits, size: size, place: place)
                        _ = DrainFace(engine: engine, now: t0 + 45, design: d, metrics: .watch).body
                    }
                }
            }
        }
    }

    @Test("どの色でも、走っている画面と終わった画面の文字が読める")
    func inkStaysReadable() {
        for color in FaceColor.allCases {
            for state in [Skin.State.running, .finalStretch, .paused, .done] {
                let skin = Skin(state: state, design: FaceDesign(color: color))
                #expect(PaletteHex.contrast(skin.inkHex, skin.groundHex) >= 4.5,
                        "\(color.code) の \(state) が読めない")
            }
        }
    }

    @Test("文字盤の丸は、どの組み合わせでも描ける")
    func everyDialDraws() {
        for content in DialContent.allCases {
            for ring in DialRing.allCases {
                for tint in DialTint.allCases {
                    let d = FaceDesign(dialContent: content, dialRing: ring, dialTint: tint)
                    _ = DialFace(design: d, duration: 90, diameter: 46).body
                    _ = DialFace(design: d, duration: 90, diameter: 46, fullColor: false).body
                }
            }
        }
    }
}
