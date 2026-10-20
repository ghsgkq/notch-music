import SwiftUI

struct NotchView: View {
    @ObservedObject var player: NowPlayingController
    let layout: NotchLayout
    @AppStorage(PreferenceKey.showArtwork) private var showArtwork = true
    @AppStorage(PreferenceKey.showProgress) private var showProgress = true
    @AppStorage(PreferenceKey.showEqualizer) private var showEqualizer = true
    @AppStorage(PreferenceKey.playbackAnimation) private var playbackAnimation = PlaybackAnimationStyle.bars.rawValue
    @AppStorage(PreferenceKey.hoverHighlight) private var hoverHighlight = true
    @AppStorage(PreferenceKey.hoverToExpand) private var hoverToExpand = true
    @AppStorage(PreferenceKey.reduceMotion) private var reduceMotion = false
    @AppStorage(PreferenceKey.accent) private var accentName = AccentChoice.green.rawValue
    @AppStorage(PreferenceKey.artworkAccent) private var artworkAccent = true
    @AppStorage(PreferenceKey.liquidGlass) private var liquidGlass = true
    @AppStorage(PreferenceKey.dynamicCompactReveal) private var dynamicCompactReveal = true
    @State private var hovering = false

    private var accentColor: Color {
        if artworkAccent, let color = player.artworkAccent {
            return Color(nsColor: color)
        }
        return AccentChoice(rawValue: accentName)?.color ?? .green
    }

    private var showsLiquidGlass: Bool {
        liquidGlass && player.isExpanded
    }

    private var revealsCompactActivity: Bool {
        !dynamicCompactReveal || player.hasActiveTrack
    }

