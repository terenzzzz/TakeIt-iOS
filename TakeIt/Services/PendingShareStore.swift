import Foundation
import Observation

@Observable
@MainActor
final class PendingShareStore {
    var payload: String?

    func consume() -> String? {
        let value = payload
        payload = nil
        return value
    }

    func accept(_ incoming: URL) {
        payload = IncomingURLParser.shareURL(from: incoming)
    }
}
