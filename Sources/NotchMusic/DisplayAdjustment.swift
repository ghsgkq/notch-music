import AppKit
import SwiftUI

struct DisplayAdjustment: Codable, Equatable {
    var horizontalOffset: Double = 0
    var verticalOffset: Double = 0
    var widthAdjustment: Double = 0
    var heightAdjustment: Double = 0

    var normalized: Self {
        func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
            value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : 0
        }
        return Self(
            horizontalOffset: clamp(horizontalOffset, -40...40),
            verticalOffset: clamp(verticalOffset, -20...40),
            widthAdjustment: clamp(widthAdjustment, -64...128),
            heightAdjustment: clamp(heightAdjustment, -12...24)
        )
    }
}

struct DisplayAdjustments: Codable, Equatable {
    var displays: [String: DisplayAdjustment] = [:]

    subscript(_ id: String) -> DisplayAdjustment {
        get { (displays[id] ?? DisplayAdjustment()).normalized }
        set {
            let value = newValue.normalized
            displays[id] = value == DisplayAdjustment() ? nil : value
        }
    }

    static func decode(_ data: Data?) -> Self {
        guard let data, let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        return value
    }

    var encoded: Data { (try? JSONEncoder().encode(self)) ?? Data() }
}

@MainActor
enum DisplayConfiguration {
    static func selectedScreen(for target: DisplayTarget, in screens: [NSScreen] = NSScreen.screens) -> NSScreen? {
        switch target {
        case .builtIn: screens.first(where: isBuiltIn) ?? screens.first
        case .primary: screens.first
        }
    }

    static func id(for screen: NSScreen) -> String {
        if let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
           let uuid = CGDisplayCreateUUIDFromDisplayID(CGDirectDisplayID(number.uint32Value))?.takeRetainedValue() {
            return CFUUIDCreateString(nil, uuid) as String
        }
        return screen.localizedName
    }

    private static func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return false }
        return CGDisplayIsBuiltin(CGDirectDisplayID(number.uint32Value)) != 0
    }
}

struct DisplayAdjustmentView: View {
    let target: DisplayTarget
    @AppStorage(PreferenceKey.displayAdjustments) private var data = Data()
    @State private var screens = NSScreen.screens

    var body: some View {
        if let screen = DisplayConfiguration.selectedScreen(for: target, in: screens) {
            let id = DisplayConfiguration.id(for: screen)
            VStack(alignment: .leading, spacing: 10) {
                Text("보정할 화면: \(screen.localizedName)").font(.caption).foregroundStyle(.secondary)
                adjustmentSlider("가로 위치", id: id, field: \.horizontalOffset, range: -40...40)
                adjustmentSlider("세로 위치", id: id, field: \.verticalOffset, range: -20...40)
                adjustmentSlider("폭 보정", id: id, field: \.widthAdjustment, range: -64...128)
                adjustmentSlider("높이 보정", id: id, field: \.heightAdjustment, range: -12...24)
                Text("위치는 양수일 때 오른쪽·아래쪽으로 이동합니다. 보정값은 화면별로 저장됩니다.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("이 화면 보정 초기화") {
                    var values = DisplayAdjustments.decode(data)
                    values[id] = DisplayAdjustment()
                    data = values.encoded
                }
            }
            .onAppear { screens = NSScreen.screens }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                screens = NSScreen.screens
            }
        }
    }

    private func adjustmentSlider(_ title: String, id: String, field: WritableKeyPath<DisplayAdjustment, Double>, range: ClosedRange<Double>) -> some View {
        let binding = Binding<Double>(
            get: { DisplayAdjustments.decode(data)[id][keyPath: field] },
            set: { value in
                var values = DisplayAdjustments.decode(data)
                var adjustment = values[id]
                adjustment[keyPath: field] = value
                values[id] = adjustment
                data = values.encoded
            }
        )
        return HStack {
            Text(title).frame(width: 62, alignment: .leading)
            Slider(value: binding, in: range, step: 1)
                .accessibilityLabel(title)
            Text(String(format: "%+.0f", binding.wrappedValue)).monospacedDigit().frame(width: 40, alignment: .trailing)
        }
    }
}
