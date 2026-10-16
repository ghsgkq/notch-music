import AppKit
import Testing
@testable import NotchMusic

struct DisplayAdjustmentTests {
    @Test func storesDisplaysIndependentlyAndResetsOnlyOne() {
        var values = DisplayAdjustments()
        values["internal"] = DisplayAdjustment(horizontalOffset: 8, heightAdjustment: 3)
        values["external"] = DisplayAdjustment(verticalOffset: 10, widthAdjustment: 20)
        let restored = DisplayAdjustments.decode(values.encoded)
        #expect(restored == values)
        values["internal"] = DisplayAdjustment()
        #expect(values["internal"] == DisplayAdjustment())
        #expect(values["external"] == restored["external"])
        #expect(DisplayAdjustments.decode(Data([1])) == DisplayAdjustments())
    }

    @Test func normalizesInvalidAndExtremeValues() {
        let value = DisplayAdjustment(horizontalOffset: .infinity, verticalOffset: -100, widthAdjustment: 1000, heightAdjustment: -100).normalized
        #expect(value.horizontalOffset == 0)
        #expect(value.verticalOffset == -20)
        #expect(value.widthAdjustment == 128)
        #expect(value.heightAdjustment == -12)
    }

    @Test func adjustedGeometryKeepsDrawingAndClicksTogether() {
        let screen = NSRect(x: 0, y: 0, width: 2045, height: 1323)
        let left = NSRect(x: 0, y: 1283.5, width: 911.5, height: 39.5)
        let right = NSRect(x: 1133.5, y: 1283.5, width: 911.5, height: 39.5)
        let adjustment = DisplayAdjustment(horizontalOffset: 8, verticalOffset: 5, widthAdjustment: 20, heightAdjustment: 3)
        let layout = NotchLayout(screenFrame: screen, topInset: 39.5, leftArea: left, rightArea: right, adjustment: adjustment)
        #expect(layout.notchWidth == 242)
        #expect(layout.idleSize == NSSize(width: 242, height: 42.5))
        #expect(layout.compactSize == NSSize(width: 370, height: 42.5))
        #expect(layout.canvasSize.height == 215)
        let frame = layout.panelFrame(screenFrame: screen, visibleFrame: screen)
        #expect(frame.midX == screen.midX + 8)
        #expect(frame.maxY == screen.maxY - 5)
        let bounds = NSRect(origin: .zero, size: layout.canvasSize)
        let hit = layout.hitRect(in: bounds, flipped: true, expanded: false, revealed: true)
        #expect(hit.size == layout.compactSize)
        #expect(hit.minY == bounds.minY)
    }
}
