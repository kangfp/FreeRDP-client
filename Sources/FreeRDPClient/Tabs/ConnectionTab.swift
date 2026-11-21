import SwiftUI
import FreeRDPKit

struct ConnectionTab: View {
    @Binding var profile: ConnectionProfile

    @State private var password = ""
    @State private var gatewayPassword = ""

    var body: some View {
        Form {
            Section("服务器") {
                TextField("主机 / IP 地址", text: $profile.host, prompt: Text("如 192.168.1.100 或 rdp.example.com"))
                NumberField(title: "端口", value: $profile.port)
                TextField("窗口标题", text: $profile.windowTitle, prompt: Text("默认使用连接名称"))
            }

            Section("凭据") {
                TextField("用户名", text: $profile.username, prompt: Text("如 administrator 或 user@domain"))
                PasswordField(title: "密码", password: $password)
                TextField("域", text: $profile.domain, prompt: Text("工作组 / AD 域, 可留空"))
                Toggle("管理员会话 (+admin)", isOn: $profile.adminSession)
                Text("密码保存在 macOS 钥匙串中，不会写入配置文件。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("RD 网关") {
                Toggle("通过 RD Gateway 连接", isOn: $profile.gatewayEnabled)
                if profile.gatewayEnabled {
                    TextField("网关主机", text: $profile.gatewayHost, prompt: Text("如 gateway.example.com"))
                    NumberField(title: "网关端口", value: $profile.gatewayPort)
                    TextField("网关用户名", text: $profile.gatewayUsername)
                    TextField("网关域", text: $profile.gatewayDomain)
                    PasswordField(title: "网关密码", password: $gatewayPassword)
                    Picker("网关类型", selection: $profile.gatewayType) {
                        Text("自动").tag("auto")
                        Text("RPC over HTTP").tag("rpc")
                        Text("HTTP").tag("http")
                    }
                }
            }

            Section("自动重连") {
                Toggle("断线自动重连", isOn: $profile.autoReconnect)
                if profile.autoReconnect {
                    Stepper(value: $profile.autoReconnectMaxRetries, in: 0...1000) {
                        LabeledContent("最大重试次数") {
                            Text(profile.autoReconnectMaxRetries == 0 ? "无限" : "\(profile.autoReconnectMaxRetries)")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: loadPasswords)
        .onChange(of: profile.id) { _, _ in loadPasswords() }
        .onChange(of: password) { _, newValue in
            KeychainHelper.save(password: newValue, account: KeychainHelper.account(for: profile.id))
        }
        .onChange(of: gatewayPassword) { _, newValue in
            KeychainHelper.save(password: newValue, account: KeychainHelper.gatewayAccount(for: profile.id))
        }
    }

    private func loadPasswords() {
        password = KeychainHelper.load(account: KeychainHelper.account(for: profile.id)) ?? ""
        gatewayPassword = KeychainHelper.load(account: KeychainHelper.gatewayAccount(for: profile.id)) ?? ""
    }
}
