// Design-only renderer. This file is not part of the application target.
// Run from the repository root: swift docs/design/2026-11-02-typography/render-previews.swift
import AppKit
import CoreText

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("docs/design/2026-11-02-typography")
let output = root.appendingPathComponent("previews")
let files = ["IBMPlexSans[wdth,wght].ttf", "AtkinsonHyperlegibleNext[wght].ttf"]
for file in files {
    var error: Unmanaged<CFError>?
    precondition(CTFontManagerRegisterFontsForURL(root.appendingPathComponent("fonts/" + file) as CFURL,
                                              .process, &error), "Cannot register \(file): \(String(describing: error))")
}

let wght = NSNumber(value: UInt32(0x77676874))
let wdth = NSNumber(value: UInt32(0x77647468))
enum Face: String, CaseIterable {
    case sf = "a-sf-rounded", plex = "b-ibm-plex-sans", atkinson = "c-atkinson-next"
    var title: String {
        switch self {
        case .sf: return "A · SF Pro Rounded"
        case .plex: return "B · IBM Plex Sans"
        case .atkinson: return "C · Atkinson Hyperlegible Next"
        }
    }
    func font(_ size: CGFloat, _ bold: Bool = false, _ tabular: Bool = false) -> NSFont {
        var descriptor: NSFontDescriptor
        switch self {
        case .sf:
            descriptor = NSFont.systemFont(ofSize: size, weight: bold ? .bold : .regular)
                .fontDescriptor.withDesign(.rounded)!
        case .plex, .atkinson:
            let name = self == .plex ? "IBMPlexSans-Regular" : "AtkinsonHyperlegibleNext-Regular"
            var variation: [NSNumber: NSNumber] = [wght: NSNumber(value: bold ? 700 : 400)]
            if self == .plex { variation[wdth] = 100 }
            descriptor = NSFontDescriptor(fontAttributes: [.name: name,
                NSFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String): variation])
        }
        if tabular {
            descriptor = descriptor.addingAttributes([.featureSettings: [[
                kCTFontFeatureTypeIdentifierKey as String: kNumberSpacingType,
                kCTFontFeatureSelectorIdentifierKey as String: kMonospacedNumbersSelector
            ]]])
        }
        let result = NSFont(descriptor: descriptor, size: size)!
        if self != .sf {
            precondition(result.familyName == (self == .plex ? "IBM Plex Sans" : "Atkinson Hyperlegible Next"))
        }
        return result
    }
}

func color(_ hex: Int) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let orange = color(0xFF6B00)
struct Palette {
    let dark: Bool
    var bg: NSColor { dark ? .black : .white }
    var ink: NSColor { dark ? .white : .black }
    var secondary: NSColor { color(dark ? 0xB3B3B3 : 0x595959) }
    var surface: NSColor { color(dark ? 0x171717 : 0xF0F0F0) }
    var line: NSColor { color(dark ? 0x373737 : 0xD6D6D6) }
}

var face = Face.sf
var p = Palette(dark: false)
var textChecks = 0
var images: [String: NSImage] = [:]

