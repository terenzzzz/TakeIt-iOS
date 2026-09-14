import Foundation
import Observation

@Observable
final class ExtractorStore {
    var loading = false
    var errorMessage: String?
    var result: ExtractResult?
    var currentURL = ""
    var showPassword = false

    private var client: APIClient {
        APIClient.shared
    }

    @discardableResult
    func extract(_ url: String) async -> ExtractResult? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        loading = true
        errorMessage = nil
        result = nil
        currentURL = trimmed
        showPassword = false

        defer { loading = false }

        do {
            let data = try await client.extract(url: trimmed)
            result = data
            showPassword = data.needsPassword
            return data
        } catch let error as APIError {
            errorMessage = error.message
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    @discardableResult
    func retryWithPassword(_ password: String) async -> ExtractResult? {
        guard !currentURL.isEmpty else { return nil }
        loading = true
        errorMessage = nil
        showPassword = false

        defer { loading = false }

        do {
            let data = try await client.extract(url: currentURL, password: password)
            result = data
            showPassword = data.needsPassword
            return data
        } catch let error as APIError {
            errorMessage = error.message
            showPassword = true
            return nil
        } catch {
            errorMessage = error.localizedDescription
            showPassword = true
            return nil
        }
    }

    func reset() {
        loading = false
        errorMessage = nil
        result = nil
        currentURL = ""
        showPassword = false
    }
}
