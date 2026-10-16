import AppKit
import Testing
@testable import NotchMusic

struct ArtworkAccentTests {
    @Test(arguments: [NSColor.red, .green, .blue])
    func preservesDominantHue(color: NSColor) throws {
        let result = try #require(ArtworkAccent.color(from: imageData(color)))
        let expected = try #require(color.usingColorSpace(.sRGB))
        #expect(abs(result.hueComponent - expected.hueComponent) < 0.05)
        #expect(result.brightnessComponent >= 0.72)
    }

    @Test func fallsBackForAbsentInvalidAndNeutralArtwork() {
        #expect(ArtworkAccent.color(from: nil) == nil)
        #expect(ArtworkAccent.color(from: Data([0, 1, 2])) == nil)
        for color in [NSColor.black, .white, .gray, .clear] {
            #expect(ArtworkAccent.color(from: imageData(color)) == nil)
        }
    }

    private func imageData(_ color: NSColor) -> Data? {
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 16, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        guard let image = context.makeImage() else { return nil }
        return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    }
}
