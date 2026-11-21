import SwiftUI
import FreeRDPKit

struct AdvancedTab: View {
    @Binding var profile: ConnectionProfile

    @State private var detectedVersion: String?

    var body: some View {
        Form {
            Section("客户端程序") {
                Picker("使用", selection: $profile.binaryKind) {
                    ForEach(ClientBinaryKind.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                if profile.binaryKind == .custom {
                    LabeledContent("路径") {
                        HStack {
                            TextField("可执行文件路径", text: $profile.customBinaryPath)
                                .frame(maxWidth: 300)
                            Button("浏览…") {
                                chooseExecutable { url in
                                    profile.customBinaryPath = url.path
                                }
                            }
                        }
                    }
                }
                if let url = FreeRDPBinary.resolve(for: profile) {
                    LabeledContent("实际路径") {
                        Text(url.path).font(.caption).monospaced()
                    }
                    if let version = detectedVersion {
                        LabeledContent("版本") {
                            Text(version).font(.caption)
                        }
                    }
                } else {
                    Label("未找到可用的 FreeRDP 客户端。安装：brew install freerdp",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("日志") {
                Picker("日志级别", selection: $profile.logLevel) {
                    ForEach(LogLevel.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .help("/log-level, 会话日志显示在本客户端的会话页")
            }

            Section("会话") {
                Stepper(value: $profile.timeoutMs, in: 0...120_000, step: 5000) {
                    LabeledContent("连接超时") {
                        Text(profile.timeoutMs == 0 ? "默认" : "\(profile.timeoutMs) ms")
                    }
                }
                .help("/timeout, 高延迟链路频繁超时时可调大")
                Toggle("防止远程锁屏 (定期发送假鼠标移动)", isOn: $profile.preventSessionLock)
                    .help("+prevent-session-lock")
                Toggle("多传输通道 (UDP + TCP)", isOn: $profile.multitransport)
                    .help("-multitransport 关闭, 网络丢包严重时可尝试关闭")
            }

            Section("额外参数") {
                TextEditor(text: $profile.extraArgs)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 110)
                    .overlay(alignment: .topLeading) {
                        if profile.extraArgs.isEmpty {
                            Text("每行一个 FreeRDP 参数，# 开头为注释\n例如 /kbd:remap:0x1e=0x1f")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                Text("这里的参数会原样追加到命令行末尾，可覆盖前面的设置。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .task(id: profile.binaryKind.rawValue + profile.customBinaryPath) {
            detectedVersion = nil
            if let url = FreeRDPBinary.resolve(for: profile) {
                let version = await Task.detached { FreeRDPBinary.versionString(of: url) }.value
                detectedVersion = version
            }
        }
    }
}
