import AppKit
import CoreGraphics
import Foundation

// ワンタップタイマーのアプリアイコン。
//
// アプリの画面そのもの：濃い地に、下から溜まったティールの水と、白い水面。
// watchOS では円に切り抜かれ、ホーム画面では 40px まで縮む。細い線も文字も残らないので、
// 面の色と1本の水面だけで作る。iOS 側は透過を持てないので、地を必ず塗る（引き継ぎ書 4-94）。

let S: CGFloat = 1024

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: a)
}
func newContext(_ w: Int, _ h: Int) -> CGContext {
    guard let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fatalError("context") }
    return c
}
func savePNG(_ image: CGImage, _ path: String) {
    let rep = NSBitmapImageRep(cgImage: image)
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("png") }
    try! data.write(to: URL(fileURLWithPath: path))
}

// アプリの配色（OneTapTimerCore の PaletteHex と同じ値）
let GROUND_TOP: UInt32 = 0x0B2E30
let GROUND_BOTTOM: UInt32 = 0x06191B
let LIQUID_TOP: UInt32 = 0x22B8AE
let LIQUID_BOTTOM: UInt32 = 0x0F8A82

func gradient(_ a: UInt32, _ b: UInt32) -> CGGradient {
    CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
               colors: [color(a), color(b)] as CFArray, locations: [0, 1])!
}

/// `level` は水位（0...1）。CoreGraphics は原点が左下。
func drawIcon(_ ctx: CGContext, size: CGFloat, level: CGFloat) {
    ctx.drawLinearGradient(gradient(GROUND_TOP, GROUND_BOTTOM),
                           start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])
    let h = size * level
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: 0, width: size, height: h))
    ctx.drawLinearGradient(gradient(LIQUID_TOP, LIQUID_BOTTOM),
                           start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()
    // 水面。円に切られても真ん中は残るよう、太めに
    ctx.setFillColor(color(0xFFFFFF, 0.6))
    ctx.fill(CGRect(x: 0, y: h - size * 0.012, width: size, height: size * 0.012))
}

func iconImage(_ size: CGFloat, level: CGFloat) -> CGImage {
    let ctx = newContext(Int(size), Int(size))
    drawIcon(ctx, size: size, level: level)
    return ctx.makeImage()!
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
savePNG(iconImage(S, level: 0.58), "\(out)/AppIcon.png")

// 見比べ用：円に切り抜いた姿と、ホーム画面の実寸(40px)
let cell: CGFloat = 300, small: CGFloat = 40
let sheet = newContext(Int(cell + 40), Int(cell + 120))
sheet.setFillColor(color(0x1C1C1E)); sheet.fill(CGRect(x: 0, y: 0, width: cell + 40, height: cell + 120))
sheet.saveGState()
sheet.addEllipse(in: CGRect(x: 20, y: 100, width: cell, height: cell)); sheet.clip()
sheet.draw(iconImage(cell, level: 0.58), in: CGRect(x: 20, y: 100, width: cell, height: cell))
sheet.restoreGState()
sheet.saveGState()
sheet.addEllipse(in: CGRect(x: 20 + cell/2 - small/2, y: 30, width: small, height: small)); sheet.clip()
sheet.draw(iconImage(small, level: 0.58), in: CGRect(x: 20 + cell/2 - small/2, y: 30, width: small, height: small))
sheet.restoreGState()
savePNG(sheet.makeImage()!, "\(out)/icon-sheet.png")
print("書き出しました: \(out)")
