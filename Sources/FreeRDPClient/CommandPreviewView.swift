import SwiftUI
import AppKit
import FreeRDPKit

struct CommandPreviewView: View {
    let profile: ConnectionProfile
    @Environment(\.dismiss) private var dismiss

    private var binaryPath: String {
        FreeRDPBinary.resolve(for: profile)?.path ?? "(未找到 FreeRDP)"
    }

    private var previewLines: [String] {
        let password = KeychainHelper.load(account: KeychainHelper.account(for: profile.id))
        let gw = KeychainHelper.load(account: KeychainHelper.gatewayAccount(for: profile.id))
        return ArgumentBuilder.preview(profile: profile, password: password, gatewayPassword: gw)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("命令行预览")
                .font(.headline)
            Text("实际启动时参数通过 /args-from:stdin 逐行传入，密码不会出现在进程列表中。下方预览已对密码打码。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(binaryPath)
                        .foregroundStyle(.tint)
                    ForEach(Array(previewLines.enumerated()), id: \.offset) { _, line in
                        Text("  " + line)
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            HStack {
                Button {
                    let text = ([binaryPath] + previewLines).joined(separator: " \\\n  ")
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                } label: {
                    Label("复制 (密码已打码)", systemImage: "doc.on.doc")
                }
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 640, height: 520)
    }
}
