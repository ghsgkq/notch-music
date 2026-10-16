import Testing
@testable import NotchMusic

@MainActor
struct HoverExpansionTests {
    private func player() -> NowPlayingController {
        NowPlayingController(hoverOpenDelay: .milliseconds(10), hoverCloseDelay: .milliseconds(10))
    }

    @Test func opensAndClosesOnHover() async throws {
        let player = player()
        player.updateHover(true, enabled: true)
        try await Task.sleep(for: .milliseconds(60))
        #expect(player.isExpanded)
        player.updateHover(false, enabled: true)
        try await Task.sleep(for: .milliseconds(60))
        #expect(!player.isExpanded)
    }

    @Test func quickPassDoesNotOpenAndReentryCancelsClosing() async throws {
        let player = player()
        player.updateHover(true, enabled: true)
        player.updateHover(false, enabled: true)
        try await Task.sleep(for: .milliseconds(60))
        #expect(!player.isExpanded)
        player.updateHover(true, enabled: true)
        try await Task.sleep(for: .milliseconds(60))
        player.updateHover(false, enabled: true)
        player.updateHover(true, enabled: true)
        try await Task.sleep(for: .milliseconds(60))
        #expect(player.isExpanded)
        player.updateHover(false, enabled: false)
    }

    @Test func manualOpeningIsPreservedAndDisablingCancelsPendingOpen() async throws {
        let player = player()
        player.toggleExpanded()
        player.updateHover(true, enabled: true)
        player.updateHover(false, enabled: true)
        try await Task.sleep(for: .milliseconds(60))
        #expect(player.isExpanded)
        player.toggleExpanded()
        player.updateHover(true, enabled: true)
        player.updateHover(true, enabled: false)
        try await Task.sleep(for: .milliseconds(60))
        #expect(!player.isExpanded)
    }
}
