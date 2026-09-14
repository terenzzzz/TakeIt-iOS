import Foundation
import Observation

@Observable
final class RecentURLStore {
    private let defaults: UserDefaults
    private let key: String
    private let limit: Int

    var urls: [String]

    init(
        defaults: UserDefaults = .standard,
        key: String = AppConfig.recentURLsKey,
        limit: Int = AppConfig.maxRecentURLs
    ) {
        self.defaults = defaults
        self.key = key
        self.limit = limit
        self.urls = Self.load(from: defaults, key: key, limit: limit)
    }

    func add(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = [trimmed] + urls.filter { $0 != trimmed }
        urls = Array(next.prefix(limit))
        persist()
    }

    func clear() {
        urls = []
        persist()
    }

    private func persist() {
        defaults.set(urls, forKey: key)
    }

    static func load(from defaults: UserDefaults, key: String, limit: Int) -> [String] {
        let stored = defaults.array(forKey: key) as? [String] ?? []
        return stored
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(limit)
            .map { $0 }
    }
}
