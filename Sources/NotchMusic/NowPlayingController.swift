import Foundation
import MediaRemoteAdapter

struct Track: Equatable {
    var title = "재생 중인 음악 없음"
    var artist = "YouTube Music 등에서 음악을 재생하세요"
    var album = ""
    var artwork: Data?
}

@MainActor
final class NowPlayingController: ObservableObject {
    @Published var track = Track()
    @Published var isPlaying = false
    @Published var isExpanded = false
    @Published private(set) var hasActiveTrack = false
    @Published private(set) var duration: TimeInterval = 0
    @Published private(set) var elapsedTime: TimeInterval = 0

    private let mediaController = MediaController()
    private var started = false
    private var progressUpdatedAt = Date()
    private var autoCollapseTask: Task<Void, Never>?

    func start() {
        guard !started else { return }
        started = true

        if ProcessInfo.processInfo.environment["NOTCH_MUSIC_DEMO"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.applyDemo()
            }
            return
        }

        mediaController.onTrackInfoReceived = { [weak self] info in
            Task { @MainActor in self?.apply(info) }
        }
        mediaController.onListenerTerminated = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.started = false
                self.start()
            }
        }
        mediaController.startListening()
        mediaController.getTrackInfo { [weak self] info in
            Task { @MainActor in self?.apply(info) }
        }
    }

    func playPause() { mediaController.togglePlayPause() }
    func previous() { mediaController.previousTrack() }
    func next() { mediaController.nextTrack() }

    func seek(toProgress progress: Double) {
        guard duration > 0 else { return }
        let target = min(duration, max(0, progress * duration))
        elapsedTime = target
        progressUpdatedAt = Date()
        mediaController.setTime(seconds: target)
    }

    func toggleExpanded() {
        autoCollapseTask?.cancel()
        isExpanded.toggle()
    }

    func progress(at date: Date) -> Double {
        guard duration > 0 else { return 0 }
        let running = isPlaying ? max(0, date.timeIntervalSince(progressUpdatedAt)) : 0
        return min(1, max(0, (elapsedTime + running) / duration))
    }

    private func apply(_ info: TrackInfo?) {
        guard let payload = info?.payload, let title = payload.title, !title.isEmpty else {
            if ProcessInfo.processInfo.environment["NOTCH_MUSIC_DEBUG"] == "1" {
                print("[NotchMusic] adapter returned no active track")
            }
            track = Track()
            isPlaying = false
            hasActiveTrack = false
            duration = 0
            elapsedTime = 0
            return
        }

        let artist = payload.artist?.isEmpty == false ? payload.artist! : "알 수 없는 아티스트"
        if ProcessInfo.processInfo.environment["NOTCH_MUSIC_DEBUG"] == "1" {
            print("[NotchMusic] \(title) — \(artist), playing=\(payload.isPlaying ?? false), artwork=\(payload.artwork != nil)")
        }
        let changed = track.title != title || track.artist != artist
        track = Track(
            title: title,
            artist: artist,
            album: payload.album ?? "",
            artwork: payload.artwork?.tiffRepresentation
        )
        hasActiveTrack = true
        isPlaying = payload.isPlaying ?? ((payload.playbackRate ?? 0) > 0)
        duration = max(0, (payload.durationMicros ?? 0) / 1_000_000)
        elapsedTime = max(0, payload.currentElapsedTime ?? ((payload.elapsedTimeMicros ?? 0) / 1_000_000))
        progressUpdatedAt = Date()
        if isPlaying && changed && AppPreferences.autoExpand {
            isExpanded = true
            if AppPreferences.autoCollapse {
                scheduleAutoCollapse(for: title)
            } else {
                autoCollapseTask?.cancel()
            }
        }
    }

    private func applyDemo() {
        track = Track(title: "Dynamic Island Preview", artist: "Notch Music", album: "Demo", artwork: nil)
        isPlaying = true
        hasActiveTrack = true
        isExpanded = true
        duration = 244
        elapsedTime = 72
        progressUpdatedAt = Date()
    }

    private func scheduleAutoCollapse(for title: String) {
        autoCollapseTask?.cancel()
        autoCollapseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(2, AppPreferences.autoCollapseDelay)))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self, self.track.title == title else { return }
                self.isExpanded = false
            }
        }
    }
}
