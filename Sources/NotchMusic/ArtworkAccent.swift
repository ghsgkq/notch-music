import AppKit

enum ArtworkAccent {
    /// Sample a small sRGB thumbnail so artwork size does not affect extraction cost.
    static func color(from data: Data?) -> NSColor? {
        guard let data, let image = NSBitmapImageRep(data: data)?.cgImage,
              let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let side = 32
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress, width: side, height: side,
                bitsPerComponent: 8, bytesPerRow: side * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard rendered else { return nil }

        var weights = [CGFloat](repeating: 0, count: 24)
        var reds = weights, greens = weights, blues = weights
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let alpha = CGFloat(pixels[index + 3]) / 255
            guard alpha > 0.5 else { continue }
            let red = CGFloat(pixels[index]) / 255 / alpha
            let green = CGFloat(pixels[index + 1]) / 255 / alpha
            let blue = CGFloat(pixels[index + 2]) / 255 / alpha
            let sample = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
            let saturation = sample.saturationComponent
            let brightness = sample.brightnessComponent
            guard saturation > 0.12, brightness > 0.15 else { continue }
            let bin = min(23, Int(sample.hueComponent * 24))
            let weight = saturation * brightness * alpha
            weights[bin] += weight
            reds[bin] += red * weight
            greens[bin] += green * weight
            blues[bin] += blue * weight
        }
        guard let best = weights.indices.max(by: { weights[$0] < weights[$1] }), weights[best] > 0 else { return nil }
        let dominant = NSColor(srgbRed: reds[best] / weights[best], green: greens[best] / weights[best], blue: blues[best] / weights[best], alpha: 1)
        return NSColor(
            calibratedHue: dominant.hueComponent,
            saturation: min(0.85, max(0.45, dominant.saturationComponent)),
            brightness: min(1, max(0.72, dominant.brightnessComponent)), alpha: 1
        )
    }
}
