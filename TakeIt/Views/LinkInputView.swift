import SwiftUI

struct LinkInputView: View {
    @Binding var url: String
    var loading: Bool
    var recentURLs: [String]
    var onSubmit: () -> Void
    var onClear: () -> Void

    @FocusState private var isFocused: Bool
    @State private var showRecent = false
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var canSubmit: Bool {
        !loading && !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if sizeClass == .compact {
                    compactLayout
                } else {
                    regularLayout
                }
            }
            .padding(10)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous)
                    .stroke(isFocused ? Theme.textMuted : Theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)

            if showRecent && !recentURLs.isEmpty {
                recentDropdown
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                textField
                if !url.isEmpty { clearButton }
            }
            .padding(.horizontal, 8)
            .frame(minHeight: 48)
            submitButton
                .frame(maxWidth: .infinity)
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textMuted)
                .padding(.leading, 10)
            textField
            if !url.isEmpty { clearButton }
            submitButton
        }
    }

    private var textField: some View {
        TextField("粘贴分享链接", text: $url)
            .textFieldStyle(.plain)
            .font(.system(size: 16))
            .foregroundStyle(Theme.text)
            .padding(.vertical, 12)
            .focused($isFocused)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            #endif
            .submitLabel(.go)
            .onSubmit(onSubmit)
            .onChange(of: isFocused) { _, focused in
                showRecent = focused && !recentURLs.isEmpty
            }
            .onChange(of: url) { oldValue, newValue in
                handlePaste(oldValue: oldValue, newValue: newValue)
            }
            .accessibilityLabel("分享链接")
    }

    private var clearButton: some View {
        Button(action: {
            url = ""
            onClear()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Theme.textMuted)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.surfaceHover.opacity(0.8)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("清除链接")
    }

    private var submitButton: some View {
        Button(action: onSubmit) {
            HStack(spacing: 8) {
                if loading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Theme.primaryText)
                    Text("提取中")
                } else {
                    Text("提取")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.primaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: sizeClass == .compact ? .infinity : nil)
            .background(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD - 2, style: .continuous))
            .opacity(canSubmit ? 1 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private var recentDropdown: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近使用")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            ForEach(recentURLs, id: \.self) { item in
                Button {
                    url = item
                    showRecent = false
                    isFocused = false
                    onSubmit()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private func handlePaste(oldValue: String, newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = oldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let clipboard = ClipboardHelper.string?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != previous,
              trimmed == clipboard,
              PlatformDetector.looksLikeURL(trimmed)
        else { return }
        showRecent = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onSubmit()
        }
    }
}
