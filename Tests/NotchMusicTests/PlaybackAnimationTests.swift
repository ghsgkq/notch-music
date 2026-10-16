import Foundation
import Testing
@testable import NotchMusic

struct PlaybackAnimationTests {
    @Test(arguments: PlaybackAnimationStyle.allCases)
    func animatesOnlyDuringPlayback(style: PlaybackAnimationStyle) {
        func frame(_ time: Double, playing: Bool = true, reduced: Bool = false) -> PlaybackAnimationGeometry {
            PlaybackAnimationGeometry(style: style, size: CGSize(width: 17, height: 18), time: time, isPlaying: playing, reduceMotion: reduced)
        }
        #expect(frame(0) != frame(0.3))
        #expect(frame(0, playing: false) == frame(100, playing: false))
        #expect(frame(0, reduced: true) == frame(100, reduced: true))
    }

    @Test(arguments: PlaybackAnimationStyle.allCases)
    func fitsCompactAndExpandedIndicators(style: PlaybackAnimationStyle) {
        for size in [CGSize(width: 17, height: 18), CGSize(width: 20, height: 24), CGSize(width: 30, height: 18), CGSize(width: 40, height: 24), CGSize(width: 30, height: 30), CGSize(width: 8, height: 8)] {
            let bounds = CGRect(origin: .zero, size: size)
            for time in [-0.2, 0, 0.3, 1.0, 1_000_000, Double.infinity, Double.nan] {
                let geometry = PlaybackAnimationGeometry(style: style, size: size, time: time, isPlaying: true, reduceMotion: false)
                for rect in geometry.bars + geometry.dots {
                    #expect(rect.minX.isFinite && rect.minY.isFinite)
                    #expect(bounds.contains(rect))
                }
                for pixel in geometry.pixels {
                    #expect(pixel.rect.minX.isFinite && pixel.rect.minY.isFinite)
                    #expect(bounds.insetBy(dx: -0.0001, dy: -0.0001).contains(pixel.rect))
                }
                for point in geometry.wave {
                    #expect(point.x.isFinite && point.y.isFinite)
                    #expect(bounds.contains(point))
                }
                if let ring = geometry.ring {
                    #expect(ring.angle.isFinite)
                    let extent = ring.radius + geometry.lineWidth / 2
                    #expect(bounds.contains(CGRect(x: ring.center.x - extent, y: ring.center.y - extent, width: extent * 2, height: extent * 2)))
                }
            }
        }
    }

    @Test func emptyLayoutAndUnknownSavedStyleAreHandled() {
        for style in PlaybackAnimationStyle.allCases {
            let geometry = PlaybackAnimationGeometry(style: style, size: .zero, time: 1, isPlaying: true, reduceMotion: false)
            #expect(geometry.bars.isEmpty && geometry.dots.isEmpty && geometry.wave.isEmpty && geometry.ring == nil && geometry.pixels.isEmpty)
        }
        #expect(PlaybackAnimationStyle(storedValue: "old-or-unknown-value") == .bars)
    }

    @Test func nyanCatIncludesTheCatAndSixRainbowColors() {
        let geometry = PlaybackAnimationGeometry(style: .nyanCat, size: CGSize(width: 30, height: 18), time: 0, isPlaying: true, reduceMotion: false)
        let colors = Set(geometry.pixels.map(\.color))
        #expect(colors.isSuperset(of: [.red, .orange, .yellow, .green, .blue, .purple, .fur, .pastry]))
        #expect(PlaybackAnimationStyle.nyanCat.compactWidth + 10 <= 46)
    }
}
