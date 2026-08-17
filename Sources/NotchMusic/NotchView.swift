import SwiftUI

struct NotchView: View {
    @ObservedObject var player: NowPlayingController
    let notchWidth: CGFloat
    let idleCompactWidth: CGFloat
    let compactWidth: CGFloat
    let expandedWidth: CGFloat
    let canvasSize: NSSize
    let usesExternalDisplayStyle: Bool
    @AppStorage(PreferenceKey.showArtwork) private var showArtwork = true
    @AppStorage(PreferenceKey.showProgress) private var showProgress = true
    @AppStorage(PreferenceKey.showEqualizer) private var showEqualizer = true
    @AppStorage(PreferenceKey.hoverHighlight) private var hoverHighlight = true
    @AppStorage(PreferenceKey.reduceMotion) private var reduceMotion = false
    @AppStorage(PreferenceKey.accent) private var accentName = AccentChoice.green.rawValue
    @AppStorage(PreferenceKey.liquidGlass) private var liquidGlass = true
    @AppStorage(PreferenceKey.dynamicCompactReveal) private var dynamicCompactReveal = true
    @State private var hovering = false

    private var accentColor: Color {
        AccentChoice(rawValue: accentName)?.color ?? .green
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

    var body: some View {
        ZStack(alignment: .top) {
            island
        }
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .top)
        .background(Color.clear)
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
            width: player.isExpanded ? expandedWidth : (revealsCompactActivity ? compactWidth : idleCompactWidth),
            height: player.isExpanded ? canvasSize.height : 40,
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
            topLeadingRadius: usesExternalDisplayStyle ? (player.isExpanded ? 26 : 20) : 0,
            bottomLeadingRadius: player.isExpanded ? 26 : 20,
            bottomTrailingRadius: player.isExpanded ? 26 : 20,
            topTrailingRadius: usesExternalDisplayStyle ? (player.isExpanded ? 26 : 20) : 0
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
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.18), value: hovering)
        .animation(expansionAnimation, value: player.isExpanded)
        .animation(
            reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.48, dampingFraction: 0.78),
            value: revealsCompactActivity
        )
    }

    private var compactHeader: some View {
        Group {
            if usesExternalDisplayStyle {
                externalCompactHeader
            } else {
                notchCompactHeader
            }
        }
        .frame(height: 40)
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
                accentColor: accentColor
            )
                .frame(width: 46, alignment: .leading)
                .opacity(revealsCompactActivity ? 1 : 0)
                .scaleEffect(revealsCompactActivity ? 1 : 0.68)
                .offset(x: revealsCompactActivity ? 0 : 22)

            Spacer().frame(width: notchWidth)

            Group {
                if player.isPlaying {
                    HStack(spacing: 5) {
                        Circle().fill(accentColor).frame(width: 5, height: 5)
                        EqualizerView(color: accentColor, reduceMotion: reduceMotion)
                            .frame(width: 17, height: 18)
                            .opacity(showEqualizer ? 1 : 0)
                    }
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
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
                EqualizerView(color: accentColor, reduceMotion: reduceMotion)
                    .frame(width: 17, height: 18)
                    .opacity(showEqualizer && player.isPlaying ? 1 : 0)
            }
        }
        .padding(.horizontal, 10)
        .opacity(revealsCompactActivity ? 1 : 0)
        .scaleEffect(revealsCompactActivity ? 1 : 0.82)
    }

    private var expandedPlayer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 14) {
                ArtworkView(data: showArtwork ? player.track.artwork : nil, accentColor: accentColor)
                    .scaleEffect(player.isExpanded ? 1 : 0.72, anchor: .topLeading)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Circle().fill(accentColor).frame(width: 5, height: 5)
                        Text("NOW PLAYING")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .tracking(0.8)
                    }
                    .foregroundStyle(accentColor)

                    Text(player.track.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(player.track.artist)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                EqualizerView(color: accentColor, reduceMotion: reduceMotion)
                    .frame(width: 20, height: 24)
                    .opacity(showEqualizer ? (player.isPlaying ? 1 : 0.25) : 0)
            }

            ProgressScrubber(
                player: player,
                accentColor: accentColor,
                isVisible: showProgress,
                liquidGlass: showsLiquidGlass
            )

            HStack(spacing: 28) {
                secondaryControl("backward.fill", action: player.previous)
                primaryControl(player.isPlaying ? "pause.fill" : "play.fill", action: player.playPause)
                secondaryControl("forward.fill", action: player.next)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 7)
        .padding(.bottom, 17)
        .frame(height: 172)
    }

    private func secondaryControl(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 30, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.82))
        .modifier(GlassControlModifier(enabled: showsLiquidGlass, accentColor: accentColor))
    }

    private func primaryControl(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(showsLiquidGlass ? .white : .black)
                .frame(width: 34, height: 34)
                .background(showsLiquidGlass ? Color.white.opacity(0.14) : .white)
                .clipShape(Circle())
                .shadow(color: .white.opacity(0.12), radius: 8)
        }
        .buttonStyle(.plain)
        .modifier(GlassControlModifier(enabled: showsLiquidGlass, accentColor: accentColor))
    }
}

