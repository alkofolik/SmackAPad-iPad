// Design-only vector renderer. Run from the repository root with:
// swift docs/design/2026-11-03-icon-and-launch/render-icons.swift
import AppKit
import CoreText

let output = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let fontURL = root.appendingPathComponent("SmackAPad/Resources/Fonts/IBMPlexSans[wdth,wght].ttf")
let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as! [CTFontDescriptor]
let descriptor = CTFontDescriptorCreateCopyWithAttributes(descriptors[0], [kCTFontVariationAttribute: [2003265652: 700, 2003072104: 100]] as CFDictionary)
let font = CTFontCreateWithFontDescriptor(descriptor, 160, nil)
precondition((CTFontCopyFamilyName(font) as String) == "IBM Plex Sans")

struct Shape { let path: CGPath; let color: String }
typealias Art = [Shape]
let orange = "FF6B00", black = "000000", white = "FFFFFF"
func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: String, _ radius: CGFloat = 0) -> Shape {
    Shape(path: CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: radius, cornerHeight: radius, transform: nil), color: color)
}
func label(_ text: String, _ rect: CGRect, _ size: CGFloat, _ color: String) -> Shape {
    let face = CTFontCreateCopyWithAttributes(font, size, nil, nil)
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: face]))
    let combined = CGMutablePath()
    for run in CTLineGetGlyphRuns(line) as! [CTRun] {
        let n = CTRunGetGlyphCount(run)
        var glyphs = [CGGlyph](repeating: 0, count: n), points = [CGPoint](repeating: .zero, count: n)
        CTRunGetGlyphs(run, CFRange(), &glyphs); CTRunGetPositions(run, CFRange(), &points)
        for i in 0..<n {
            if let p = CTFontCreatePathForGlyph(face, glyphs[i], nil) {
                combined.addPath(p, transform: CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: points[i].x, ty: -points[i].y))
            }
        }
    }
    let bounds = combined.boundingBoxOfPath
    precondition(bounds.width <= rect.width && bounds.height <= rect.height, "Text must fit: \(text)")
    var move = CGAffineTransform(translationX: rect.midX - bounds.midX, y: rect.midY - bounds.midY)
    return Shape(path: combined.copy(using: &move)!, color: color)
}
func tile(_ text: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ size: CGFloat) -> Art {
    [box(x, y, w, h, white, 22), label(text, CGRect(x: x, y: y, width: w, height: h), size, black)]
}
func marker(_ x: CGFloat, _ top: CGFloat, _ height: CGFloat) -> Art {
    let p = CGMutablePath(); p.move(to: CGPoint(x: x - 34, y: top)); p.addLine(to: CGPoint(x: x + 34, y: top)); p.addLine(to: CGPoint(x: x, y: top + 40)); p.closeSubpath()
    return [box(x - 23, top + 36, 46, height - 36, white), box(x - 9, top + 36, 18, height - 36, black), Shape(path: p, color: black)]
}
var stack: Art = [box(0, 0, 1024, 1024, orange)]
for (i, text) in ["HH", "SN", "KD"].enumerated() {
    let y = CGFloat(172 + i * 236)
    stack += tile(text, 188, y, 356, 200, 170)
    stack += [box(744, y + 32, 92, 136, black, 12)]
}
stack += marker(640, 104, 816)

var tape: Art = [box(0, 0, 1024, 1024, black), box(0, 248, 1024, 528, orange)]
tape += [box(0, 344, 124, 336, white, 22)]
tape += tile("HH", 240, 344, 544, 336, 248)
tape += [box(900, 344, 124, 336, white, 22)]
tape += marker(170, 284, 456)

var together: Art = [box(0, 0, 1024, 1024, white), box(112, 112, 800, 800, orange)]
together += tile("HH", 216, 208, 432, 272, 208)
together += tile("KD", 216, 544, 432, 272, 208)
together += marker(744, 160, 704)

let concepts: [(String, String, Art)] = [("a-stack", "A / Pad stack", stack), ("b-tape", "B / Hit tape", tape), ("c-together", "C / Together", together)]
func pathString(_ path: CGPath) -> String {
    var result = ""
    func p(_ point: CGPoint) -> String { String(format: "%.3f %.3f", Double(point.x), Double(point.y)) }
    path.applyWithBlock { pointer in
        let e = pointer.pointee
        switch e.type {
        case .moveToPoint: result += "M\(p(e.points[0]))"
        case .addLineToPoint: result += "L\(p(e.points[0]))"
        case .addQuadCurveToPoint: result += "Q\(p(e.points[0])) \(p(e.points[1]))"
        case .addCurveToPoint: result += "C\(p(e.points[0])) \(p(e.points[1])) \(p(e.points[2]))"
        case .closeSubpath: result += "Z"
        @unknown default: fatalError("Unknown path element")
        }
    }
    return result
}
func paint(_ art: Art, in context: CGContext, x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1) {
    context.saveGState(); context.translateBy(x: x, y: y); context.scaleBy(x: scale, y: scale)
    for shape in art {
        let value = UInt32(shape.color, radix: 16)!
        context.setFillColor(CGColor(srgbRed: CGFloat((value >> 16) & 255)/255, green: CGFloat((value >> 8) & 255)/255, blue: CGFloat(value & 255)/255, alpha: 1))
        context.addPath(shape.path); context.fillPath()
    }
    context.restoreGState()
}
func png(_ name: String, width: Int, height: Int, draw: (CGContext) -> Void) throws {
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.translateBy(x: 0, y: CGFloat(height)); context.scaleBy(x: 1, y: -1)
    draw(context)
    let image = context.makeImage()!
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try data.write(to: output.appendingPathComponent(name))
}
for (id, title, art) in concepts {
    let body = art.map { "<path fill=\"#\($0.color)\" d=\"\(pathString($0.path))\"/>" }.joined(separator: "\n")
    let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1024\" height=\"1024\" viewBox=\"0 0 1024 1024\" role=\"img\" aria-label=\"\(title)\"><title>\(title)</title>\n\(body)\n</svg>\n"
    try svg.write(to: output.appendingPathComponent("\(id).svg"), atomically: true, encoding: .utf8)
    try png("\(id).png", width: 1024, height: 1024) { paint(art, in: $0) }
}
try png("overview.png", width: 3456, height: 3000) { ctx in
    for (row, background) in [white, black].enumerated() {
        let ink = row == 0 ? black : white
        let y = CGFloat(row * 1500)
        paint([box(0, y, 3456, 1500, background)], in: ctx)
        for (column, entry) in concepts.enumerated() {
            let x = CGFloat(column * 1152 + 64)
            paint([label(entry.1, CGRect(x: x, y: y + 28, width: 1024, height: 64), 42, ink)], in: ctx)
            paint(entry.2, in: ctx, x: x, y: y + 124)
            paint([label("1024 px · \(row == 0 ? "Light" : "Dark") home screen", CGRect(x: x, y: y + 1164, width: 1024, height: 50), 28, ink)], in: ctx)
            for (j, size) in [180, 120, 60].enumerated() {
                let smallX = x + CGFloat(j * 300)
                paint(entry.2, in: ctx, x: smallX, y: y + 1240, scale: CGFloat(size)/1024)
                paint([label("\(size) px", CGRect(x: smallX, y: y + 1436, width: 180, height: 40), 26, ink)], in: ctx)
            }
        }
    }
}
print("Rendered three opaque 1024px PNGs, outlined SVGs, and overview.png.")
