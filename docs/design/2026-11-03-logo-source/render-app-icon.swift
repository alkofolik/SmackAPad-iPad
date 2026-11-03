import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let canvasRect = CGRect(x: 0, y: 0, width: size, height: size)

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
    fatalError("Could not create sRGB color space")
}

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("Could not create CGContext")
}

// Background: #F2F0EA full bleed square
let cream = CGColor(
    srgbRed: CGFloat(0xF2) / 255.0,
    green: CGFloat(0xF0) / 255.0,
    blue: CGFloat(0xEA) / 255.0,
    alpha: 1.0
)
context.setFillColor(cream)
context.fill(canvasRect)

// Flip Y to match SVG coordinate space (top-left origin, y pointing down)
context.translateBy(x: 0, y: CGFloat(size))
context.scaleBy(x: 1.0, y: -1.0)

// Scale 100x100 SVG space to 1024x1024 (10.24 scale factor)
let scale: CGFloat = CGFloat(size) / 100.0
context.scaleBy(x: scale, y: scale)

// Black pads: #111111, 32x32, corner radius 3
let black = CGColor(
    srgbRed: CGFloat(0x11) / 255.0,
    green: CGFloat(0x11) / 255.0,
    blue: CGFloat(0x11) / 255.0,
    alpha: 1.0
)
context.setFillColor(black)

let blackPads = [
    CGRect(x: 14, y: 18, width: 32, height: 32),
    CGRect(x: 14, y: 58, width: 32, height: 32),
    CGRect(x: 54, y: 58, width: 32, height: 32)
]

for pad in blackPads {
    let path = CGPath(roundedRect: pad, cornerWidth: 3, cornerHeight: 3, transform: nil)
    context.addPath(path)
    context.fillPath()
}

// Orange pad: #FF5B1F, 32x32, radius 3, rotated 12° about (73, 27)
let orange = CGColor(
    srgbRed: CGFloat(0xFF) / 255.0,
    green: CGFloat(0x5B) / 255.0,
    blue: CGFloat(0x1F) / 255.0,
    alpha: 1.0
)
context.saveGState()
context.translateBy(x: 73, y: 27)
context.rotate(by: 12.0 * .pi / 180.0)
context.translateBy(x: -73, y: -27)

context.setFillColor(orange)
let orangePath = CGPath(
    roundedRect: CGRect(x: 57, y: 11, width: 32, height: 32),
    cornerWidth: 3,
    cornerHeight: 3,
    transform: nil
)
context.addPath(orangePath)
context.fillPath()
context.restoreGState()

// Make CGImage
guard let image = context.makeImage() else {
    fatalError("Could not create CGImage from context")
}

// Output URL
let scriptURL = URL(fileURLWithPath: #filePath)
let directoryURL = scriptURL.deletingLastPathComponent()
let outputURL = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : directoryURL.appendingPathComponent("app-icon-1024.png")

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fatalError("Could not create image destination for \(outputURL.path)")
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Failed to write PNG to \(outputURL.path)")
}

print("Rendered app icon to \(outputURL.path)")
