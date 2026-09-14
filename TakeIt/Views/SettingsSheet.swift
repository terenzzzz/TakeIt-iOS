import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(HealthMonitor.self) private var health
    @State private var apiBaseURL = AppConfig.apiBaseURLString
    @State private var saved = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://takeit.terenzzzz.cn", text: $apiBaseURL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                } header: {
                    Text("后端 API 地址")
                } footer: {
                    Text("默认连接 takeit.terenzzzz.cn。本地调试可改为 http://localhost:3001。")
                }

                Section("状态") {
                    LabeledContent("健康检查") {
                        Text(health.isOnline ? "正常" : "离线")
                            .foregroundStyle(health.isOnline ? Theme.success : Theme.danger)
                    }
                    if let date = health.lastChecked {
                        LabeledContent("最近检查") {
                            Text(date, style: .time)
                        }
                    }
                    Button("立即检查") {
                        Task { await health.refresh() }
                    }
                }

                Section("支持平台") {
                    Text("MyPPT · LURL · PPT.cc · Twitter / X · Instagram")
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .navigationTitle("设置")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        AppConfig.apiBaseURLString = apiBaseURL
                        saved = true
                        Task { await health.refresh() }
                    }
                }
            }
            .alert("已保存", isPresented: $saved) {
                Button("好", role: .cancel) { dismiss() }
            } message: {
                Text("API 地址已更新。")
            }
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }
}
