import Foundation
import Testing
@testable import TakeIt

struct TakeItTests {
    @Test func errorMessagesMatchFrontend() {
        #expect(APIError.message(for: "INVALID_URL") == "请输入有效的分享链接")
        #expect(APIError.message(for: "UNSUPPORTED_PLATFORM") == "暂不支持该平台，敬请期待")
        #expect(APIError.message(for: "EXPIRED") == "该链接可能已过期或失效")
        #expect(APIError.message(for: "PASSWORD_FAILED") == "密码不正确，请重试")
        #expect(APIError.message(for: "NO_MEDIA") == "未找到可下载的媒体资源")
        #expect(APIError.message(for: "PARSE_FAILED") == "解析失败，请检查链接是否正确")
        #expect(APIError.message(for: "RATE_LIMIT") == "请求过于频繁，请稍后重试")
        #expect(APIError.message(for: "NETWORK") == "解析超时，请稍后重试")
    }

    @Test func platformDetectorRecognizesSupportedHosts() {
        #expect(PlatformDetector.detect(from: "https://myppt.cc/abc123") == "myppt")
        #expect(PlatformDetector.detect(from: "https://lurl.cc/xyz") == "lurl")
        #expect(PlatformDetector.detect(from: "https://ppt.cc/fOFqFx") == "pptcc")
        #expect(PlatformDetector.detect(from: "https://x.com/user/status/123") == "twitter")
        #expect(PlatformDetector.detect(from: "https://twitter.com/user/status/123") == "twitter")
        #expect(PlatformDetector.detect(from: "https://www.instagram.com/p/abc123/") == "instagram")
        #expect(PlatformDetector.detect(from: "https://instagr.am/reel/abc123") == "instagram")
        #expect(PlatformDetector.detect(from: "https://example.com/foo") == nil)
    }

    @Test func instagramPlaybackStreamsDirectCDN() {
        let proxy = URL(string: "https://takeit.terenzzzz.cn/api/download")!
        let cdn = "https://scontent.cdninstagram.com/o1/v/t2/video.mp4"
        let stream = MediaPlayback.videoStream(originalURL: cdn, proxyURL: proxy)
        #expect(stream.url.absoluteString == cdn)
        #expect(stream.headers["Referer"] == "https://www.instagram.com/")

        let other = MediaPlayback.videoStream(originalURL: "https://video.twimg.com/a.mp4", proxyURL: proxy)
        #expect(other.url == proxy)
        #expect(other.headers.isEmpty)
    }

    @Test func recentURLStoreKeepsLatestFiveUnique() {
        let defaults = UserDefaults(suiteName: "takeit.tests.recents")!
        defaults.removePersistentDomain(forName: "takeit.tests.recents")
        let store = RecentURLStore(defaults: defaults, key: "urls", limit: 5)

        store.add(" https://lurl.cc/a ")
        store.add("https://lurl.cc/b")
        store.add("https://lurl.cc/c")
        store.add("https://lurl.cc/a")
        store.add("https://lurl.cc/d")
        store.add("https://lurl.cc/e")
        store.add("https://lurl.cc/f")

        #expect(store.urls == [
            "https://lurl.cc/f",
            "https://lurl.cc/e",
            "https://lurl.cc/d",
            "https://lurl.cc/a",
            "https://lurl.cc/c",
        ])
    }

    @Test func downloadURLEncodesQueryItems() throws {
        let base = URL(string: "http://localhost:3001")!
        let url = APIClient.downloadURL(
            baseURL: base,
            mediaURL: "https://cdn.example.com/file name.mp4",
            filename: "clip.mp4",
            inline: true
        )
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })
        #expect(items["url"] == "https://cdn.example.com/file name.mp4")
        #expect(items["filename"] == "clip.mp4")
        #expect(items["inline"] == "1")
        #expect(url.path.hasSuffix("/api/download"))
    }

    @Test func productionAPIBaseURLIsDefault() {
        #expect(AppConfig.defaultAPIBaseURL == "https://takeit.terenzzzz.cn")
        #expect(AppConfig.isLegacyLocalDefault("http://localhost:3001"))
        #expect(AppConfig.isLegacyLocalDefault("http://localhost:3001/"))
        #expect(!AppConfig.isLegacyLocalDefault("https://takeit.terenzzzz.cn"))
    }

    @Test func extractResultDefaultsWhenOptionalFieldsMissing() throws {
        let json = Data(#"{"platform":"lurl","media":[{"url":"https://cdn.example.com/a.jpg"}]}"#.utf8)
        let result = try JSONDecoder().decode(ExtractResult.self, from: json)
        #expect(result.platform == "lurl")
        #expect(result.needsPassword == false)
        #expect(result.media.count == 1)
        #expect(result.media[0].type == .image)
        #expect(result.media[0].displayName == "download")
    }

    @Test func incomingURLParserReadsTakeItScheme() {
        let nested = URL(string: "takeit://extract?url=https%3A%2F%2Flurl.cc%2Fabc")!
        #expect(IncomingURLParser.shareURL(from: nested) == "https://lurl.cc/abc")

        let direct = URL(string: "takeit://https://x.com/user/status/1")!
        #expect(IncomingURLParser.shareURL(from: direct) == "https://x.com/user/status/1")
    }

    @Test func mediaFormatSniffsCommonHeaders() {
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0]) + Data(repeating: 0, count: 12)
        #expect(MediaFormat.sniff(jpeg)?.fileExtension == "jpg")

        let webp = Data("RIFF".utf8) + Data([0, 0, 0, 0]) + Data("WEBP".utf8)
        #expect(MediaFormat.sniff(webp)?.fileExtension == "webp")

        let mp4 = Data([0, 0, 0, 0x18]) + Data("ftyp".utf8) + Data("isom".utf8)
        #expect(MediaFormat.sniff(mp4)?.type == .video)

        let heic = Data([0, 0, 0, 0x18]) + Data("ftyp".utf8) + Data("heic".utf8)
        #expect(MediaFormat.sniff(heic)?.type == .image)

        let webm = Data([0x1A, 0x45, 0xDF, 0xA3]) + Data(repeating: 0, count: 12)
        #expect(MediaFormat.sniff(webm)?.fileExtension == "webm")
    }
}
