import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            Text("支持的平台")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textMuted)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], spacing: 8) {
                ForEach(["MyPPT.cc", "LURL.cc", "PPT.cc", "Twitter / X", "Instagram"], id: \.self) { name in
                    chip(name)
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
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Theme.surface)
            .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
            .clipShape(Capsule())
    }
}
