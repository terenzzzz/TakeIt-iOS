import Foundation
import Observation

@Observable
final class DownloadManager {
    var downloadingIDs: Set<String> = []
    var toastMessage: String?
    var sharePayload: SharePayload?
    var isDownloadingAll = false

    func isDownloading(_ item: MediaItem) -> Bool {
        downloadingIDs.contains(item.url)
    }

    func download(_ item: MediaItem) async {
        downloadingIDs.insert(item.url)
        defer { downloadingIDs.remove(item.url) }

        do {
            let (data, contentType) = try await APIClient.shared.downloadData(
                mediaURL: item.url,
                filename: item.displayName
            )
            let fileURL = try MediaSaver.save(data, item: item, contentType: contentType)
            sharePayload = SharePayload(urls: [fileURL])
        } catch {
            toastMessage = friendlyMessage(for: error)
        }
    }

    func downloadAll(_ items: [MediaItem]) async {
        guard !items.isEmpty else { return }
        isDownloadingAll = true
        defer { isDownloadingAll = false }

        var files: [URL] = []
        for (index, item) in items.enumerated() {
            downloadingIDs.insert(item.url)
            defer { downloadingIDs.remove(item.url) }
            do {
                let (data, contentType) = try await APIClient.shared.downloadData(
                    mediaURL: item.url,
                    filename: item.displayName
                )
                files.append(try MediaSaver.save(data, item: item, contentType: contentType))
            } catch {
                toastMessage = friendlyMessage(for: error)
            }
            if index < items.count - 1 {
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
        if !files.isEmpty {
            sharePayload = SharePayload(urls: files)
        }
    }

    func clearToast() {
        toastMessage = nil
    }

    private func friendlyMessage(for error: Error) -> String {
        if let saveError = error as? MediaSaveError {
            return saveError.localizedDescription
        }
        if let apiError = error as? APIError {
            return apiError.message
        }
        return error.localizedDescription
    }
}

struct SharePayload: Identifiable, Equatable {
    let urls: [URL]
    var id: String { urls.map(\.absoluteString).joined(separator: "|") }
}
