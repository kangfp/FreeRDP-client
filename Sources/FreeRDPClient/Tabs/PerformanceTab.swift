import SwiftUI
import FreeRDPKit

struct PerformanceTab: View {
    @Binding var profile: ConnectionProfile

    var body: some View {
        Form {
            Section("网络") {
                Picker("连接速度", selection: $profile.network) {
                    ForEach(NetworkType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .help("/network, 决定默认启用哪些性能优化")
                Text("局域网选 LAN 可获得最佳画质；跨互联网建议「自动检测」或 WAN。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("图形") {
                Picker("图形管线", selection: $profile.gfxMode) {
                    ForEach(GfxMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .help("/gfx, RDP8+ 图形管线, 现代 Windows 建议保持自动或 AVC444")
                Toggle("压缩", isOn: $profile.compression)
                    .help("-compression 关闭")
                Toggle("JPEG 编码 (照片类画面省带宽)", isOn: $profile.jpeg)
                    .help("+jpeg")
                if profile.jpeg {
                    LabeledContent("JPEG 质量") {
                        HStack {
                            Slider(value: Binding(
                                get: { Double(profile.jpegQuality) },
                                set: { profile.jpegQuality = Int($0) }
                            ), in: 10...100, step: 5)
                            Text("\(profile.jpegQuality)")
                                .monospacedDigit()
                                .frame(width: 32)
                        }
                        .frame(maxWidth: 280)
                    }
                }
            }

            Section("桌面效果") {
                Toggle("桌面壁纸", isOn: $profile.wallpaper)
                    .help("+wallpaper, 关闭可显著减少带宽")
                Toggle("字体平滑 (ClearType)", isOn: $profile.fontSmoothing)
                    .help("-fonts 关闭")
                Toggle("视觉主题", isOn: $profile.themes)
                    .help("-themes 关闭")
                Toggle("菜单动画", isOn: $profile.menuAnims)
                    .help("+menu-anims")
                Toggle("完整窗口拖动", isOn: $profile.windowDrag)
                    .help("+window-drag")
                Toggle("桌面合成 (Aero)", isOn: $profile.aero)
                    .help("+aero")
            }
        }
        .formStyle(.grouped)
    }
}
