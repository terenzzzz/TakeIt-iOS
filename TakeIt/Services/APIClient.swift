import Foundation

struct APIClient {
    var baseURL: URL
    var session: URLSession
    var decoder: JSONDecoder

    static var shared: APIClient {
        APIClient(baseURL: AppConfig.apiBaseURL)
    }

    init(baseURL: URL, session: URLSession = APIClient.makeSession()) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.resourceTimeout
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }

    func extract(url: String, password: String? = nil) async throws -> ExtractResult {
        let endpoint = baseURL.appending(path: "api/extract")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        var body: [String: String] = ["url": url]
        if let password, !password.isEmpty {
            body["password"] = password
        }
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = AppConfig.requestTimeout

        let (data, response) = try await perform(request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(code: "NETWORK", message: APIError.message(for: "NETWORK"), statusCode: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: http.statusCode)
        }
        return try decoder.decode(ExtractResult.self, from: data)
    }

    func health() async throws -> HealthStatus {
        let endpoint = baseURL.appending(path: "health")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = AppConfig.healthTimeout
        let (data, response) = try await perform(request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError(code: "NETWORK", message: "后端不可用", statusCode: (response as? HTTPURLResponse)?.statusCode)
        }
        return try decoder.decode(HealthStatus.self, from: data)
    }

    func downloadURL(for mediaURL: String, filename: String, inline: Bool = false) -> URL {
        Self.downloadURL(baseURL: baseURL, mediaURL: mediaURL, filename: filename, inline: inline)
    }

    func previewURL(for mediaURL: String, filename: String) -> URL {
        downloadURL(for: mediaURL, filename: filename, inline: true)
    }

    func downloadData(mediaURL: String, filename: String) async throws -> (Data, String?) {
        let endpoint = downloadURL(for: mediaURL, filename: filename, inline: false)
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = AppConfig.resourceTimeout
        let (data, response) = try await perform(request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.from(data: data, statusCode: (response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        guard !data.isEmpty else { throw MediaSaveError.emptyFile }
        return (data, http.value(forHTTPHeaderField: "Content-Type"))
    }

    static func downloadURL(baseURL: URL, mediaURL: String, filename: String, inline: Bool) -> URL {
        var components = URLComponents(url: baseURL.appending(path: "api/download"), resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "url", value: mediaURL),
            URLQueryItem(name: "filename", value: filename.isEmpty ? "download" : filename),
        ]
        if inline {
            items.append(URLQueryItem(name: "inline", value: "1"))
        }
        components.queryItems = items
        return components.url ?? baseURL.appending(path: "api/download")
    }

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError(code: "NETWORK", message: APIError.message(for: "NETWORK"), statusCode: nil)
        }
    }
}