func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: NSColor, _ radius: CGFloat = 0) {
    c.setFill()
    NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: radius, yRadius: radius).fill()
}
func rule(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ c: NSColor? = nil) { rect(x, y, w, 1, c ?? p.line) }
func lineWidth(_ text: String, _ font: NSFont) -> CGFloat {
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: [.font: font]))
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}
func text(_ s: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat = 22,
          _ bold: Bool = false, _ c: NSColor? = nil, _ width: CGFloat = 1100,
          _ align: NSTextAlignment = .left, _ tabular: Bool = false) {
    let font = face.font(size, bold, tabular)
    let measured = lineWidth(s, font)
    precondition(measured <= width + 0.5, "Text overflow: \(face) \(s), \(measured) > \(width)")
    textChecks += 1
    let style = NSMutableParagraphStyle()
    style.alignment = align
    style.lineBreakMode = .byClipping
    let value = NSAttributedString(string: s, attributes: [.font: font,
        .foregroundColor: c ?? p.ink, .paragraphStyle: style])
    value.draw(in: NSRect(x: x, y: y, width: width, height: size * 1.6))
}
func star(_ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ filled: Bool) {
    let path = NSBezierPath()
    for i in 0..<10 {
        let angle = CGFloat(i) * .pi / 5 - .pi / 2
        let r = size * (i % 2 == 0 ? 0.5 : 0.22)
        let pt = NSPoint(x: x + size/2 + cos(angle)*r, y: y + size/2 + sin(angle)*r)
        if i == 0 { path.move(to: pt) } else { path.line(to: pt) }
    }
    path.close()
    (filled ? orange : p.line).setFill()
    path.fill()
}
func button(_ title: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, primary: Bool = true) {
    rect(x, y, w, 60, primary ? p.ink : p.surface, 3)
    text(title, x + 12, y + 13, 24, true, primary ? p.bg : p.ink, w - 24, .center)
}
func toggle(_ x: CGFloat, _ y: CGFloat, _ on: Bool) {
    rect(x, y, 64, 36, on ? p.ink : p.line, 18)
    rect(x + (on ? 32 : 4), y + 4, 28, 28, on ? p.bg : p.surface, 14)
}
func shell(_ selected: String) {
    rect(0, 0, 1194, 834, p.bg)
    // The repeated pad shape is the product mark, not another font.
    for i in 0..<4 { rect(40 + CGFloat(i % 2)*11, 30 + CGFloat(i/2)*11, 8, 8, i == 0 ? orange : p.ink, 1) }
    text("Smack-a-Pad", 76, 24, 24, true, nil, 270)
    let nav: [(String, CGFloat, CGFloat)] = [("Cvičení", 654, 128), ("Knihovna", 816, 148), ("Nastavení", 1000, 154)]
    for (label, x, w) in nav {
        text(label, x, 27, 22, selected == label, selected == label ? p.ink : p.secondary, w, .center)
        if label == selected { rect(x + 28, 68, w - 56, 3, p.ink) }
    }
    rule(40, 86, 1114)
}

func practice() {
    shell("Cvičení")
    text("Základy / Osminy", 40, 110, 22, false, p.secondary, 750)
    text("Osminový groove", 40, 147, 32, true, nil, 750)
    text("Tempo", 880, 111, 22, false, p.secondary, 274, .right)
    text("112", 915, 139, 56, true, nil, 161, .right, true)
    text("BPM", 1087, 168, 22, false, p.secondary, 67)
    rect(40, 221, 12, 12, orange, 6)
    text("Běží", 64, 211, 24, true, nil, 170)
    text("Takt 3 z 8", 270, 211, 24, false, nil, 500, .left, true)
    text("Pravá a levá ruka", 810, 214, 22, false, p.secondary, 344, .right)
    let cellW: CGFloat = (1114 - 7*8)/8
    for i in 0..<8 {
        let x = 40 + CGFloat(i)*(cellW + 8)
        text(i % 2 == 0 ? "\(i/2+1)" : "&", x, 276, 28, i % 2 == 0,
             i % 2 == 0 ? p.ink : p.secondary, cellW, .center, true)
        for row in 0..<3 {
            let y = 325 + CGFloat(row)*90
            let active = row == 0 || (row == 1 && [2,6].contains(i)) || (row == 2 && [0,4].contains(i))
            let current = i == 4
            rect(x, y, cellW, 76, current && active ? orange : p.surface, 3)
            if active {
                text(["HH", "SN", "KD"][row], x, y + 15, 32, true,
                     current ? .black : p.ink, cellW, .center)
            } else {
                rect(x + cellW/2 - 3, y + 35, 6, 6, p.line, 3)
            }
        }
    }
    rect(40, 617, 1114, 6, p.surface)
    rect(40, 617, 1114*3/8, 6, orange)
    text("Přesně", 40, 654, 28, true, nil, 400)
    text("Drž tempo a pokračuj.", 40, 697, 22, false, p.secondary, 700)
    button("Zastavit", 884, 674, 270)
    text("Hi-hat · Malý buben · Kopák", 40, 779, 20, false, p.secondary, 1114)
}

