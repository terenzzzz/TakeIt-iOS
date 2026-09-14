import Foundation
import Observation

@Observable
final class HealthMonitor {
    var isOnline = false
    var lastChecked: Date?

    func refresh() async {
        do {
            let status = try await APIClient.shared.health()
            isOnline = status.status.lowercased() == "ok"
        } catch {
            isOnline = false
        }
        lastChecked = Date()
    }

    func start() async {
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(30))
            await refresh()
        }
    }
}
