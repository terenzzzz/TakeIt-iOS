import SwiftUI

struct EmptyStateView: View {
    private let platforms = [
        "twitter", "instagram", "douyin", "xiaohongshu", "myppt", "lurl", "pptcc",
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 14) {
            Text("支持的平台")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textMuted)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(platforms, id: \.self) { platform in
                    chip(PlatformStyle.style(for: platform).name)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceGlass)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG, style: .continuous)
                .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG, style: .continuous))
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
            .clipShape(Capsule())
    }
}
