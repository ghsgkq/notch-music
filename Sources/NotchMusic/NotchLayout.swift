import AppKit

/// All dimensions use AppKit points, including when the display uses a scaled resolution.
struct NotchLayout {
    let notchRect: NSRect?
    let compactSize: NSSize
    let idleSize: NSSize
    let expandedSize: NSSize

    var isFloating: Bool { notchRect == nil }
    var notchWidth: CGFloat { notchRect?.width ?? 0 }
    // AppKit can round window dimensions to whole points. Keep the host and its canvas equal.
    var canvasSize: NSSize {
        NSSize(width: ceil(expandedSize.width), height: ceil(expandedSize.height))
    }

    init(screenFrame: NSRect, topInset: CGFloat, leftArea: NSRect?, rightArea: NSRect?) {
        if topInset > 0, let leftArea, let rightArea, rightArea.minX > leftArea.maxX {
            notchRect = NSRect(
                x: leftArea.maxX,
                y: screenFrame.maxY - topInset,
                width: rightArea.minX - leftArea.maxX,
                height: topInset
            )
        } else {
            notchRect = nil
        }

        let height = notchRect?.height ?? 40
        let width = notchRect.map { $0.width + 128 } ?? 300
        compactSize = NSSize(width: width, height: height)
        idleSize = NSSize(width: notchRect?.width ?? 0, height: height)
        expandedSize = NSSize(width: max(notchRect == nil ? 420 : 450, width), height: height + 172)
    }

    func panelFrame(screenFrame: NSRect, visibleFrame: NSRect) -> NSRect {
        let centerX = notchRect?.midX ?? screenFrame.midX
        let topEdge = isFloating ? visibleFrame.maxY - 8 : screenFrame.maxY
        return NSRect(
            x: centerX - canvasSize.width / 2,
            y: topEdge - canvasSize.height,
            width: canvasSize.width,
            height: canvasSize.height
        )
    }

    func hitRect(in bounds: NSRect, flipped: Bool, expanded: Bool, revealed: Bool) -> NSRect {
        let size = expanded ? expandedSize : (revealed ? compactSize : idleSize)
        return NSRect(
            x: bounds.midX - size.width / 2,
            y: flipped ? bounds.minY : bounds.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }
}
