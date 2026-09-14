import Foundation

struct APIError: Error, LocalizedError, Equatable {
    let code: String
    let message: String
    let statusCode: Int?

    var errorDescription: String? { message }

    static let messages: [String: String] = [
        "INVALID_URL": "请输入有效的分享链接",
        "UNSUPPORTED_PLATFORM": "暂不支持该平台，敬请期待",
        "EXPIRED": "该链接可能已过期或失效",
        "BLOCKED": "目标网站启用了防护，暂时无法解析",
        "PASSWORD_FAILED": "密码不正确，请重试",
        "NO_MEDIA": "未找到可下载的媒体资源",
        "PARSE_FAILED": "解析失败，请检查链接是否正确",
        "RATE_LIMIT": "请求过于频繁，请稍后重试",
        "DOWNLOAD_FAILED": "下载失败，请重试",
        "NETWORK": "解析超时，请稍后重试",
    ]

    static func message(for code: String?, fallback: String? = nil) -> String {
        if let code, let mapped = messages[code] {
            return mapped
        }
        if let fallback, !fallback.isEmpty {
            return fallback
        }
        return "解析失败"
    }

    static func from(data: Data, statusCode: Int) -> APIError {
        let payload = (try? JSONDecoder().decode(ErrorPayload.self, from: data)) ?? ErrorPayload(error: nil, message: nil)
        let code = payload.error ?? (statusCode == 429 ? "RATE_LIMIT" : "PARSE_FAILED")
        return APIError(
            code: code,
            message: message(for: code, fallback: payload.message),
            statusCode: statusCode
        )
    }

    private struct ErrorPayload: Codable {
        var error: String?
        var message: String?
    }
}

enum MediaSaveError: LocalizedError, Equatable {
    case photoAccessDenied
    case writeFailed
    case emptyFile

    var errorDescription: String? {
        switch self {
        case .photoAccessDenied:
            return "没有相册写入权限，请在设置中允许 TakeIt 访问相册"
        case .writeFailed:
            return "保存失败，请重试"
        case .emptyFile:
            return "下载内容为空，请重试"
        }
    }
}
