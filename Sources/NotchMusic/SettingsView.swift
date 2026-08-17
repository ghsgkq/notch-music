import SwiftUI

struct SettingsView: View {
    @AppStorage(PreferenceKey.autoExpand) private var autoExpand = false
    @AppStorage(PreferenceKey.autoCollapse) private var autoCollapse = true
    @AppStorage(PreferenceKey.autoCollapseDelay) private var autoCollapseDelay = 4.5
    @AppStorage(PreferenceKey.showArtwork) private var showArtwork = true
    @AppStorage(PreferenceKey.showProgress) private var showProgress = true
    @AppStorage(PreferenceKey.showEqualizer) private var showEqualizer = true
    @AppStorage(PreferenceKey.hoverHighlight) private var hoverHighlight = true
    @AppStorage(PreferenceKey.reduceMotion) private var reduceMotion = false
    @AppStorage(PreferenceKey.accent) private var accent = AccentChoice.green.rawValue
    @AppStorage(PreferenceKey.liquidGlass) private var liquidGlass = true
    @AppStorage(PreferenceKey.displayTarget) private var displayTarget = DisplayTarget.builtIn.rawValue
    @AppStorage(PreferenceKey.dynamicCompactReveal) private var dynamicCompactReveal = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notch Music 설정")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("변경 내용은 바로 적용됩니다.")
                        .foregroundStyle(.secondary)
                }

                settingsGroup("곡 변경") {
                    Toggle("새 곡이 시작되면 상세 플레이어 펼치기", isOn: $autoExpand)
                    Toggle("알림 후 자동으로 접기", isOn: $autoCollapse)
                        .disabled(!autoExpand)
                    HStack {
                        Text("펼쳐진 시간")
                        Slider(value: $autoCollapseDelay, in: 2...12, step: 0.5)
                            .disabled(!autoExpand || !autoCollapse)
                        Text(String(format: "%.1f초", autoCollapseDelay))
                            .monospacedDigit()
                            .frame(width: 46, alignment: .trailing)
                    }
                }

                settingsGroup("표시") {
                    Toggle("음악 감지 시 노치 양옆으로 펼치기", isOn: $dynamicCompactReveal)
                    Toggle("앨범 표지 표시", isOn: $showArtwork)
                    Toggle("재생 진행률 표시", isOn: $showProgress)
                    Toggle("재생 이퀄라이저 표시", isOn: $showEqualizer)
                    Toggle("마우스 호버 강조 효과", isOn: $hoverHighlight)
                }

                settingsGroup("디스플레이") {
                    Picker("표시 위치", selection: $displayTarget) {
                        ForEach(DisplayTarget.allCases) { target in
                            Text(target.title).tag(target.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(displayTarget == DisplayTarget.builtIn.rawValue
                         ? "외부 모니터가 주 화면이어도 MacBook 노치에 고정합니다."
                         : "외부 모니터에서는 화면 상단의 플로팅 플레이어 디자인을 사용합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                settingsGroup("스타일") {
                    Toggle("펼친 화면에 리퀴드 글래스 적용", isOn: $liquidGlass)

                    Picker("강조 색상", selection: $accent) {
                        ForEach(AccentChoice.allCases) { choice in
                            Text(choice.title).tag(choice.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("애니메이션 움직임 줄이기", isOn: $reduceMotion)
                }

                HStack {
                    Spacer()
                    Button("기본값으로 재설정") { reset() }
                }
            }
            .padding(24)
        }
        .frame(width: 500, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) { content() }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
        } label: {
            Text(title).font(.headline)
        }
    }

    private func reset() {
        autoExpand = false
        autoCollapse = true
        autoCollapseDelay = 4.5
        showArtwork = true
        showProgress = true
        showEqualizer = true
        hoverHighlight = true
        reduceMotion = false
        accent = AccentChoice.green.rawValue
        liquidGlass = true
        displayTarget = DisplayTarget.builtIn.rawValue
        dynamicCompactReveal = true
    }
}
