import SwiftUI
import FreeRDPKit

struct SecurityTab: View {
    @Binding var profile: ConnectionProfile

    var body: some View {
        Form {
            Section("安全协议") {
                Picker("协议", selection: $profile.securityProtocol) {
                    ForEach(SecurityProtocol.allCases) { p in
                        Text(p.label).tag(p)
                    }
                }
                .help("/sec")
                Text(protocolHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("服务器证书") {
                Picker("校验策略", selection: $profile.certPolicy) {
                    ForEach(CertPolicy.allCases) { policy in
                        Text(policy.label).tag(policy)
                    }
                }
                .help("/cert")
                if profile.certPolicy == .ignore {
                    Label("忽略证书校验有中间人攻击风险，仅建议在完全可信的内网使用。",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else if profile.certPolicy == .tofu {
                    Text("首次连接自动信任证书，之后若证书变化则拒绝连接。自签名证书环境 (如 GNOME Remote Desktop) 推荐此项。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("TLS 兼容 (老旧服务器)") {
                Picker("TLS 安全级别", selection: $profile.tlsSeclevel) {
                    Text("默认 (1)").tag(-1)
                    ForEach(0...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                .help("/tls:seclevel, 连接老系统握手失败时可降到 0")
                Picker("强制 TLS 版本", selection: $profile.tlsEnforce) {
                    Text("自动").tag("")
                    Text("TLS 1.0 (Windows 7)").tag("1.0")
                    Text("TLS 1.1").tag("1.1")
                    Text("TLS 1.2").tag("1.2")
                    Text("TLS 1.3").tag("1.3")
                }
                .help("/tls:enforce")
            }

            Section("其他") {
                Toggle("受限管理模式 (Restricted Admin)", isOn: $profile.restrictedAdmin)
                    .help("+restricted-admin, 凭据不发送到服务器")
            }
        }
        .formStyle(.grouped)
    }

    private var protocolHint: String {
        switch profile.securityProtocol {
        case .auto: return "默认自动协商，兼容绝大多数服务器 (Windows / GNOME Remote Desktop / xrdp)。"
        case .nla: return "网络级认证：先验证身份再建立会话，Windows 推荐。需要正确的用户名密码。"
        case .tls: return "仅 TLS 加密。服务器未启用 NLA 时使用。"
        case .rdp: return "旧式 RDP 加密，安全性弱，仅在服务器不支持 TLS 时使用。"
        case .ext: return "NLA 扩展协议 (CredSSP 之外)。"
        case .aad: return "Azure Active Directory 认证，用于 AVD / Windows 365。"
        }
    }
}
