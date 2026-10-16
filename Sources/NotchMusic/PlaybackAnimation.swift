import SwiftUI

enum PlaybackAnimationStyle: String, CaseIterable, Identifiable {
    case bars, wave, dots, ring, nyanCat

    var id: String { rawValue }

    init(storedValue: String) { self = Self(rawValue: storedValue) ?? .bars }

    var title: String {
        switch self {
        case .bars: "막대"
        case .wave: "파동"
        case .dots: "점프하는 점"
        case .ring: "회전 링"
        case .nyanCat: "Nyan Cat"
        }
    }

    var detail: String {
        switch self {
        case .bars: "리듬감 있게 움직이는 막대"
        case .wave: "부드럽게 흐르는 물결"
        case .dots: "번갈아 뛰어오르는 세 점"
        case .ring: "원을 따라 회전하는 빛"
        case .nyanCat: "무지개를 남기며 날아가는 픽셀 고양이"
        }
    }

    var compactWidth: CGFloat { self == .nyanCat ? 30 : 17 }
    var expandedWidth: CGFloat { self == .nyanCat ? 40 : 20 }
    var previewWidth: CGFloat { self == .nyanCat ? 42 : 30 }
}

/// Geometry is shared by the live view and previews, and stays within the supplied bounds.
struct PlaybackAnimationGeometry: Equatable {
    struct Ring: Equatable {
        let center: CGPoint
        let radius: CGFloat
        let angle: Double
    }

    struct Pixel: Equatable {
        let rect: CGRect
        let color: NyanPixelColor
    }

    var bars: [CGRect] = []
    var dots: [CGRect] = []
    var wave: [CGPoint] = []
    var ring: Ring?
    var pixels: [Pixel] = []
    let lineWidth: CGFloat

    init(style: PlaybackAnimationStyle, size: CGSize, time: TimeInterval, isPlaying: Bool, reduceMotion: Bool) {
        let width = size.width.isFinite ? max(0, size.width) : 0
        let height = size.height.isFinite ? max(0, size.height) : 0
        let side = min(width, height)
        lineWidth = min(side / 4, min(2.4, max(1, side * 0.11)))
        guard side > 0 else { return }
        let phase = isPlaying && !reduceMotion && time.isFinite
            ? time.truncatingRemainder(dividingBy: 1.8) * .pi * 2 / 1.8 : 0
        let inset = lineWidth / 2 + min(0.5, side / 20)

        switch style {
        case .bars:
            let available = max(0, width - inset * 2)
            let gap = min(2, available * 0.11)
            let barWidth = max(0, (available - gap * 3) / 4)
            for index in 0..<4 {
                let level = 0.25 + 0.7 * (0.5 + 0.5 * sin(phase * 2 + Double(index) * 1.7))
                let barHeight = max(0, height - inset * 2) * level
                bars.append(CGRect(x: inset + CGFloat(index) * (barWidth + gap), y: (height - barHeight) / 2, width: barWidth, height: barHeight))
            }
        case .wave:
            for index in 0...24 {
                let fraction = Double(index) / 24
                let envelope = sin(fraction * .pi)
                let offset = sin(fraction * .pi * 4 - phase * 2) * envelope
                wave.append(CGPoint(x: inset + (width - inset * 2) * fraction, y: height / 2 + (height - inset * 2) * 0.32 * offset))
            }
        case .dots:
            let diameter = side * 0.22
            let gap = side * 0.12
            let start = (width - diameter * 3 - gap * 2) / 2
            for index in 0..<3 {
                let bounce = max(0, sin(phase * 2 - Double(index) * 0.85))
                dots.append(CGRect(x: start + CGFloat(index) * (diameter + gap), y: (height - diameter) / 2 - side * 0.22 * bounce, width: diameter, height: diameter))
            }
        case .ring:
            ring = Ring(center: CGPoint(x: width / 2, y: height / 2), radius: side * 0.34, angle: phase - .pi / 2)
        case .nyanCat:
            let unit = min(width / 32, height / 18)
            let origin = CGPoint(x: (width - unit * 32) / 2, y: (height - unit * 18) / 2)
            let bob = sin(phase * 2) > 0 ? 1 : 0
            let stride = abs(Int(floor(phase / (.pi / 2)))) % 2
            func pixel(_ x: Int, _ y: Int, _ color: NyanPixelColor) -> Pixel {
                Pixel(rect: CGRect(x: origin.x + CGFloat(x) * unit, y: origin.y + CGFloat(y) * unit, width: unit, height: unit), color: color)
            }
            func sprite(_ rows: [String], x: Int, y: Int) -> [Pixel] {
                rows.enumerated().flatMap { row, line in
                    line.enumerated().compactMap { column, symbol in
                        NyanPixelColor(rawValue: String(symbol)).map { pixel(x + column, y + row + bob, $0) }
                    }
                }
            }
            let rainbow: [NyanPixelColor] = [.red, .orange, .yellow, .green, .blue, .purple]
            for column in 0..<14 {
                let ripple = Int((sin(phase * 2 - Double(column) * 0.55) * 0.8).rounded())
                for (row, color) in rainbow.enumerated() { pixels.append(pixel(column, 6 + row + ripple, color)) }
            }
            pixels += sprite(["K....", "KGK..", ".KGKK", "..KGK"], x: 9, y: 7)
            for (index, x) in [14, 19, 27].enumerated() {
                let step = (index + stride) % 2
                pixels += sprite(["KGK", "KK."], x: x - step, y: 12 + step)
            }
            pixels += sprite([
                ".KKKKKKKKK.", "KTTTTTTTTTK", "KTPPPPPPPTK",
                "KTPPSPPPPTK", "KTPPPPSPPTK", "KTPPSPPPPTK",
                "KTPPPPPPPTK", "KTTTTTTTTTK", ".KKKKKKKKK."
            ], x: 13, y: 3)
            pixels += sprite([
                ".K.....K.", "KGGK.KGGK", "KGGGGGGGK", "KGGGGGGGK",
                "KGKGGGKGK", "KCGGGGGCK", ".KGGKGGK.", "..KKKKK.."
            ], x: 23, y: 4)
        }
    }
}