func result() {
    shell("Cvičení")
    text("Osminový groove", 40, 112, 32, true, nil, 1114)
    rect(150, 184, 894, 588, p.surface)
    rect(150, 184, 894, 142, orange)
    text("Cvičení dokončeno", 186, 208, 32, true, .black, 822)
    text("Cílové tempo získáno", 186, 260, 24, false, .black, 822)
    text("Úspěšnost", 186, 351, 22, false, p.secondary, 350)
    text("94 %", 186, 384, 56, true, nil, 350, .left, true)
    text("Tempo", 680, 351, 22, false, p.secondary, 328)
    text("112 BPM", 680, 399, 32, true, nil, 328, .left, true)
    rule(186, 472, 822)
    let stages = ["Začátek", "Cílové tempo", "Z paměti"]
    for (i, stage) in stages.enumerated() {
        let x = 186 + CGFloat(i)*282
        star(x, 505, 38, i < 2)
        text(stage, x, 558, 24, true, nil, 260)
        text(i < 2 ? "Získáno" : "Ještě před tebou", x, 598, 22, false, p.secondary, 260)
    }
    button("Znovu", 186, 680, 240, primary: false)
    button("Zpět do knihovny", 650, 680, 358)
}

func library() {
    shell("Knihovna")
    text("Knihovna", 40, 112, 32, true, nil, 1114)
    text("Základy", 40, 182, 28, true, nil, 600)
    text("4 z 12 cvičení hotovo", 700, 190, 22, false, p.secondary, 454, .right, true)
    rect(40, 238, 1114, 6, p.surface)
    rect(40, 238, 1114/3, 6, orange)
    let rows = [("Osminový groove", "Hi-hat, malý buben a kopák", "112 BPM", 2),
                ("Střídání rukou", "Plynule pravou a levou rukou", "96 BPM", 1),
                ("Přechody přes čtyři pady", "Přesnost při změně nástroje", "88 BPM", 0)]
    for (i, row) in rows.enumerated() {
        let y = 280 + CGFloat(i)*126
        text(row.0, 40, y, 28, true, nil, 700)
        text(row.1, 40, y + 45, 22, false, p.secondary, 700)
        text(row.2, 850, y, 28, true, nil, 304, .right, true)
        for j in 0..<3 { star(1054 + CGFloat(j)*35, y + 49, 28, j < row.3) }
        rule(40, y + 107, 1114)
    }
    text("Další krok", 40, 692, 22, false, p.secondary, 700)
    text("Čtvrtiny a osminy", 40, 730, 28, true, nil, 700)
    button("Pokračovat", 874, 711, 280)
}

func settings() {
    shell("Nastavení")
    text("Nastavení", 40, 112, 32, true, nil, 1114)
    rect(40, 194, 248, 56, p.surface, 3)
    text("Obecné", 58, 205, 24, true, nil, 212)
    text("Zvuk a MIDI", 58, 282, 24, false, p.secondary, 230)
    text("Přístupnost", 58, 359, 24, false, p.secondary, 230)
    let left: CGFloat = 352
    let right: CGFloat = 1154
    text("Vzhled a jazyk", left, 194, 26, true, nil, 802)
    text("Režim aplikace", left, 258, 24, false, nil, 410)
    text("Podle systému", 800, 258, 24, true, nil, right - 800, .right)
    rule(left, 307, 802)
    text("Jazyk", left, 332, 24, false, nil, 410)
    text("Čeština", 800, 332, 24, true, nil, right - 800, .right)
    rule(left, 381, 802)
    text("Zvuk a MIDI", left, 421, 26, true, nil, 802)
    text("MIDI kontrolér", left, 485, 24, false, nil, 410)
    text("Připojen", 800, 485, 24, true, nil, right - 800, .right)
    rule(left, 534, 802)
    text("Zvuk bicích", left, 560, 24, false, nil, 410)
    toggle(1090, 558, true)
    rule(left, 609, 802)
    text("Přístupnost", left, 649, 26, true, nil, 802)
    text("Omezit pohyb", left, 713, 24, false, nil, 410)
    toggle(1090, 711, false)
    text("Méně animací při přechodu mezi obrazovkami.", left, 758, 20, false, p.secondary, 802)
}

@discardableResult
func canvas(_ width: CGFloat, _ height: CGFloat, _ scale: CGFloat, _ name: String, _ draw: () -> Void) -> NSImage {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width*scale), pixelsHigh: Int(height*scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.translateBy(x: 0, y: height*scale)
    context.cgContext.scaleBy(x: scale, y: -scale)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context.cgContext, flipped: true)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    rep.size = NSSize(width: width, height: height)
    try! rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name + ".png"))
    let image = NSImage(size: rep.size)
    image.addRepresentation(rep)
    images[name] = image
    return image
}

