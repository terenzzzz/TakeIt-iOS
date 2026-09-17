import AVKit
import SwiftUI

struct MediaCardView: View {
    let item: MediaItem
    @Environment(DownloadManager.self) private var downloader
    @State private var selectedQualityURL: String?

    private var qualityOptions: [VideoQuality] {
        item.qualityOptions
    }

    private var selectedQuality: VideoQuality? {
        guard !qualityOptions.isEmpty else { return nil }
        if let selectedQualityURL,
           let match = qualityOptions.first(where: { $0.url == selectedQualityURL }) {
            return match
        }
        return qualityOptions.first
    }

    private var activeURL: String {
        item.downloadURL(for: selectedQuality)
    }

    private var activeFilename: String {
        item.filename(for: selectedQuality)
    }

    private var previewURL: URL {
        APIClient.shared.previewURL(for: activeURL, filename: activeFilename)
    }

    private var thumbnailURL: URL {
        if let thumbnail = item.thumbnail, !thumbnail.isEmpty {
            return APIClient.shared.previewURL(for: thumbnail, filename: item.displayName)
        }
        return previewURL
    }

    private var downloading: Bool {
        downloader.isDownloading(item)
    }

    private var downloadFraction: Double? {
        downloader.fraction(for: item)
    }

    private var downloadButtonTitle: String {
        if downloading, let downloadFraction, downloadFraction > 0 {
            return DownloadProgressBar.percentText(downloadFraction)
        }
        return downloading ? "下载中" : "下载"
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Theme.previewBg
                preview
                typeTag
                    .padding(10)
                if downloading {
                    VStack {
                        Spacer()
                        DownloadProgressBar(fraction: downloadFraction)
                    }
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipped()

            VStack(alignment: .leading, spacing: 12) {
                Text(item.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    if qualityOptions.count > 1 {
                        qualityPicker
                    }
                    downloadButton
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surface)
        }
        .background(Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
        .contextMenu {
            Button {
                Task { await downloader.download(item, quality: selectedQuality) }
            } label: {
                Label("下载", systemImage: "arrow.down.to.line")
            }
            if let shareURL = URL(string: activeURL) {
                ShareLink(item: shareURL) {
                    Label("分享原链接", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var qualityPicker: some View {
        Menu {
            ForEach(qualityOptions) { quality in
                Button {
                    selectedQualityURL = quality.url
                } label: {
                    if quality.url == activeURL {
                        Label(quality.displayLabel, systemImage: "checkmark")
                    } else {
                        Text(quality.displayLabel)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text("清晰度")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                Text(selectedQuality?.displayLabel ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
        }
        .menuOrder(.fixed)
        .buttonStyle(.plain)
        .disabled(downloading)
        .accessibilityLabel("选择视频清晰度")
    }

    private var downloadButton: some View {
        Button {
            Task { await downloader.download(item, quality: selectedQuality) }
        } label: {
            HStack(spacing: 6) {
                if downloading {
                    if downloadFraction == nil {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(Theme.primaryText)
                    }
                } else {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(downloadButtonTitle)
                    .monospacedDigit()
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .frame(minWidth: qualityOptions.count > 1 ? 104 : nil, maxWidth: qualityOptions.count > 1 ? nil : .infinity)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(downloading)
    }

    @ViewBuilder
    private var preview: some View {
        switch item.type {
        case .image:
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    placeholder(systemImage: "photo")
                default:
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .video:
            LoopingVideoPreview(
                stream: MediaPlayback.videoStream(originalURL: activeURL, proxyURL: previewURL),
                posterURL: (item.thumbnail?.isEmpty == false) ? thumbnailURL : nil
            )
            .id(activeURL)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .audio:
            VStack(spacing: 12) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Theme.primary.opacity(0.85))
                AudioPreview(url: previewURL)
                    .frame(height: 36)
                    .padding(.horizontal, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var typeTag: some View {
        HStack(spacing: 5) {
            Image(systemName: item.type.systemImage)
                .font(.system(size: 10, weight: .semibold))
            Text(item.type.label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color(hex: 0xF8FAFC))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.black.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
    }

    private func placeholder(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 28))
            .foregroundStyle(.white.opacity(0.7))
    }
}

struct DownloadProgressBar: View {
    var fraction: Double?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.white.opacity(0.22))
                if let fraction {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: max(6, geo.size.width * fraction))
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .tint(.white)
                        .padding(.horizontal, 0)
                }
            }
        }
        .frame(height: 3)
        .animation(.easeOut(duration: 0.15), value: fraction)
    }

    static func percentText(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }
}

private struct LoopingVideoPreview: View {
    let stream: MediaPlayback.Stream
    var posterURL: URL?
    @State private var player: AVPlayer?
    @State private var streamController: VideoStreamController?
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            if let posterURL, player == nil {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    default:
                        Color.clear
                    }
                }
            }

            if let player {
                VideoPlayer(player: player)
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear { start() }
        .onDisappear {
            player?.pause()
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
        }
    }

    private func start() {
        guard player == nil else { return }

        let avPlayer: AVPlayer
        if stream.headers.isEmpty {
            avPlayer = AVPlayer(url: stream.url)
        } else {
            let controller = VideoStreamController(url: stream.url, headers: stream.headers)
            streamController = controller
            avPlayer = controller.player
        }

        avPlayer.isMuted = true
        avPlayer.automaticallyWaitsToMinimizeStalling = true
        if let item = avPlayer.currentItem {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak avPlayer] _ in
                avPlayer?.seek(to: .zero)
                avPlayer?.play()
            }
        }
        player = avPlayer
        avPlayer.play()
    }
}

enum MediaPlayback {
    struct Stream: Equatable {
        let url: URL
        let headers: [String: String]
    }

    static func videoStream(originalURL: String, proxyURL: URL) -> Stream {
        guard let url = URL(string: originalURL),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return Stream(url: proxyURL, headers: [:])
        }

        let host = url.host?.lowercased() ?? ""
        if needsDownloadProxy(host) {
            return Stream(url: proxyURL, headers: [:])
        }
        guard let referer = referer(for: url) else {
            return Stream(url: proxyURL, headers: [:])
        }
        return Stream(url: url, headers: streamHeaders(referer: referer))
    }

    static func referer(for url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if matches(host, ["instagram.com", "instagr.am", "cdninstagram.com", "ddinstagram.com", "kkinstagram.com"])
            || host.contains("fbcdn.net")
            || host.contains("scontent") {
            return "https://www.instagram.com/"
        }
        if matches(host, ["xiaohongshu.com", "xhscdn.com", "xhslink.com", "xhslink.cn", "rednote.com"]) {
            return "https://www.xiaohongshu.com/"
        }
        if host.contains("douyin")
            || matches(host, ["iesdouyin.com", "snssdk.com", "ixigua.com"])
            || host.contains("bytecdn") {
            return "https://www.douyin.com/"
        }
        if matches(host, ["twitter.com", "twimg.com"]) || host == "x.com" || host.hasSuffix(".x.com") {
            return "https://twitter.com/"
        }
        if matches(host, ["ppt.cc"]) {
            return "https://ppt.cc/"
        }
        return nil
    }

    static func needsDownloadProxy(_ host: String) -> Bool {
        matches(host, ["lurl.cc", "myppt.cc"]) || host.contains("r2limit")
    }

    private static func streamHeaders(referer: String) -> [String: String] {
        [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
            "Accept": "*/*",
            "Referer": referer,
            "Origin": referer.hasSuffix("/") ? String(referer.dropLast()) : referer,
        ]
    }

    private static func matches(_ host: String, _ domains: [String]) -> Bool {
        domains.contains { host == $0 || host.hasSuffix(".\($0)") }
    }
}

private final class VideoStreamController {
    let player: AVPlayer
    private let loader: RefererResourceLoader

    init(url: URL, headers: [String: String]) {
        loader = RefererResourceLoader(targetURL: url, headers: headers)
        var parts = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? URLComponents()
        parts.scheme = "takeitstream"
        let asset = AVURLAsset(url: parts.url ?? url)
        asset.resourceLoader.setDelegate(loader, queue: loader.queue)
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.automaticallyWaitsToMinimizeStalling = true
    }
}

private final class RefererResourceLoader: NSObject, AVAssetResourceLoaderDelegate, URLSessionTaskDelegate {
    let queue = DispatchQueue(label: "takeit.video.stream")
    private let targetURL: URL
    private let headers: [String: String]
    private var tasks: [ObjectIdentifier: URLSessionDataTask] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = AppConfig.resourceTimeout
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    init(targetURL: URL, headers: [String: String]) {
        self.targetURL = targetURL
        self.headers = headers
    }

    deinit {
        session.invalidateAndCancel()
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        var request = URLRequest(url: targetURL)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        if let dataRequest = loadingRequest.dataRequest {
            let start = dataRequest.requestedOffset
            if dataRequest.requestsAllDataToEndOfResource {
                request.setValue("bytes=\(start)-", forHTTPHeaderField: "Range")
            } else {
                let end = start + Int64(dataRequest.requestedLength) - 1
                request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
            }
        } else {
            request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        }

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            self?.finish(loadingRequest, data: data, response: response, error: error)
        }
        tasks[ObjectIdentifier(loadingRequest)] = task
        task.resume()
        return true
    }

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        didCancel loadingRequest: AVAssetResourceLoadingRequest
    ) {
        let key = ObjectIdentifier(loadingRequest)
        tasks[key]?.cancel()
        tasks[key] = nil
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        var next = request
        headers.forEach { next.setValue($1, forHTTPHeaderField: $0) }
        completionHandler(next)
    }

    private func finish(
        _ loadingRequest: AVAssetResourceLoadingRequest,
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) {
        defer { tasks[ObjectIdentifier(loadingRequest)] = nil }

        if loadingRequest.isCancelled {
            return
        }
        if let error {
            loadingRequest.finishLoading(with: error)
            return
        }
        guard let http = response as? HTTPURLResponse, let data, (200..<400).contains(http.statusCode) else {
            loadingRequest.finishLoading(with: URLError(.badServerResponse))
            return
        }

        if let info = loadingRequest.contentInformationRequest {
            info.contentType = uti(from: http.value(forHTTPHeaderField: "Content-Type"))
            info.isByteRangeAccessSupported = true
            info.contentLength = contentLength(from: http) ?? Int64(data.count)
        }

        loadingRequest.dataRequest?.respond(with: data)
        loadingRequest.finishLoading()
    }

    private func contentLength(from response: HTTPURLResponse) -> Int64? {
        if let range = response.value(forHTTPHeaderField: "Content-Range"),
           let total = range.split(separator: "/").last,
           let length = Int64(total) {
            return length
        }
        if let raw = response.value(forHTTPHeaderField: "Content-Length"), let length = Int64(raw) {
            return length
        }
        return nil
    }

    private func uti(from contentType: String?) -> String {
        let mime = contentType?.split(separator: ";").first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch mime {
        case "video/quicktime":
            return "com.apple.quicktime-movie"
        case "video/x-m4v":
            return "public.mpeg-4"
        default:
            return "public.mpeg-4"
        }
    }
}

private struct AudioPreview: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                if player == nil {
                    player = AVPlayer(url: url)
                }
            }
            .onDisappear {
                player?.pause()
            }
    }
}