enum NyanPixelColor: String {
    case outline = "K", crust = "T", pastry = "P", sprinkle = "S", fur = "G", cheek = "C"
    case red = "r", orange = "o", yellow = "y", green = "g", blue = "b", purple = "v"

    var color: Color {
        switch self {
        case .outline: Color(red: 0.08, green: 0.07, blue: 0.12)
        case .crust: Color(red: 0.96, green: 0.78, blue: 0.58)
        case .pastry: Color(red: 0.98, green: 0.64, blue: 0.77)
        case .sprinkle: Color(red: 0.88, green: 0.25, blue: 0.52)
        case .fur: Color(red: 0.64, green: 0.67, blue: 0.72)
        case .cheek: Color(red: 1, green: 0.45, blue: 0.6)
        case .red: Color(red: 1, green: 0.30, blue: 0.38)
        case .orange: Color(red: 1, green: 0.64, blue: 0.22)
        case .yellow: Color(red: 1, green: 0.88, blue: 0.30)
        case .green: Color(red: 0.40, green: 0.90, blue: 0.35)
        case .blue: Color(red: 0.30, green: 0.74, blue: 1)
        case .purple: Color(red: 0.68, green: 0.42, blue: 1)
        }
    }
}

struct PlaybackAnimationFrame: View {
    let style: PlaybackAnimationStyle
    let color: Color
    let time: TimeInterval
    let isPlaying: Bool
    let reduceMotion: Bool

    var body: some View {
        Canvas { context, size in
            let geometry = PlaybackAnimationGeometry(style: style, size: size, time: time, isPlaying: isPlaying, reduceMotion: reduceMotion)
            for pixel in geometry.pixels {
                context.fill(Path(pixel.rect), with: .color(pixel.color.color), style: FillStyle(antialiased: false))
            }
            for bar in geometry.bars {
                context.fill(Path(roundedRect: bar, cornerRadius: bar.width / 2), with: .color(color))
            }
            for dot in geometry.dots { context.fill(Path(ellipseIn: dot), with: .color(color)) }
            if let first = geometry.wave.first {
                var path = Path()
                path.move(to: first)
                path.addLines(Array(geometry.wave.dropFirst()))
                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: geometry.lineWidth, lineCap: .round, lineJoin: .round))
            }
            if let ring = geometry.ring {
                let rect = CGRect(x: ring.center.x - ring.radius, y: ring.center.y - ring.radius, width: ring.radius * 2, height: ring.radius * 2)
                context.stroke(Path(ellipseIn: rect), with: .color(color.opacity(0.18)), lineWidth: geometry.lineWidth)
                var arc = Path()
                arc.addArc(center: ring.center, radius: ring.radius, startAngle: .radians(ring.angle), endAngle: .radians(ring.angle + .pi * 1.4), clockwise: false)
                context.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: geometry.lineWidth, lineCap: .round))
            }
        }
    }
}

struct PlaybackIndicatorView: View {
    let style: PlaybackAnimationStyle
    let color: Color
    let isPlaying: Bool
    let reduceMotion: Bool
    var isVisible = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !isPlaying || reduceMotion || !isVisible)) { context in
            PlaybackAnimationFrame(style: style, color: color, time: context.date.timeIntervalSinceReferenceDate, isPlaying: isPlaying, reduceMotion: reduceMotion)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("재생 애니메이션: \(style.title)")
        .accessibilityValue(isPlaying ? "재생 중" : "일시정지")
        .accessibilityHidden(!isVisible)
    }
}

struct PlaybackAnimationPicker: View {
    @Binding var selection: String
    let color: Color
    let reduceMotion: Bool
    let isEnabled: Bool

    private var selectedStyle: PlaybackAnimationStyle { .init(storedValue: selection) }

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(PlaybackAnimationStyle.allCases) { style in
                let selected = selectedStyle == style
                Button {
                    selection = style.rawValue
                } label: {
                    HStack(spacing: 10) {
                        PlaybackIndicatorView(style: style, color: color, isPlaying: selected && isEnabled, reduceMotion: reduceMotion)
                            .frame(width: style.previewWidth, height: 30)
                        Text(style.title).font(.system(size: 12, weight: .semibold))
                        Spacer(minLength: 0)
                        if selected {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(color)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selected ? color.opacity(0.12) : Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12).stroke(selected ? color.opacity(0.7) : Color.primary.opacity(0.08), lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .accessibilityLabel(style.title)
                .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
                .accessibilityHint(style.detail)
            }
        }
        .opacity(isEnabled ? 1 : 0.45)
        Text(reduceMotion ? "움직임 줄이기가 켜져 있어 정지된 모양으로 표시합니다." : "선택한 애니메이션을 미리 볼 수 있습니다. 노치와 펼친 플레이어에 바로 적용됩니다.")
            .font(.caption).foregroundStyle(.secondary)
    }
}
