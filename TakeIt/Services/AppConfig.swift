import Foundation

enum AppConfig {
    static let defaultAPIBaseURL = "http://127.0.0.1:3001"
    static let apiBaseURLKey = "takeit.apiBaseURL"
    static let maxRecentURLs = 5
    static let recentURLsKey = "takeit-recent-urls"
    static let requestTimeout: TimeInterval = 180
    static let resourceTimeout: TimeInterval = 300
    static let healthTimeout: TimeInterval = 8

    static var apiBaseURLString: String {
        get {
            let stored = UserDefaults.standard.string(forKey: apiBaseURLKey)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if stored.isEmpty {
                return defaultAPIBaseURL
            }
            return stored
        }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: apiBaseURLKey)
            } else {
                UserDefaults.standard.set(trimmed, forKey: apiBaseURLKey)
            }
        }
    }

    static var apiBaseURL: URL {
        let raw = apiBaseURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: raw) ?? URL(string: defaultAPIBaseURL)!
    }
}
