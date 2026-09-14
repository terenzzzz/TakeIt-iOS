import SwiftUI

struct NavbarView: View {
    @Environment(HealthMonitor.self) private var health
    var onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
                    .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

                Text("TakeIt")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.text)
                    .tracking(-0.3)

                Text("v1.0")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Theme.surfaceHover)
                    .overlay(
                        Capsule().stroke(Theme.border, lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }

            Spacer()

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(health.isOnline ? Theme.success : Theme.danger)
                        .frame(width: 6, height: 6)
                        .shadow(color: (health.isOnline ? Theme.success : Theme.danger).opacity(0.8), radius: 3)
                    Text(health.isOnline ? "在线" : "离线")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.surface)
                .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
                .clipShape(Capsule())

                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .frame(width: 32, height: 32)
                        .background(Theme.surface)
                        .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("设置")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.surfaceGlass)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)
        }
    }
}
