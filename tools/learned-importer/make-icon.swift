import AppKit
import Foundation

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon-1024.png"

let size = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    FileHandle.standardError.write(Data("Could not create bitmap\n".utf8))
    exit(1)
}

guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
    FileHandle.standardError.write(Data("Could not create graphics context\n".utf8))
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let canvas = NSRect(x: 0, y: 0, width: size, height: size)
NSColor.clear.setFill()
canvas.fill()

let tileRect = canvas.insetBy(dx: 40, dy: 40)
let tile = NSBezierPath(roundedRect: tileRect, xRadius: 220, yRadius: 220)

if let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.13, alpha: 1),
    NSColor(calibratedRed: 0.035, green: 0.035, blue: 0.045, alpha: 1),
]) {
    gradient.draw(in: tile, angle: -60)
} else {
    NSColor(calibratedWhite: 0.06, alpha: 1).setFill()
    tile.fill()
}

NSColor(calibratedWhite: 1, alpha: 0.14).setStroke()
tile.lineWidth = 6
tile.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let font = NSFont.monospacedSystemFont(ofSize: 300, weight: .bold)
let textAttributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph,
]

let text = "TIL" as NSString
let textHeight = text.size(withAttributes: textAttributes).height
text.draw(
    in: NSRect(x: 0, y: 435, width: CGFloat(size), height: textHeight),
    withAttributes: textAttributes
)

let accent = NSColor(calibratedRed: 0.35, green: 0.82, blue: 0.60, alpha: 1)
accent.setFill()
NSBezierPath(
    roundedRect: NSRect(x: CGFloat(size) / 2 - 150, y: 340, width: 300, height: 34),
    xRadius: 17,
    yRadius: 17
).fill()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("Could not encode PNG\n".utf8))
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