private struct ProgressScrubber: View {
    @ObservedObject var player: NowPlayingController
    let accentColor: Color
    let isVisible: Bool
    let liquidGlass: Bool
    @State private var scrubProgress: Double?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            GeometryReader { proxy in
                let width = max(1, proxy.size.width)
                let progress = scrubProgress ?? player.progress(at: context.date)

                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(liquidGlass ? 0.16 : 0.1))
                        .frame(height: 3)
                    Capsule()
                        .fill(LinearGradient(colors: [accentColor, accentColor.opacity(0.55)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: width * progress, height: 3)

                    Circle()
                        .fill(.white)
                        .frame(width: scrubProgress == nil ? 0 : 8, height: scrubProgress == nil ? 0 : 8)
                        .offset(x: max(0, min(width - 8, width * progress - 4)))
                        .shadow(color: accentColor.opacity(0.65), radius: 5)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .overlay(alignment: .topLeading) {
                    if let scrubProgress {
                        Text(Self.timeString(player.duration * scrubProgress))
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.8), in: Capsule())
                            .offset(x: max(0, min(width - 42, width * scrubProgress - 21)), y: -17)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard isVisible, player.duration > 0 else { return }
                            scrubProgress = min(1, max(0, value.location.x / width))
                        }
                        .onEnded { value in
                            guard isVisible, player.duration > 0 else { return }
                            let progress = min(1, max(0, value.location.x / width))
                            scrubProgress = nil
                            player.seek(toProgress: progress)
                        }
                )
            }
        }
        .frame(height: 14)
        .opacity(isVisible ? 1 : 0)
        .allowsHitTesting(isVisible && player.duration > 0)
    }

    private static func timeString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
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
                    .frame(width: 82, height: 82)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(colors: [accentColor.opacity(0.85), accentColor.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image(systemName: "music.note").font(.title).foregroundStyle(.white.opacity(0.85))
                }
                .frame(width: 82, height: 82)
            }
        }
        .frame(width: 82, height: 82)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct MiniArtwork: View {
    let data: Data?
    let isPlaying: Bool
    let accentColor: Color

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
        .frame(width: 28, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(isPlaying ? accentColor.opacity(0.55) : .white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct EqualizerView: View {
    let color: Color
    let reduceMotion: Bool
    @State private var active = false

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(color)
                    .frame(width: 2.5, height: active ? CGFloat([7, 15, 11, 17][index]) : CGFloat([7, 11, 8, 13][index]))
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.32).repeatForever(autoreverses: true).delay(Double(index) * 0.08),
                        value: active
                    )
            }
        }
        .onAppear { active = !reduceMotion }
        .onChange(of: reduceMotion) { _, newValue in
            active = !newValue
        }
    }
}
