import SwiftUI

@main
struct TakeItApp: App {
    @State private var extractor = ExtractorStore()
    @State private var recents = RecentURLStore()
    @State private var downloader = DownloadManager()
    @State private var health = HealthMonitor()
    @State private var pendingShare = PendingShareStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(extractor)
                .environment(recents)
                .environment(downloader)
                .environment(health)
                .environment(pendingShare)
                .tint(Theme.primary)
                .onOpenURL { pendingShare.accept($0) }
                .task {
                    await health.start()
                }
        }
    }
}
