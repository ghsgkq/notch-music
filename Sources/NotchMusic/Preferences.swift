import SwiftUI

enum PreferenceKey {
    static let autoExpand = "autoExpandOnTrackChange"
    static let autoCollapse = "autoCollapseAfterTrackChange"
    static let autoCollapseDelay = "autoCollapseDelay"
    static let showArtwork = "showArtwork"
    static let showProgress = "showProgress"
    static let showEqualizer = "showEqualizer"
    static let hoverHighlight = "hoverHighlight"
    static let reduceMotion = "reduceMotion"
    static let accent = "accentColor"
    static let liquidGlass = "liquidGlass"
    static let displayTarget = "displayTarget"
    static let dynamicCompactReveal = "dynamicCompactReveal"
}

enum AppPreferences {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            PreferenceKey.autoExpand: false,
            PreferenceKey.autoCollapse: true,
            PreferenceKey.autoCollapseDelay: 4.5,
            PreferenceKey.showArtwork: true,
            PreferenceKey.showProgress: true,
            PreferenceKey.showEqualizer: true,
            PreferenceKey.hoverHighlight: true,
            PreferenceKey.reduceMotion: false,
            PreferenceKey.accent: AccentChoice.green.rawValue,
            PreferenceKey.liquidGlass: true,
            PreferenceKey.displayTarget: DisplayTarget.builtIn.rawValue,
            PreferenceKey.dynamicCompactReveal: true
        ])
    }

    static var autoExpand: Bool { UserDefaults.standard.bool(forKey: PreferenceKey.autoExpand) }
    static var autoCollapse: Bool { UserDefaults.standard.bool(forKey: PreferenceKey.autoCollapse) }
    static var autoCollapseDelay: Double { UserDefaults.standard.double(forKey: PreferenceKey.autoCollapseDelay) }
    static var displayTarget: DisplayTarget {
        DisplayTarget(rawValue: UserDefaults.standard.string(forKey: PreferenceKey.displayTarget) ?? "") ?? .builtIn
    }
    static var dynamicCompactReveal: Bool {
        UserDefaults.standard.bool(forKey: PreferenceKey.dynamicCompactReveal)
    }
}

enum DisplayTarget: String, CaseIterable, Identifiable {
    case builtIn
    case primary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .builtIn: "내장 디스플레이"
        case .primary: "현재 주 디스플레이"
        }
    }
}

enum AccentChoice: String, CaseIterable, Identifiable {
    case green, blue, purple, pink

    var id: String { rawValue }

    var title: String {
        switch self {
        case .green: "그린"
        case .blue: "블루"
        case .purple: "퍼플"
        case .pink: "핑크"
        }
    }

    var color: Color {
        switch self {
        case .green: .green
        case .blue: .cyan
        case .purple: .purple
        case .pink: .pink
        }
    }
}
