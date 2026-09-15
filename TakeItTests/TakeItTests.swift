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
        #expect(PlatformDetector.looksLikeShareLink("复制打开抖音 https://v.douyin.com/xxxxx/ 你好"))
        #expect(PlatformDetector.looksLikeShareLink("https://www.instagram.com/p/abc123/"))
        #expect(!PlatformDetector.looksLikeShareLink("随便一段文字"))
    }

    @Test func videoPlaybackUsesDirectCDNExceptCloudflareHosts() {
        let proxy = URL(string: "http://127.0.0.1:3001/api/download")!

        let instagram = "https://scontent.cdninstagram.com/o1/v/t2/video.mp4"
        let instagramStream = MediaPlayback.videoStream(originalURL: instagram, proxyURL: proxy)
        #expect(instagramStream.url.absoluteString == instagram)
        #expect(instagramStream.headers["Referer"] == "https://www.instagram.com/")

        let xhs = "https://sns-video-bd.xhscdn.com/stream/abc.mp4"
        let xhsStream = MediaPlayback.videoStream(originalURL: xhs, proxyURL: proxy)
        #expect(xhsStream.url.absoluteString == xhs)
        #expect(xhsStream.headers["Referer"] == "https://www.xiaohongshu.com/")

        let douyin = "https://aweme.snssdk.com/aweme/v1/play/?video_id=abc"
        let douyinStream = MediaPlayback.videoStream(originalURL: douyin, proxyURL: proxy)
        #expect(douyinStream.url.absoluteString == douyin)
        #expect(douyinStream.headers["Referer"] == "https://www.douyin.com/")

        let twitter = "https://video.twimg.com/ext_tw_video/1/pu/vid/avc1/720x1280/clip.mp4"
        let twitterStream = MediaPlayback.videoStream(originalURL: twitter, proxyURL: proxy)
        #expect(twitterStream.url.absoluteString == twitter)
        #expect(twitterStream.headers["Referer"] == "https://twitter.com/")

        let pptcc = "https://www.ppt.cc/clip.mp4"
        let pptccStream = MediaPlayback.videoStream(originalURL: pptcc, proxyURL: proxy)
        #expect(pptccStream.url.absoluteString == pptcc)
        #expect(pptccStream.headers["Referer"] == "https://ppt.cc/")

        let lurl = MediaPlayback.videoStream(originalURL: "https://r2limit.example.com/a.mp4", proxyURL: proxy)
        #expect(lurl.url == proxy)
        #expect(lurl.headers.isEmpty)

        let myppt = MediaPlayback.videoStream(originalURL: "https://cdn.myppt.cc/a.mp4", proxyURL: proxy)
        #expect(myppt.url == proxy)
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
        let base = URL(string: "http://127.0.0.1:3001")!
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
        #expect(AppConfig.defaultAPIBaseURL == "http://127.0.0.1:3001")
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

    @Test func sharePayloadKeepsFullShareCopy() {
        #expect(IncomingURLParser.sharePayload(fromText: "https://lurl.cc/abc") == "https://lurl.cc/abc")
        #expect(
            IncomingURLParser.sharePayload(fromText: "复制打开抖音 https://v.douyin.com/xxxxx/ 你好")
            == "复制打开抖音 https://v.douyin.com/xxxxx/ 你好"
        )
        #expect(IncomingURLParser.httpURL(fromText: "看这个 https://xhslink.com/abc。") == "https://xhslink.com/abc")
        #expect(IncomingURLParser.sharePayload(fromText: "随便一段文字") == nil)

        let openURL = IncomingURLParser.takeItOpenURL(for: "https://lurl.cc/abc")
        #expect(IncomingURLParser.shareURL(from: openURL!) == "https://lurl.cc/abc")
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

    @Test func downloadProgressPercentText() {
        #expect(DownloadProgressBar.percentText(0) == "0%")
        #expect(DownloadProgressBar.percentText(0.42) == "42%")
        #expect(DownloadProgressBar.percentText(1) == "100%")
    }
}
