import AppKit
import SwiftUI

@MainActor
final class NotchPanel: NSPanel {
    private let player: NowPlayingController
    private var compactSize = NSSize(width: 300, height: 40)
    private var idleCompactSize = NSSize(width: 190, height: 40)
    private var visibleExpandedSize = NSSize(width: 450, height: 212)
    private let panelSize = NSSize(width: 450, height: 212)
    private var configuredDisplayTarget = AppPreferences.displayTarget

    init(player: NowPlayingController) {
        self.player = player
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isMovable = false
        animationBehavior = .none

        configureForSelectedDisplay(display: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesDidChange),
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }

    override var canBecomeKey: Bool { true }

    func show() { orderFrontRegardless() }

    func toggleExpanded() {
        player.toggleExpanded()
    }

    private func configureForSelectedDisplay(display: Bool) {
        configuredDisplayTarget = AppPreferences.displayTarget
        let screen = Self.selectedScreen(for: configuredDisplayTarget)
        let usesExternalDisplayStyle = !Self.isBuiltIn(screen)
        let notchWidth = usesExternalDisplayStyle ? 0 : Self.notchWidth(on: screen)
        compactSize = NSSize(
            width: usesExternalDisplayStyle ? 300 : max(300, notchWidth + 128),
            height: 40
        )
        idleCompactSize = NSSize(
            width: usesExternalDisplayStyle ? 0 : notchWidth,
            height: 40
        )
        visibleExpandedSize = NSSize(
            width: usesExternalDisplayStyle ? 420 : panelSize.width,
            height: panelSize.height
        )

        let rootView = NotchView(
            player: player,
            notchWidth: notchWidth,
            idleCompactWidth: idleCompactSize.width,
            compactWidth: compactSize.width,
            expandedWidth: visibleExpandedSize.width,
            canvasSize: panelSize,
            usesExternalDisplayStyle: usesExternalDisplayStyle
        )
        let hostingView = NotchHostingView(
            rootView: rootView,
            player: player,
            idleCompactSize: idleCompactSize,
            compactSize: compactSize,
            expandedSize: visibleExpandedSize
        )
        hostingView.sizingOptions = []
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView

        // Keep the AppKit window fixed. Only the SwiftUI island animates.
        setFrame(frame(for: panelSize, on: screen, floating: usesExternalDisplayStyle), display: display)
    }

    @objc private func screenParametersDidChange() {
        configureForSelectedDisplay(display: true)
        orderFrontRegardless()
    }

    @objc private func preferencesDidChange() {
        guard configuredDisplayTarget != AppPreferences.displayTarget else { return }
        configureForSelectedDisplay(display: true)
        orderFrontRegardless()
    }

    private func frame(for size: NSSize, on screen: NSScreen, floating: Bool) -> NSRect {
        let topEdge = floating ? screen.visibleFrame.maxY - 8 : screen.frame.maxY
        return NSRect(
            x: screen.frame.midX - size.width / 2,
            y: topEdge - size.height,
            width: size.width,
            height: size.height
        )
    }

    private static func selectedScreen(for target: DisplayTarget) -> NSScreen {
        let screens = NSScreen.screens
        guard let fallback = screens.first else {
            preconditionFailure("Notch Music requires an attached display")
        }

        switch target {
        case .builtIn:
            return screens.first(where: isBuiltIn) ?? fallback
        case .primary:
            // The first screen owns the menu bar and is the configured primary display.
            return fallback
        }
    }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return false
        }
        return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) != 0
    }

    private static func notchWidth(on screen: NSScreen) -> CGFloat {
        guard let left = screen.auxiliaryTopLeftArea,
            let right = screen.auxiliaryTopRightArea
        else { return 190 }
        return max(0, right.minX - left.maxX)
    }
}

/// The fixed transparent canvas must not block clicks outside the visible island.
@MainActor
private final class NotchHostingView: NSHostingView<NotchView> {
    private let player: NowPlayingController
    private let idleCompactSize: NSSize
    private let compactSize: NSSize
    private let expandedSize: NSSize

    init(
        rootView: NotchView,
        player: NowPlayingController,
        idleCompactSize: NSSize,
        compactSize: NSSize,
        expandedSize: NSSize
    ) {
        self.player = player
        self.idleCompactSize = idleCompactSize
        self.compactSize = compactSize
        self.expandedSize = expandedSize
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init(rootView: NotchView) {
        fatalError("Use the designated initializer")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let compactIsRevealed = !AppPreferences.dynamicCompactReveal || player.hasActiveTrack
        let size = player.isExpanded ? expandedSize : (compactIsRevealed ? compactSize : idleCompactSize)
        let visibleRect = NSRect(
            x: (bounds.width - size.width) / 2,
            y: bounds.height - size.height,
            width: size.width,
            height: size.height
        )
        guard visibleRect.contains(point) else { return nil }
        return super.hitTest(point)
    }
}
