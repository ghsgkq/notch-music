import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PlaybackApp: Identifiable, Equatable {
    let id: String
    let name: String
}

struct PlaybackFilter: Codable, Equatable {
    var excludeBrowsers = false
    var excludedBundleIdentifiers: Set<String> = []
    var customApps: [String: String] = [:]

    static let browserIdentifiers: Set<String> = [
        "com.apple.safari", "com.google.chrome", "org.chromium.chromium",
        "com.microsoft.edgemac", "org.mozilla.firefox", "com.brave.browser",
        "company.thebrowser.browser", "com.operasoftware.opera", "com.naver.whale",
        "com.vivaldi.vivaldi", "io.gitlab.librewolf-community"
    ]

    func allows(_ bundleIdentifier: String?) -> Bool {
        guard let id = bundleIdentifier?.lowercased(), !id.isEmpty else { return true }
        guard !excludedBundleIdentifiers.contains(where: { $0.lowercased() == id }) else { return false }
        return !excludeBrowsers || !Self.isBrowser(id)
    }

    static func isBrowser(_ identifier: String) -> Bool {
        let id = identifier.lowercased()
        return browserIdentifiers.contains { id == $0 || id.hasPrefix($0 + ".") }
    }

    static func decode(_ data: Data?) -> Self {
        guard let data, let filter = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return filter
    }

    var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
}

struct PlaybackFilterView: View {
    @ObservedObject var player: NowPlayingController
    @AppStorage(PreferenceKey.playbackFilter) private var filterData = Data()
    @State private var errorMessage: String?

    private var filter: PlaybackFilter { .decode(filterData) }

    private var apps: [PlaybackApp] {
        var names = filter.customApps
        for app in player.knownSources { names[app.id] = app.name }
        let common = ["com.apple.Music", "com.spotify.client", "com.apple.Safari", "com.google.Chrome", "com.naver.Whale", "com.microsoft.edgemac", "org.mozilla.firefox", "company.thebrowser.Browser"]
        for id in Set(common).union(filter.excludedBundleIdentifiers) {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
                names[id] = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
            } else if names[id] == nil, filter.excludedBundleIdentifiers.contains(id) {
                names[id] = id
            }
        }
        return names.map { PlaybackApp(id: $0.key, name: $0.value) }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("브라우저의 재생 정보 제외", isOn: Binding(
                get: { filter.excludeBrowsers },
                set: { value in update { $0.excludeBrowsers = value } }
            ))
            Text("표시할 앱을 선택하세요. 현재 재생이 감지된 앱도 목록에 추가됩니다.")
                .font(.caption).foregroundStyle(.secondary)
            ForEach(apps) { app in
                Toggle(app.name, isOn: Binding(
                    get: { filter.allows(app.id) },
                    set: { allowed in
                        update {
                            if allowed { $0.excludedBundleIdentifiers.remove(app.id) }
                            else { $0.excludedBundleIdentifiers.insert(app.id) }
                        }
                    }
                ))
                .disabled(filter.excludeBrowsers && PlaybackFilter.isBrowser(app.id))
            }
            Button("다른 앱 추가…", action: addApp)
            if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
        }
    }

    private func update(_ change: (inout PlaybackFilter) -> Void) {
        var value = filter
        change(&value)
        filterData = value.encoded
        player.refreshPlaybackFilter()
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "추가"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let id = Bundle(url: url)?.bundleIdentifier else {
            errorMessage = "선택한 앱의 정보를 읽지 못했습니다."
            return
        }
        errorMessage = nil
        let name = FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
        update { $0.customApps[id] = name }
    }
}