    private var expansionAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.08) : .spring(response: 0.4, dampingFraction: 0.84)
    }

    private var animationStyle: PlaybackAnimationStyle { .init(storedValue: playbackAnimation) }

    var body: some View {
        ZStack(alignment: .top) {
            island
        }
        .frame(width: layout.canvasSize.width, height: layout.canvasSize.height, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .ignoresSafeArea()
    }

    private var island: some View {
        VStack(spacing: 0) {
            compactHeader
            expandedPlayer
                .opacity(player.isExpanded ? 1 : 0)
                .offset(y: player.isExpanded ? 0 : -10)
                .allowsHitTesting(player.isExpanded)
        }
        .frame(
            width: player.isExpanded ? layout.expandedSize.width : (revealsCompactActivity ? layout.compactSize.width : layout.idleSize.width),
            height: player.isExpanded ? layout.expandedSize.height : layout.compactSize.height,
            alignment: .top
        )
        .background {
            ZStack {
                LiquidGlassBackdrop(accentColor: accentColor)
                    .opacity(showsLiquidGlass ? 1 : 0)
                Color.black.opacity(showsLiquidGlass ? 0.72 : 1)
                LinearGradient(
                    colors: [Color.white.opacity(player.isExpanded ? (showsLiquidGlass ? 0.12 : 0.055) : 0), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                RadialGradient(
                    colors: [accentColor.opacity(player.isExpanded ? 0.12 : 0), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 210
                )
                LinearGradient(
                    colors: [.white.opacity(0.075), .clear, accentColor.opacity(0.055)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(hovering && hoverHighlight && revealsCompactActivity ? 1 : 0)
            }
        }
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: layout.isFloating ? (player.isExpanded ? 26 : compactCornerRadius) : 0,
            bottomLeadingRadius: player.isExpanded ? 26 : compactCornerRadius,
            bottomTrailingRadius: player.isExpanded ? 26 : compactCornerRadius,
            topTrailingRadius: layout.isFloating ? (player.isExpanded ? 26 : compactCornerRadius) : 0
        ))
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(hovering ? Color.white.opacity(0.68) : Color.white.opacity(0.16))
                .frame(width: hovering ? 42 : 26, height: 3)
                .padding(.bottom, player.isExpanded ? 6 : 4)
                .animation(reduceMotion ? .easeOut(duration: 0.08) : .spring(response: 0.28, dampingFraction: 0.78), value: hovering)
                .opacity(revealsCompactActivity || player.isExpanded ? 1 : 0)
        }
        .shadow(
            color: .black.opacity(player.isExpanded ? 0.38 : (revealsCompactActivity ? 0.18 : 0)),
            radius: player.isExpanded ? 18 : 8,
            y: 7
        )
        .onHover {
            hovering = $0
            player.updateHover($0, enabled: hoverToExpand)
        }
        .onChange(of: hoverToExpand) { _, enabled in
            player.updateHover(hovering, enabled: enabled)
        }
        .onDisappear { player.updateHover(false, enabled: false) }
        .animation(.easeOut(duration: 0.18), value: hovering)
        .animation(expansionAnimation, value: player.isExpanded)
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.48, dampingFraction: 0.78),
            value: revealsCompactActivity
        )
    }

    private var compactCornerRadius: CGFloat {
        min(20, layout.compactSize.height / 2)
    }

    private var compactArtworkSize: CGFloat {
        min(28, max(0, layout.compactSize.height - 8))
    }

    private var compactHeader: some View {
        Group {
            if layout.isFloating {
                externalCompactHeader
            } else {
                notchCompactHeader
            }
        }
        .frame(height: layout.compactSize.height)
        .contentShape(Rectangle())
        .onTapGesture {
            player.toggleExpanded()
        }
    }

    private var notchCompactHeader: some View {
        HStack(spacing: 0) {
            MiniArtwork(
                data: showArtwork ? player.track.artwork : nil,
                isPlaying: player.isPlaying,
                accentColor: accentColor,
                size: compactArtworkSize
            )
                .frame(width: 46, alignment: .leading)
                .opacity(revealsCompactActivity ? 1 : 0)
                .scaleEffect(revealsCompactActivity ? 1 : 0.68)
                .offset(x: revealsCompactActivity ? 0 : 22)

            Spacer().frame(width: layout.notchWidth)

            Group {
                if player.isPlaying {
                    HStack(spacing: 5) {
                        Circle().fill(accentColor).frame(width: 5, height: 5)
                        PlaybackIndicatorView(style: animationStyle, color: accentColor, isPlaying: player.isPlaying, reduceMotion: reduceMotion, isVisible: showEqualizer && revealsCompactActivity)
                            .frame(width: animationStyle.compactWidth, height: 18)
                            .opacity(showEqualizer ? 1 : 0)
                    }
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .scaleEffect(min(1, layout.compactSize.height / 40))
            .frame(width: 46, alignment: .trailing)
            .opacity(revealsCompactActivity ? 1 : 0)
            .scaleEffect(revealsCompactActivity ? 1 : 0.68)
            .offset(x: revealsCompactActivity ? 0 : -22)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
    }

    private var externalCompactHeader: some View {
        HStack(spacing: 10) {
            MiniArtwork(
                data: showArtwork ? player.track.artwork : nil,
                isPlaying: player.isPlaying,
                accentColor: accentColor
            )

            VStack(alignment: .leading, spacing: 1) {
                Text(player.track.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(player.track.artist)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 5) {
                Circle()
                    .fill(player.isPlaying ? accentColor : .white.opacity(0.35))
                    .frame(width: 5, height: 5)
                PlaybackIndicatorView(style: animationStyle, color: accentColor, isPlaying: player.isPlaying, reduceMotion: reduceMotion, isVisible: showEqualizer && revealsCompactActivity)
                    .frame(width: animationStyle.compactWidth, height: 18)
                    .opacity(showEqualizer && player.isPlaying ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .opacity(revealsCompactActivity ? 1 : 0)
        .scaleEffect(revealsCompactActivity ? 1 : 0.82)
    }

    private var expandedPlayer: some View {
        VStack(spacing: 6) {
            HStack(spacing: 16) {
                ArtworkView(data: showArtwork ? player.track.artwork : nil, accentColor: accentColor)
                    .scaleEffect(player.isExpanded ? 1 : 0.72, anchor: .topLeading)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Circle().fill(accentColor).frame(width: 5, height: 5)
                        Text(player.isPlaying ? "지금 재생 중" : "일시 정지")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.4)
                    }
                    .foregroundStyle(accentColor)

                    Text(player.track.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(player.track.artist)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PlaybackIndicatorView(style: animationStyle, color: accentColor, isPlaying: player.isPlaying, reduceMotion: reduceMotion, isVisible: showEqualizer && player.isExpanded)
                    .frame(width: animationStyle.expandedWidth, height: 24)
                    .opacity(showEqualizer ? (player.isPlaying ? 1 : 0.25) : 0)
            }

            ProgressScrubber(
                player: player,
                accentColor: accentColor,
                isVisible: showProgress,
                liquidGlass: showsLiquidGlass
            )

            HStack(spacing: 34) {
                secondaryControl("backward.fill", action: player.previous)
                primaryControl(player.isPlaying ? "pause.fill" : "play.fill", action: player.playPause)
                secondaryControl("forward.fill", action: player.next)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .frame(height: 172)
    }

    private func secondaryControl(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 44, height: 40)
                .contentShape(Circle())
        }
        .buttonStyle(PlayerControlStyle())
        .foregroundStyle(.white.opacity(0.9))
        .accessibilityLabel(symbol == "backward.fill" ? "이전 곡" : "다음 곡")
        .modifier(GlassControlModifier(enabled: showsLiquidGlass, accentColor: accentColor))
    }

    private func primaryControl(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 40)
                .background(Color.white.opacity(showsLiquidGlass ? 0.12 : 0.08))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PlayerControlStyle())
        .accessibilityLabel(player.isPlaying ? "일시 정지" : "재생")
        .modifier(GlassControlModifier(enabled: showsLiquidGlass, accentColor: accentColor))
    }
}

private struct PlayerControlStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ProgressScrubber: View {
    @ObservedObject var player: NowPlayingController
    let accentColor: Color
    let isVisible: Bool
    let liquidGlass: Bool
    @State private var scrubProgress: Double?
    @State private var hovering = false
    @AppStorage(PreferenceKey.reduceMotion) private var reduceMotion = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let progress = scrubProgress ?? player.progress(at: context.date)
            let elapsed = player.duration * progress
            VStack(spacing: 2) {
                GeometryReader { proxy in
                    let width = max(1, proxy.size.width)
                    FlowingProgressTrack(
                        progress: progress,
                        accentColor: accentColor,
                        isAnimating: player.isPlaying && player.isExpanded && isVisible && !reduceMotion,
                        isSeeking: scrubProgress != nil || hovering,
                        hasDuration: player.duration > 0,
                        liquidGlass: liquidGlass
                    )
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard isVisible, player.duration > 0 else { return }
                                scrubProgress = min(1, max(0, value.location.x / width))
                            }
                            .onEnded { value in
                                guard isVisible, player.duration > 0 else { return }
                                player.seek(toProgress: min(1, max(0, value.location.x / width)))
                                scrubProgress = nil
                            }
                    )
                    .onHover { hovering = $0 }
                    .animation(.easeOut(duration: 0.15), value: hovering)
                    .animation(.easeOut(duration: 0.15), value: scrubProgress != nil)
                    .accessibilityElement()
                    .accessibilityLabel("재생 위치")
                    .accessibilityValue("\(Self.timeString(elapsed)) / \(Self.timeString(player.duration))")
                    .accessibilityAdjustableAction { direction in
                        guard player.duration > 0 else { return }
                        switch direction {
                        case .increment: player.seek(toProgress: min(1, progress + 5 / player.duration))
                        case .decrement: player.seek(toProgress: max(0, progress - 5 / player.duration))
                        @unknown default: break
                        }
                    }
                }
                .frame(height: 14)

                HStack {
                    Text(player.duration > 0 ? Self.timeString(elapsed) : "–:––")
                    Spacer()
                    Text(player.duration > 0 ? "−" + Self.timeString(player.duration - elapsed) : "–:––")
                }
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.42))
            }
        }
        .frame(height: 28)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible && player.duration > 0)
    }

    private static func timeString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

