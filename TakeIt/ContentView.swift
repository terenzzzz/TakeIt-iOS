import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(ExtractorStore.self) private var extractor
    @Environment(RecentURLStore.self) private var recents
    @Environment(DownloadManager.self) private var downloader
    @Environment(HealthMonitor.self) private var health

    @State private var url = ""
    @State private var showSettings = false
    @State private var clipboardHint: String?

    var body: some View {
        @Bindable var extractor = extractor
        @Bindable var downloader = downloader

        ZStack {
            DotBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        LinkInputView(
                            url: $url,
                            loading: extractor.loading,
                            recentURLs: recents.urls,
                            onSubmit: submit,
                            onClear: clear
                        )
                        if let clipboardHint {
                            clipboardBanner(clipboardHint)
                        }
                        if let error = extractor.errorMessage {
                            errorBanner(error)
                        }
                        if extractor.loading {
                            loadingState
                        } else if let result = extractor.result, !result.needsPassword {
                            resultSection(result)
                        } else if extractor.errorMessage == nil {
                            EmptyStateView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 960)
                    .frame(maxWidth: .infinity)
                }
                #if os(iOS)
                .scrollDismissesKeyboard(.interactively)
                #endif
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                NavbarView { showSettings = true }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
            }

            if extractor.showPassword {
                PasswordDialogView(isPresented: $extractor.showPassword) { password in
                    Task {
                        await extractor.retryWithPassword(password)
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }

            if let toast = downloader.toastMessage {
                toastBanner(toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: extractor.errorMessage)
        .animation(.easeInOut(duration: 0.2), value: extractor.loading)
        .animation(.easeInOut(duration: 0.2), value: downloader.toastMessage)
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        #if os(iOS)
        .sheet(item: $downloader.sharePayload) { payload in
            ActivityView(items: payload.urls)
        }
        #endif
        .onAppear {
            inspectClipboard()
        }
        .onReceive(NotificationCenter.default.publisher(for: sceneDidBecomeActive)) { _ in
            inspectClipboard()
        }
        .onChange(of: downloader.toastMessage) { _, newValue in
            guard newValue != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(2.4))
                if downloader.toastMessage == newValue {
                    downloader.clearToast()
                }
            }
        }
        .onOpenURL { incoming in
            applyIncomingURL(incoming)
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            Text("Paste it. Take it. Save it.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.4)
                .textCase(.uppercase)

            VStack(spacing: 2) {
                Text("一键解析提取")
                Text("公开媒体")
                    .underline(color: Theme.borderHover)
            }
            .font(.system(size: 32, weight: .heavy))
            .foregroundStyle(Theme.text)

            Text("粘贴 MyPPT、LURL、PPT.cc、Twitter/X、抖音或 Instagram 分享链接（支持整段分享文案），即可批量解析与下载原质图片与视频。")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 2)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.text)
            Text("正在提取…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.textMuted)
        }
        .padding(.vertical, 56)
        .frame(maxWidth: .infinity)
    }

    private func resultSection(_ result: ExtractResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                PlatformBadgeView(platform: result.platform)
                Spacer(minLength: 0)

                Text("\(result.media.count) 项")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )

                if result.media.count > 1 {
                    Button {
                        Task { await downloader.downloadAll(result.media) }
                    } label: {
                        HStack(spacing: 6) {
                            if downloader.isDownloadingAll {
                                ProgressView().controlSize(.mini).tint(Theme.primaryText)
                            } else {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Text("全部下载")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(downloader.isDownloadingAll)
                }
            }
            .padding(.bottom, 12)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Theme.border).frame(height: 1)
            }

            MediaGridView(media: result.media)
        }
        .padding(.top, 4)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 16, weight: .semibold))
            Text(message)
                .font(.system(size: 14, weight: .medium))
            Spacer(minLength: 0)
        }
        .foregroundStyle(Theme.danger)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.danger.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous)
                .stroke(Theme.danger.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous))
    }

    private func clipboardBanner(_ hint: String) -> some View {
        Button {
            url = hint
            clipboardHint = nil
            submit()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard")
                Text("剪贴板里有链接")
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
                Text("提取")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func toastBanner(_ message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.primary.opacity(0.92))
                .clipShape(Capsule())
                .padding(.bottom, 28)
        }
        .allowsHitTesting(false)
    }

    private var footer: some View {
        Text("TakeIt © 2026 · 仅用于公开与授权内容")
            .font(.system(size: 12))
            .foregroundStyle(Theme.textMuted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.border).frame(height: 1)
            }
            .background(Theme.bg.opacity(0.92))
    }

    private func submit() {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recents.add(trimmed)
        clipboardHint = nil
        Task { await extractor.extract(trimmed) }
    }

    private func clear() {
        extractor.reset()
        clipboardHint = nil
    }

    private func inspectClipboard() {
        guard let pasted = ClipboardHelper.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !pasted.isEmpty,
              pasted != url,
              PlatformDetector.detect(from: pasted) != nil
        else { return }
        clipboardHint = pasted
    }

    private func applyIncomingURL(_ incoming: URL) {
        if let extracted = IncomingURLParser.shareURL(from: incoming) {
            url = extracted
            submit()
        }
    }

    private var sceneDidBecomeActive: Notification.Name {
        #if os(iOS)
        UIApplication.didBecomeActiveNotification
        #elseif os(macOS)
        NSApplication.didBecomeActiveNotification
        #else
        Notification.Name("DidBecomeActive")
        #endif
    }
}

enum IncomingURLParser {
    static func shareURL(from incoming: URL) -> String? {
        if incoming.scheme?.lowercased() == "takeit" {
            let components = URLComponents(url: incoming, resolvingAgainstBaseURL: false)
            if let nested = components?.queryItems?.first(where: { $0.name == "url" })?.value,
               !nested.isEmpty {
                return nested
            }
            let path = incoming.absoluteString.replacingOccurrences(of: "takeit://", with: "")
            if path.hasPrefix("http") {
                return path
            }
        }
        if incoming.scheme == "http" || incoming.scheme == "https" {
            return incoming.absoluteString
        }
        return nil
    }
}

#Preview {
    ContentView()
        .environment(ExtractorStore())
        .environment(RecentURLStore())
        .environment(DownloadManager())
        .environment(HealthMonitor())
}
