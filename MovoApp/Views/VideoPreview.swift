@preconcurrency import AVFoundation
import AppKit
import SwiftUI

struct SilentLoopingVideo: NSViewRepresentable {
    let url: URL
    let isPlaying: Bool
    let videoGravity: AVLayerVideoGravity

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PlayerSurface {
        let view = PlayerSurface()
        view.playerLayer.videoGravity = videoGravity
        context.coordinator.load(url: url, into: view, isPlaying: isPlaying)
        return view
    }

    func updateNSView(_ view: PlayerSurface, context: Context) {
        view.playerLayer.videoGravity = videoGravity
        if context.coordinator.url != url {
            context.coordinator.load(url: url, into: view, isPlaying: isPlaying)
        } else {
            isPlaying ? context.coordinator.player?.play() : context.coordinator.player?.pause()
        }
    }

    static func dismantleNSView(_ view: PlayerSurface, coordinator: Coordinator) {
        coordinator.player?.pause()
        view.playerLayer.player = nil
    }

    final class Coordinator {
        var url: URL?
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?

        @MainActor
        func load(url: URL, into view: PlayerSurface, isPlaying: Bool) {
            self.url = url
            player?.pause()
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            player.actionAtItemEnd = .none
            looper = AVPlayerLooper(player: player, templateItem: item)
            self.player = player
            view.playerLayer.player = player
            isPlaying ? player.play() : player.pause()
        }
    }
}

final class PlayerSurface: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.addSublayer(playerLayer)
        playerLayer.backgroundColor = NSColor.black.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}

struct VideoThumbnail: View {
    let url: URL
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            Rectangle().fill(MovoTheme.graphiteSurface)
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "film")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(MovoTheme.tertiaryText)
            }
        }
        .clipped()
        .task(id: url) { image = await Self.generate(url: url) }
    }

    private static func generate(url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)
        do {
            let (cgImage, _) = try await generator.image(at: CMTime(seconds: 0.15, preferredTimescale: 600))
            return NSImage(cgImage: cgImage, size: .zero)
        } catch {
            return nil
        }
    }
}