// Coverage is checked in the requested face itself, not merely through system fallback.
let czech = "ěščřžýáíéúůďťňĚŠČŘŽÝÁÍÉÚŮĎŤŇ"
let proof = "Příliš žluťoučký kůň úpěl ďábelské ódy."
var audit: [[String: Any]] = []
let studyOnly = CommandLine.arguments.contains("--sf-study-only")
if studyOnly {
    let previous = try! JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("font-verification.json"))) as! [String: Any]
    audit = (previous["results"] as! [[String: Any]]).filter { $0["sf_design_study"] == nil }
    textChecks = (previous["single_line_fit_checks"] as! Int) - 4
}
if !studyOnly {
for f in Face.allCases {
    for bold in [false, true] {
        let font = f.font(32, bold)
        let ct = font as CTFont
        var chars = Array((czech + "HH SN KD 0123456789").utf16)
        var glyphs = Array(repeating: CGGlyph(0), count: chars.count)
        precondition(CTFontGetGlyphsForCharacters(ct, &chars, &glyphs, chars.count), "Missing glyph in \(f)")
        var fallbackFonts = Set<String>()
        for specimen in [czech, proof, proof.decomposedStringWithCanonicalMapping] {
            let shaped = CTLineCreateWithAttributedString(NSAttributedString(string: specimen, attributes: [.font: font]))
            for run in CTLineGetGlyphRuns(shaped) as! [CTRun] {
                let attributes = CTRunGetAttributes(run) as NSDictionary
                let actual = attributes[kCTFontAttributeName] as! CTFont
                let actualFamily = CTFontCopyFamilyName(actual) as String
                precondition(actualFamily == font.familyName, "Czech fallback: \(f) to \(actualFamily)")
                fallbackFonts.insert(CTFontCopyPostScriptName(actual) as String)
            }
        }
        let numeric = f.font(32, bold, true)
        let widths = (0...9).map { lineWidth(String($0), numeric) }
        precondition(widths.max()! - widths.min()! < 0.01, "Unequal tabular digits in \(f)")
        let proportional = ["i", "m", "W"].map { lineWidth($0, font) }
        precondition(proportional.max()! - proportional.min()! > 2, "Monospace face")
        let variation = (CTFontCopyVariation(ct) as? [NSNumber: NSNumber] ?? [:])
            .reduce(into: [String: NSNumber]()) { $0[$1.key.stringValue] = $1.value }
        audit.append(["variant": f.title, "weight": bold ? 700 : 400,
            "postscript_name": font.fontName, "family": font.familyName!,
            "variation": variation,
            "czech_missing_glyphs": glyphs.filter { $0 == 0 }.count,
            "czech_shaped_run_fonts_nfc_and_nfd": Array(fallbackFonts).sorted(),
            "tabular_digit_advances_at_32pt": widths,
            "proportional_i_m_W_advances_at_32pt": proportional,
            "x_height_at_32pt": CTFontGetXHeight(ct),
            "version": CTFontCopyName(ct, kCTFontVersionNameKey) as String? ?? "system"])
    }
}

let screens: [(String, () -> Void)] = [("practice", practice), ("result", result), ("library", library), ("settings", settings)]
for f in Face.allCases {
    face = f
    for dark in [false, true] {
        p = Palette(dark: dark)
        for (name, draw) in screens {
            canvas(1194, 834, 2, f.rawValue + "-" + name + (dark ? "-dark" : "-light"), draw)
        }
    }
}

// Comparison sheets have the same content at the same scale: columns = family, rows = appearance.
for (screen, _) in screens {
    canvas(1848, 1010, 1, "compare-" + screen) {
        p = Palette(dark: false)
        rect(0, 0, 1848, 1010, color(0xE6E6E6))
        for (i, f) in Face.allCases.enumerated() {
            face = f
            let x = 16 + CGFloat(i)*612
            text(f.title, x, 18, 22, true, .black, 597)
            for (j, mode) in ["light", "dark"].enumerated() {
                text(mode == "light" ? "Světlý režim" : "Tmavý režim", x, 62 + CGFloat(j)*466, 18, false, color(0x595959), 597)
                let image = images[f.rawValue + "-" + screen + "-" + mode]!
                image.draw(in: NSRect(x: x, y: 96 + CGFloat(j)*466, width: 597, height: 417),
                           from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
            }
        }
    }
}

for f in Face.allCases {
    face = f
    canvas(1242, 1932, 1, f.rawValue + "-all-screens") {
        p = Palette(dark: false)
        rect(0, 0, 1242, 1932, color(0xE6E6E6))
        text(f.title + " · Regular / Bold", 16, 18, 26, true, .black, 1210)
        for (i, screen) in screens.enumerated() {
            let y = 64 + CGFloat(i)*466
            let labels = ["Cvičení během běhu", "Výsledkový panel", "Knihovna", "Nastavení"]
            for (j, mode) in ["light", "dark"].enumerated() {
                let x = 16 + CGFloat(j)*613
                text(labels[i] + (j == 0 ? " · Světlý" : " · Tmavý"), x, y, 18, true, .black, 597)
                images[f.rawValue + "-" + screen.0 + "-" + mode]!.draw(
                    in: NSRect(x: x, y: y + 34, width: 597, height: 417), from: .zero,
                    operation: .copy, fraction: 1, respectFlipped: true, hints: nil)
            }
        }
    }
}

canvas(1500, 1490, 1, "czech-and-numerals-proof") {
    rect(0, 0, 1500, 1490, color(0xE6E6E6))
    for (i, f) in Face.allCases.enumerated() {
        face = f
        for (j, dark) in [false, true].enumerated() {
            p = Palette(dark: dark)
            let x: CGFloat = j == 0 ? 16 : 758
            let y = 16 + CGFloat(i)*490
            rect(x, y, 726, 474, p.bg)
            text(f.title, x + 24, y + 18, 24, true, nil, 678)
            text(czech, x + 24, y + 68, 28, false, nil, 678)
            text(czech, x + 24, y + 114, 28, true, nil, 678)
            text(proof, x + 24, y + 172, 26, false, nil, 678)
            text(proof, x + 24, y + 216, 26, true, nil, 678)
            text("HH   SN   KD   ů   ď   ť   ň", x + 24, y + 274, 32, true, nil, 678)
            text("0123456789", x + 24, y + 332, 32, true, nil, 300, .left, true)
            text("88   96   112   128", x + 350, y + 332, 32, true, nil, 350, .left, true)
            text("1 l I   ·   0 O   ·   i m W", x + 24, y + 395, 26, false, p.secondary, 678)
        }
    }
}
}

// Width/design investigation only; these are not extra app typography variants.
canvas(1194, 624, 2, "sf-design-study") {
    face = .sf
    p = Palette(dark: false)
    rect(0, 0, 1194, 624, .white)
    text("SF Pro · Porovnání tvarů a šířky", 40, 28, 32, true, .black, 1114)
    let cases: [(String, NSFontDescriptor)] = [
        ("Výchozí", NSFont.systemFont(ofSize: 32, weight: .bold).fontDescriptor),
        ("Rounded · vybraná varianta A", NSFont.systemFont(ofSize: 32, weight: .bold).fontDescriptor.withDesign(.rounded)!),
        ("Expanded", NSFont.systemFont(ofSize: 32, weight: .bold, width: .expanded).fontDescriptor)
    ]
    for (i, item) in cases.enumerated() {
        let y = 105 + CGFloat(i)*166
        text(item.0, 40, y, 22, false, color(0x595959), 1114)
        let font = NSFont(descriptor: item.1, size: 32)!
        NSAttributedString(string: "Osminový groove   HH  SN  KD   Příliš žluťoučký kůň",
                           attributes: [.font: font, .foregroundColor: NSColor.black])
            .draw(at: NSPoint(x: 40, y: y + 42))
        audit.append(["sf_design_study": item.0, "font": font.fontName,
                      "traits": CTFontCopyTraits(font as CTFont),
                      "specimen_width": lineWidth("Osminový groove   HH  SN  KD   Příliš žluťoučký kůň", font)])
    }
}

let record: [String: Any] = ["date": "2026-11-02", "renderer": "macOS AppKit / CoreText; process-local font registration",
    "screen_points": [1194,834], "screen_pixels": [2388,1668], "weights": [400,700],
    "screen_count": 24, "png_count": studyOnly ? 33 : images.count, "single_line_fit_checks": textChecks,
    "czech_characters": czech, "proof": proof, "results": audit]
try! JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys])
    .write(to: root.appendingPathComponent("font-verification.json"))
print(studyOnly ? "Updated SF design study only; preserved completed font verification." :
      "Rendered \(images.count) PNG files. Verified \(textChecks) text placements and six font instances.")
