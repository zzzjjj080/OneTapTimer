import Testing
import Foundation
@testable import OneTapTimerCore

/// 見た目の番号は、本人が見本表を見て指すためのもの。
/// **番号を振り直したらここも直す**（黙って中身が入れ替わると、指した番号と実物がずれる）。
struct FaceDesignTests {
    @Test("番号は 1 から連番で、抜けが無い")
    func numbersAreContiguous() {
        func check<T: NumberedChoice>(_ t: T.Type, _ head: String) {
            let codes = T.allCases.map(\.code)
            #expect(codes == (1...codes.count).map { "\(head)\($0)" }, "\(head) が連番でない: \(codes)")
        }
        // アプリの画面
        check(FaceStyle.self, "Y"); check(FaceColor.self, "C"); check(FaceDigits.self, "N")
        check(FaceSize.self, "S"); check(FaceTypeface.self, "T"); check(FaceWeight.self, "F")
        check(FaceOutline.self, "O"); check(FacePlace.self, "P")
        // 文字盤（コンプリケーション）
        check(DialContent.self, "W"); check(DialMark.self, "I"); check(DialRing.self, "R")
        check(DialTint.self, "V"); check(DialSize.self, "U"); check(DialTypeface.self, "J")
    }

    @Test("既定は 1.1 までと同じ見た目（水が減る・ティール・秒＋時計）")
    func standardKeepsTheOldLook() {
        let d = FaceDesign.standard
        #expect(d.style == .liquid)
        #expect(d.color == .teal)
        #expect(d.digits == .secondsWithClock)
        #expect(d.dialContent == .markAndNumber)
        #expect(d.text == "Y1 C1 N1 S3 T1 F3 O1 P1 W1 I1 R1 V1 U2 J1")
    }

    @Test("1行にして戻すと同じものになる")
    func roundTripsThroughText() {
        let d = FaceDesign(style: .ring, color: .pink, digits: .clockOnly, size: .small,
                           typeface: .serif, weight: .light, outline: .stroke, place: .bottom,
                           dialContent: .numberOnly, dialMark: .hourglass, dialRing: .dotted,
                           dialTint: .filled, dialSize: .large, dialTypeface: .monospaced)
        #expect(FaceDesign(text: d.text) == d)
    }

    @Test("知らない番号は、その項目だけ既定に落ちる。ほかは残る")
    func unknownCodesFallBackPerItem() {
        // G3（塗り方）は 1.3 で消した種類。読み飛ばされるだけで、ほかは効く
        let d = FaceDesign(text: "Y2 C99 G3 W3")
        #expect(d.style == .ring)               // 読めたものは効く
        #expect(d.color == .teal)               // 消えた番号は既定
        #expect(d.dialContent == .numberAndUnit)
        #expect(d.digits == .secondsWithClock)  // 書いていない項目も既定
    }

    @Test("保存は1行の文字。項目を足しても古い保存が壊れない")
    func codesAsOneLine() throws {
        let d = FaceDesign(color: .green)
        let data = try JSONEncoder().encode(d)
        #expect(String(data: data, encoding: .utf8)?.contains("C9") == true)
        #expect(try JSONDecoder().decode(FaceDesign.self, from: data) == d)
        // 知らない番号が混じった古い保存
        let old = try JSONDecoder().decode(FaceDesign.self, from: Data(#""Y1 C3 Z9""#.utf8))
        #expect(old.color == .indigo)
    }

    @Test("色の番号は ThemeHex の並びと同じ")
    func colorsMatchThemes() {
        #expect(FaceColor.allCases.count == ThemeHex.all.count)
        for c in FaceColor.allCases {
            #expect(c.theme.name == ThemeHex.all[c.number - 1].name)
        }
    }
}
