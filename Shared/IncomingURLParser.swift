import Foundation

enum IncomingURLParser {
    nonisolated static func shareURL(from incoming: URL) -> String? {
        if incoming.scheme?.lowercased() == "takeit" {
            let components = URLComponents(url: incoming, resolvingAgainstBaseURL: false)
            if let nested = components?.queryItems?.first(where: { $0.name == "url" })?.value,
               !nested.isEmpty {
                return nested
            }
            let path = incoming.absoluteString.replacingOccurrences(of: "takeit://", with: "")
            if path.hasPrefix("http") {
                return path
            }
        }
        if incoming.scheme == "http" || incoming.scheme == "https" {
            return incoming.absoluteString
        }
        return nil
    }

    /// 整段分享文案或纯链接。有 http(s) 时保留原文，方便后端从抖音 / 小红书文案里抽链。
    nonisolated static func sharePayload(fromText raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if httpURL(fromText: trimmed) != nil {
            return trimmed
        }
        let normalized = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: normalized), url.host != nil, trimmed.contains(".") else {
            return nil
        }
        return normalized
    }

    nonisolated static func httpURL(fromText raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if isHTTPURL(trimmed) {
            return trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        }

        guard let range = trimmed.range(of: #"https?://[^\s]+"#, options: .regularExpression) else {
            return nil
        }
        var found = String(trimmed[range])
        let trailing = CharacterSet(charactersIn: ".,;:!?)]}>」』、。")
        while let last = found.unicodeScalars.last, trailing.contains(last) {
            found.removeLast()
        }
        return found.isEmpty ? nil : found
    }

    nonisolated static func takeItOpenURL(for payload: String) -> URL? {
        var components = URLComponents()
        components.scheme = "takeit"
        components.host = "extract"
        components.queryItems = [URLQueryItem(name: "url", value: payload)]
        return components.url
    }

    nonisolated private static func isHTTPURL(_ raw: String) -> Bool {
        let value = raw.contains("://") ? raw : "https://\(raw)"
        guard let url = URL(string: value), let host = url.host, !host.isEmpty else { return false }
        let scheme = url.scheme?.lowercased()
        return scheme == "http" || scheme == "https"
    }
}
