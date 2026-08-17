import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let player = NowPlayingController()
    private var notchPanel: NotchPanel?
    private var statusItem: NSStatusItem?
    private let settingsWindow = SettingsWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppPreferences.registerDefaults()
        NSApp.setActivationPolicy(.accessory)
        notchPanel = NotchPanel(player: player)
        notchPanel?.show()
        installMenuBarItem()
        player.start()
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Notch Music")
        let menu = NSMenu()
        let notchItem = menu.addItem(withTitle: "노치 열기", action: #selector(toggleNotch), keyEquivalent: "n")
        notchItem.target = self
        let settingsItem = menu.addItem(withTitle: "설정…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "종료", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        item.menu = menu
        statusItem = item
    }

    @objc private func toggleNotch() { notchPanel?.toggleExpanded() }
    @objc private func openSettings() { settingsWindow.show() }
    @objc private func quit() { NSApp.terminate(nil) }
}
