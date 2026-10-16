import AppKit
import SwiftUI

@MainActor
final class NotchPanel: NSPanel {
    private let player: NowPlayingController
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
        let layout = NotchLayout(
            screenFrame: screen.frame,
            topInset: screen.safeAreaInsets.top,
            leftArea: screen.auxiliaryTopLeftArea,
            rightArea: screen.auxiliaryTopRightArea
        )

        let rootView = NotchView(
            player: player,
            layout: layout
        )
        let hostingView = NotchHostingView(
            rootView: rootView,
            player: player,
            layout: layout
        )
        hostingView.sizingOptions = []
        // This overlay intentionally occupies the camera's unsafe area.
        hostingView.safeAreaRegions = []
        hostingView.autoresizingMask = [.width, .height]
        contentView = hostingView

        // Keep the AppKit window fixed. Only the SwiftUI island animates.
        setFrame(layout.panelFrame(screenFrame: screen.frame, visibleFrame: screen.visibleFrame), display: display)
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
}

/// The fixed transparent canvas must not block clicks outside the visible island.
@MainActor
final class NotchHostingView: NSHostingView<NotchView> {
    private let player: NowPlayingController
    private let layout: NotchLayout

    init(
        rootView: NotchView,
        player: NowPlayingController,
        layout: NotchLayout
    ) {
        self.player = player
        self.layout = layout
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
        guard containsIslandPoint(point) else { return nil }
        return super.hitTest(point)
    }

    func containsIslandPoint(_ point: NSPoint) -> Bool {
        let compactIsRevealed = !AppPreferences.dynamicCompactReveal || player.hasActiveTrack
        let visibleRect = layout.hitRect(in: bounds, flipped: isFlipped, expanded: player.isExpanded, revealed: compactIsRevealed)
        // AppKit supplies a point in the superview's coordinates, while SwiftUI hosts are flipped.
        let localPoint = convert(point, from: superview)
        return visibleRect.contains(localPoint)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
