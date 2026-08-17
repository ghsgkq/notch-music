import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fatalError("Expected output PNG path")
}

let canvas = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvas)
image.lockFocus()

let backgroundRect = NSRect(x: 52, y: 52, width: 920, height: 920)
let backgroundPath = NSBezierPath(roundedRect: backgroundRect, xRadius: 220, yRadius: 220)
NSGradient(colors: [
    NSColor(red: 0.09, green: 0.10, blue: 0.14, alpha: 1),
    NSColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1)
])!.draw(in: backgroundPath, angle: -45)

NSColor.black.setFill()
NSBezierPath(roundedRect: NSRect(x: 252, y: 724, width: 520, height: 180), xRadius: 90, yRadius: 90).fill()

let waveGradient = NSGradient(colors: [
    NSColor(red: 0.20, green: 0.96, blue: 0.49, alpha: 1),
    NSColor(red: 0.13, green: 0.79, blue: 1.0, alpha: 1)
])!
let bars: [NSRect] = [
    NSRect(x: 292, y: 312, width: 52, height: 118),
    NSRect(x: 388, y: 238, width: 52, height: 266),
    NSRect(x: 484, y: 278, width: 52, height: 186),
    NSRect(x: 580, y: 192, width: 52, height: 358),
    NSRect(x: 676, y: 268, width: 52, height: 206)
]
for bar in bars {
    waveGradient.draw(in: NSBezierPath(roundedRect: bar, xRadius: 26, yRadius: 26), angle: -45)
}

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fatalError("Could not render icon")
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