/// Decorative flowing waves; now-playing metadata does not expose audio samples.
private struct FlowingProgressTrack: View {
    let progress: Double
    let accentColor: Color
    let isAnimating: Bool
    let isSeeking: Bool
    let hasDuration: Bool
    let liquidGlass: Bool
    @State private var accumulatedTime: TimeInterval = 0
    @State private var startedAt: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !isAnimating)) { timeline in
            let time = accumulatedTime + (startedAt.map { timeline.date.timeIntervalSince($0) } ?? 0)
            GeometryReader { geometry in
                let width = geometry.size.width
                let end = max(0, min(width, width * progress))
                let baseline = geometry.size.height - 4
                ZStack(alignment: .topLeading) {
                    Canvas { context, size in
                        let colors: [Color] = [.blue, .purple, .pink, accentColor]
                        // Each layer travels at a different speed, rising softly above the played section.
                        if end > 0 {
                            for layer in 0..<4 {
                                var wave = Path()
                                wave.move(to: CGPoint(x: 0, y: baseline))
                                let samples = max(2, Int(end / 2))
                                for sample in 0...samples {
                                    let fraction = Double(sample) / Double(samples)
                                    let x = end * fraction
                                    let phase = time * (0.9 + Double(layer) * 0.21) + Double(layer) * 1.8
                                    let envelope = pow(sin(.pi * fraction), 0.8)
                                    let swell = (sin(fraction * .pi * 3.5 - phase) + 1) / 2
                                    let ripple = (sin(fraction * .pi * 7 + phase * 0.7) + 1) / 2
                                    let amplitude = (isSeeking ? 1.0 : 0.82) * (0.2 + 0.65 * swell + 0.15 * ripple)
                                    let y = baseline - (size.height - 4) * envelope * amplitude
                                    wave.addLine(to: CGPoint(x: x, y: y))
                                }
                                wave.addLine(to: CGPoint(x: end, y: baseline))
                                wave.closeSubpath()
                                context.fill(wave, with: .linearGradient(
                                    Gradient(colors: [colors[layer].opacity(0.8), colors[layer].opacity(0.35)]),
                                    startPoint: .zero,
                                    endPoint: CGPoint(x: end, y: baseline)
                                ))
                            }
                        }
                        let remainingStart = min(width, end + (hasDuration ? 7 : 0))
                        let remaining = CGRect(x: remainingStart, y: baseline - 1.5, width: max(0, width - remainingStart), height: 3)
                        context.fill(Path(roundedRect: remaining, cornerRadius: 1.5), with: .color(.white.opacity(liquidGlass ? 0.28 : 0.2)))
                        let played = CGRect(x: 0, y: baseline - 1.5, width: max(0, end - 5), height: 3)
                        context.fill(Path(roundedRect: played, cornerRadius: 1.5), with: .linearGradient(
                            Gradient(colors: [.white.opacity(0.4), .white]),
                            startPoint: .zero, endPoint: CGPoint(x: end, y: baseline)
                        ))
                    }
                    if hasDuration {
                        Circle()
                            .fill(accentColor)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 1.8))
                            .frame(width: isSeeking ? 12 : 10, height: isSeeking ? 12 : 10)
                            .shadow(color: accentColor.opacity(0.8), radius: isSeeking ? 7 : 4)
                            .position(x: min(max(6, end), max(6, width - 6)), y: baseline)
                    }
                }
            }
        }
        .onAppear { updateClock(isAnimating) }
        .onChange(of: isAnimating) { _, active in updateClock(active) }
        .onDisappear { updateClock(false) }
    }

    private func updateClock(_ active: Bool) {
        if active {
            if startedAt == nil { startedAt = .now }
        } else if let startedAt {
            accumulatedTime += Date.now.timeIntervalSince(startedAt)
            self.startedAt = nil
        }
    }
}

