import Foundation
import Observation

@Observable
@MainActor
final class DownloadManager {
    var downloadingIDs: Set<String> = []
    var progress: [String: Double] = [:]
    var toastMessage: String?
    var sharePayload: SharePayload?
    var isDownloadingAll = false
    var batchCompleted = 0
    var batchTotal = 0

    func isDownloading(_ item: MediaItem) -> Bool {
        downloadingIDs.contains(item.url)
    }

    func fraction(for item: MediaItem) -> Double? {
        progress[item.url]
    }

    var batchFraction: Double {
        guard batchTotal > 0 else { return 0 }
        let current = downloadingIDs.compactMap { progress[$0] }.first ?? 0
        return min(1, (Double(batchCompleted) + current) / Double(batchTotal))
    }

    var batchLabel: String {
        guard batchTotal > 0 else { return "全部下载" }
        let current = min(batchCompleted + (downloadingIDs.isEmpty ? 0 : 1), batchTotal)
        return "\(current)/\(batchTotal)"
    }

    func download(_ item: MediaItem) async {
        downloadingIDs.insert(item.url)
        progress[item.url] = 0
        defer {
            downloadingIDs.remove(item.url)
            progress[item.url] = nil
        }

        do {
            let id = item.url
            let (data, contentType) = try await APIClient.shared.downloadData(
                mediaURL: item.url,
                filename: item.displayName,
                onProgress: reportProgress(id: id)
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
        batchTotal = items.count
        batchCompleted = 0
        defer {
            isDownloadingAll = false
            batchTotal = 0
            batchCompleted = 0
        }

        var files: [URL] = []
        for (index, item) in items.enumerated() {
            downloadingIDs.insert(item.url)
            progress[item.url] = 0
            defer {
                downloadingIDs.remove(item.url)
                progress[item.url] = nil
            }
            do {
                let id = item.url
                let (data, contentType) = try await APIClient.shared.downloadData(
                    mediaURL: item.url,
                    filename: item.displayName,
                    onProgress: reportProgress(id: id)
                )
                files.append(try MediaSaver.save(data, item: item, contentType: contentType))
            } catch {
                toastMessage = friendlyMessage(for: error)
            }
            batchCompleted = index + 1
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

    private func reportProgress(id: String) -> @Sendable (Double?) -> Void {
        { [weak self] fraction in
            Task { @MainActor in
                self?.applyProgress(id: id, fraction: fraction)
            }
        }
    }

    private func applyProgress(id: String, fraction: Double?) {
        if let fraction {
            progress[id] = min(1, max(0, fraction))
        } else {
            progress.removeValue(forKey: id)
        }
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
