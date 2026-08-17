import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift VideoToGIF.swift input.mov output.gif")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let asset = AVURLAsset(url: inputURL)
let duration = try await asset.load(.duration)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let frameRate = 12.0
let frameCount = max(1, Int(CMTimeGetSeconds(duration) * frameRate))
guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.gif.identifier as CFString,
    frameCount,
    nil
) else {
    fatalError("Could not create GIF destination")
}

CGImageDestinationSetProperties(destination, [
    kCGImagePropertyGIFDictionary: [
        kCGImagePropertyGIFLoopCount: 0
    ]
] as CFDictionary)

for index in 0..<frameCount {
    let seconds = Double(index) / frameRate
    let time = CMTime(seconds: seconds, preferredTimescale: 600)
    let (image, _) = try await generator.image(at: time)
    CGImageDestinationAddImage(destination, image, [
        kCGImagePropertyGIFDictionary: [
            kCGImagePropertyGIFDelayTime: 1.0 / frameRate
        ]
    ] as CFDictionary)
}

guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not finish GIF")
}

print(outputURL.path)
