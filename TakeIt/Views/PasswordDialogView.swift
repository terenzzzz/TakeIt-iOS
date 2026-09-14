import SwiftUI

struct PasswordDialogView: View {
    @Binding var isPresented: Bool
    var onSubmit: (String) -> Void

    @State private var password = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(width: 44, height: 44)
                        .background(Theme.primaryLight)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("此链接需要密码")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.text)
                        Text("常见为上传日期，四位数字如 0115")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                SecureField("输入密码", text: $password)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Theme.bg)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous)
                            .stroke(focused ? Theme.primary : Theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit(submit)

                HStack {
                    Spacer()
                    Button("取消", action: close)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                    Button("解锁", action: submit)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSM, style: .continuous))
                        .opacity(password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                        .disabled(password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(Theme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLG, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 24, y: 12)
            .padding(20)
        }
        .onAppear {
            focused = true
        }
    }

    private func submit() {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        password = ""
    }

    private func close() {
        password = ""
        isPresented = false
    }
}
