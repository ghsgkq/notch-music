import SwiftUI

@main
struct NotchMusicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(player: appDelegate.player)
        }
    }
}
