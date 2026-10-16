import Foundation
import MediaRemoteAdapter
import Testing
@testable import NotchMusic

struct PlaybackFilterTests {
    @Test func excludesBrowsersAndSelectedApps() {
        var filter = PlaybackFilter()
        #expect(filter.allows("com.apple.Safari"))
        filter.excludeBrowsers = true
        #expect(!filter.allows("com.google.Chrome.canary"))
        #expect(!filter.allows("com.naver.Whale"))
        #expect(filter.allows("com.spotify.client"))
        #expect(filter.allows(nil))
        filter.excludedBundleIdentifiers.insert("com.apple.Music")
        #expect(!filter.allows("com.apple.music"))
        #expect(PlaybackFilter.decode(filter.encoded) == filter)
        #expect(PlaybackFilter.decode(Data([1, 2, 3])) == PlaybackFilter())
    }

    @MainActor @Test func preferenceChangesImmediatelyHideAndRestoreCurrentTrack() throws {
        let suite = "NotchMusicTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let player = NowPlayingController(defaults: defaults)
        player.receive(TrackInfo(payload: .init(title: "Test", isPlaying: true, bundleIdentifier: "com.apple.Safari")))
        #expect(player.hasActiveTrack)
        var filter = PlaybackFilter()
        filter.excludeBrowsers = true
        defaults.set(filter.encoded, forKey: PreferenceKey.playbackFilter)
        player.refreshPlaybackFilter()
        #expect(!player.hasActiveTrack)
        #expect(!player.isExpanded)
        #expect(player.knownSources.map(\.id) == ["com.apple.Safari"])
        defaults.removeObject(forKey: PreferenceKey.playbackFilter)
        player.refreshPlaybackFilter()
        #expect(player.hasActiveTrack)
        #expect(player.track.title == "Test")
    }
}
