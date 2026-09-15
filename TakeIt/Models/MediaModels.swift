import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

enum MediaType: String, Codable, Equatable, CaseIterable {
    case image
    case video
    case audio

    var label: String {
        switch self {
        case .image: return "图片"
        case .video: return "视频"
        case .audio: return "音频"
        }
    }

    var systemImage: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "music.note"
        }
    }
}

struct MediaItem: Codable, Equatable, Identifiable, Hashable {
    var type: MediaType
    var url: String
    var thumbnail: String?
    var filename: String?

    var id: String { url }

    var displayName: String {
        let name = filename?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? "download" : name
    }

    init(type: MediaType, url: String, thumbnail: String? = nil, filename: String? = nil) {
        self.type = type
        self.url = url
        self.thumbnail = thumbnail
        self.filename = filename
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(MediaType.self, forKey: .type) ?? .image
        url = try container.decode(String.self, forKey: .url)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
    }
}

struct ExtractResult: Codable, Equatable {
    var platform: String
    var title: String?
    var needsPassword: Bool
    var media: [MediaItem]

    init(platform: String, title: String? = nil, needsPassword: Bool = false, media: [MediaItem] = []) {
        self.platform = platform
        self.title = title
        self.needsPassword = needsPassword
        self.media = media
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        platform = try container.decodeIfPresent(String.self, forKey: .platform) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title)
        needsPassword = try container.decodeIfPresent(Bool.self, forKey: .needsPassword) ?? false
        media = try container.decodeIfPresent([MediaItem].self, forKey: .media) ?? []
    }
}

struct HealthStatus: Codable, Equatable {
    var status: String
}

enum ClipboardHelper {
    static var string: String? {
        #if os(iOS)
        return UIPasteboard.general.string
        #elseif os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }

    static func pasteableString() -> String? {
        let trimmed = string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard PlatformDetector.looksLikeShareLink(trimmed) else { return nil }
        return trimmed
    }
}

enum PlatformDetector {
    static func detect(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalized = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let host = URL(string: normalized)?.host?.lowercased() else { return nil }

        if host.contains("myppt.cc") { return "myppt" }
        if host.contains("lurl.cc") { return "lurl" }
        if host.contains("ppt.cc") { return "pptcc" }
        if host.contains("twitter.com") || host.contains("x.com") { return "twitter" }
        if host.contains("xiaohongshu.com") || host.contains("xhslink.com") { return "xiaohongshu" }
        if host.contains("douyin.com") || host.contains("iesdouyin.com") { return "douyin" }
        if host.contains("instagram.com") || host.contains("instagr.am") { return "instagram" }
        return nil
    }

    static func looksLikeURL(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)") else {
            return false
        }
        return url.host != nil
    }

    static func looksLikeShareLink(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if detect(from: trimmed) != nil { return true }
        if looksLikeURL(trimmed) { return true }
        return trimmed.range(of: #"https?://"#, options: .regularExpression) != nil
    }
}
