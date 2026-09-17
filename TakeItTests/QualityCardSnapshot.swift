import SwiftUI
import Testing
import UIKit
@testable import TakeIt

@MainActor
struct QualityCardSnapshot {
    @Test func renderCards() throws {
        let video = MediaItem(
            type: .video,
            url: "https://video.twimg.com/768.mp4",
            filename: "twitter-video-1.mp4",
            qualities: [
                VideoQuality(url: "https://video.twimg.com/768.mp4", label: "768p", height: 768),
                VideoQuality(url: "https://video.twimg.com/480.mp4", label: "480p", height: 480),
                VideoQuality(url: "https://video.twimg.com/360.mp4", label: "360p", height: 360),
            ]
        )
        let image = MediaItem(type: .image, url: "https://cdn.example.com/a.jpg", filename: "twitter-1.jpg")

        let content = VStack(spacing: 16) {
            MediaCardView(item: video)
            MediaCardView(item: image)
        }
        .padding(20)
        .background(Theme.bg)
        .environment(DownloadManager())

        let host = UIHostingController(rootView: content)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
        let window = UIWindow(frame: host.view.frame)
        window.rootViewController = host
        window.isHidden = false
        window.layoutIfNeeded()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()

        let renderer = UIGraphicsImageRenderer(bounds: host.view.bounds)
        let png = renderer.pngData { _ in
            host.view.drawHierarchy(in: host.view.bounds, afterScreenUpdates: true)
        }
        Attachment.record(png, named: "takeit-card.png")
    }
}
