import AppKit
import Testing
@testable import NotchMusic

struct NotchLayoutTests {
    @Test(arguments: [
        (CGFloat(1512), CGFloat(982), CGFloat(190), CGFloat(32)),
        (1800, 1169, 226, 38),
        (2056, 1329, 258, 44),
        (3024, 1964, 380, 64),
        (1280, 832, 160, 27),
        (2045, 1323, 222, 39.5)
    ])
    func scaledResolutions(dimensions: (CGFloat, CGFloat, CGFloat, CGFloat)) {
        let (width, height, notchWidth, notchHeight) = dimensions
        let screen = NSRect(x: 0, y: 0, width: width, height: height)
        let layout = makeLayout(screen: screen, width: notchWidth, height: notchHeight)

        #expect(!layout.isFloating)
        #expect(layout.idleSize == NSSize(width: notchWidth, height: notchHeight))
        #expect(layout.compactSize.height == notchHeight)
        #expect(layout.compactSize.width >= notchWidth + 120) // Space for both controls and padding.
        #expect(layout.expandedSize.height - notchHeight == 172)
        #expect(layout.canvasSize.width >= layout.compactSize.width)

        let panel = layout.panelFrame(screenFrame: screen, visibleFrame: screen)
        #expect(panel.maxY == screen.maxY)
        #expect(panel.midX == screen.midX)

        let bounds = NSRect(origin: .zero, size: layout.canvasSize)
        let idle = layout.hitRect(in: bounds, flipped: false, expanded: false, revealed: false)
        let compact = layout.hitRect(in: bounds, flipped: false, expanded: false, revealed: true)
        let expanded = layout.hitRect(in: bounds, flipped: false, expanded: true, revealed: true)
        #expect(idle.size == layout.idleSize)
        #expect(compact.size == layout.compactSize)
        #expect(compact.maxY == bounds.maxY)
        #expect(!compact.contains(NSPoint(x: bounds.midX, y: compact.minY - 1)))
        #expect(expanded.size == layout.expandedSize)
        #expect(expanded.maxY == bounds.maxY)
        #expect(bounds.contains(expanded))
        #expect(layout.canvasSize.height == ceil(layout.expandedSize.height))

        let flippedCompact = layout.hitRect(in: bounds, flipped: true, expanded: false, revealed: true)
        #expect(flippedCompact.minY == bounds.minY)
        #expect(flippedCompact.size == layout.compactSize)
        #expect(!flippedCompact.contains(NSPoint(x: bounds.midX, y: flippedCompact.maxY + 1)))
    }

    @MainActor @Test func hostConvertsClicksFromItsSuperview() {
        let screen = NSRect(x: 0, y: 0, width: 2045, height: 1323)
        let layout = makeLayout(screen: screen, width: 222, height: 39.5)
        let player = NowPlayingController()
        let parent = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        let host = NotchHostingView(rootView: NotchView(player: player, layout: layout), player: player, layout: layout)
        host.sizingOptions = []
        host.safeAreaRegions = []
        host.frame = NSRect(x: 40, y: 70, width: layout.canvasSize.width, height: layout.canvasSize.height)
        parent.addSubview(host)
        host.layoutSubtreeIfNeeded()

        let visible = layout.hitRect(in: host.bounds, flipped: host.isFlipped, expanded: false, revealed: false)
        let click = host.convert(NSPoint(x: visible.midX, y: visible.midY), to: parent)
        #expect(host.containsIslandPoint(click))
        let outside = host.convert(NSPoint(x: visible.midX, y: visible.maxY + 20), to: parent)
        #expect(!host.containsIslandPoint(outside))
        #expect(host.acceptsFirstMouse(for: nil))
    }

    @Test func displayWithOffsetOrigin() {
        let screen = NSRect(x: -1800, y: 240, width: 1800, height: 1169)
        let layout = makeLayout(screen: screen, width: 226, height: 38)
        let panel = layout.panelFrame(screenFrame: screen, visibleFrame: screen)
        #expect(panel.midX == -900)
        #expect(panel.maxY == 1409)
    }

    @Test func notchlessDisplaysUseFloatingPlayer() {
        let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let visible = NSRect(x: 0, y: 0, width: 1920, height: 1055)
        let layout = NotchLayout(screenFrame: screen, topInset: 0, leftArea: nil, rightArea: nil)
        #expect(layout.isFloating)
        #expect(layout.notchWidth == 0)
        #expect(layout.idleSize.width == 0)
        #expect(layout.compactSize == NSSize(width: 300, height: 40))
        #expect(layout.expandedSize == NSSize(width: 420, height: 212))
        #expect(layout.panelFrame(screenFrame: screen, visibleFrame: visible).maxY == 1047)
    }

    @Test func missingOrInvalidNotchAreasDoNotInventANotch() {
        let screen = NSRect(x: 0, y: 0, width: 1512, height: 982)
        let left = NSRect(x: 0, y: 950, width: 800, height: 32)
        let right = NSRect(x: 700, y: 950, width: 812, height: 32)
        #expect(NotchLayout(screenFrame: screen, topInset: 32, leftArea: left, rightArea: nil).isFloating)
        #expect(NotchLayout(screenFrame: screen, topInset: 32, leftArea: left, rightArea: right).isFloating)
        #expect(NotchLayout(screenFrame: screen, topInset: 0, leftArea: left, rightArea: right).isFloating)
    }

    private func makeLayout(screen: NSRect, width: CGFloat, height: CGFloat) -> NotchLayout {
        let left = NSRect(x: screen.minX, y: screen.maxY - height, width: (screen.width - width) / 2, height: height)
        let right = NSRect(x: screen.midX + width / 2, y: screen.maxY - height, width: left.width, height: height)
        return NotchLayout(screenFrame: screen, topInset: height, leftArea: left, rightArea: right)
    }
}
