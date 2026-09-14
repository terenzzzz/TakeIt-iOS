import SwiftUI

struct PlatformBadgeView: View {
    let platform: String

    var body: some View {
        let style = PlatformStyle.style(for: platform)
        HStack(spacing: 6) {
            Circle()
                .fill(style.color)
                .frame(width: 6, height: 6)
            Text(style.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(style.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(style.background)
        .overlay(Capsule().stroke(style.border, lineWidth: 1))
        .clipShape(Capsule())
    }
}
