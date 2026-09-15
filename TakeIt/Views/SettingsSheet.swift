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
                    TextField("http://127.0.0.1:3001", text: $apiBaseURL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                } header: {
                    Text("后端 API 地址")
                } footer: {
                    Text("请填写你自行部署的 takeit-backend 地址。默认使用本地调试地址 http://127.0.0.1:3001。")
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
