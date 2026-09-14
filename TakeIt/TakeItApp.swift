import SwiftUI

@main
struct TakeItApp: App {
    @State private var extractor = ExtractorStore()
    @State private var recents = RecentURLStore()
    @State private var downloader = DownloadManager()
    @State private var health = HealthMonitor()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(extractor)
                .environment(recents)
                .environment(downloader)
                .environment(health)
                .tint(Theme.primary)
                .task {
                    await health.start()
                }
        }
    }
}