private struct LiquidGlassBackdrop: View {
    let accentColor: Color

    @ViewBuilder
    var body: some View {
        if #available(macOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.tint(accentColor.opacity(0.12)), in: Rectangle())
        } else {
            Rectangle().fill(.ultraThinMaterial)
        }
    }
}

private struct GlassControlModifier: ViewModifier {
    let enabled: Bool
    let accentColor: Color

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            if #available(macOS 26.0, *) {
                content.glassEffect(.regular.tint(accentColor.opacity(0.1)).interactive(), in: Circle())
            } else {
                content.background(.ultraThinMaterial, in: Circle())
            }
        } else {
            content
        }
    }
}

private struct ArtworkView: View {
    let data: Data?
    let accentColor: Color
    var body: some View {
        Group {
            if let data, let image = NSImage(data: data) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 68, height: 68)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(colors: [accentColor.opacity(0.85), accentColor.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note").font(.title).foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 68, height: 68)
            }
        }
        .frame(width: 68, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct MiniArtwork: View {
    let data: Data?
    let isPlaying: Bool
    let accentColor: Color
    var size: CGFloat = 28

    var body: some View {
        Group {
            if let data, let image = NSImage(data: data) {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    LinearGradient(colors: [accentColor.opacity(0.9), accentColor.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(isPlaying ? accentColor.opacity(0.55) : .white.opacity(0.12), lineWidth: 1)
        }
    }
}
