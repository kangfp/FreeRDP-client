import SwiftUI
import FreeRDPKit

struct DisplayTab: View {
    @Binding var profile: ConnectionProfile

    private let presets: [(String, Int, Int)] = [
        ("1920 × 1080 (Full HD)", 1920, 1080),
        ("2560 × 1440 (2K)", 2560, 1440),
        ("3840 × 2160 (4K)", 3840, 2160),
        ("1600 × 900", 1600, 900),
        ("1366 × 768", 1366, 768),
        ("1280 × 720", 1280, 720),
        ("1024 × 768", 1024, 768),
    ]

    var body: some View {
        Form {
            Section("分辨率") {
                Picker("模式", selection: $profile.resolutionMode) {
                    ForEach(ResolutionMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                switch profile.resolutionMode {
                case .fullscreen:
                    Text("全屏模式，会话中可用 Ctrl+Alt+Enter 切换全屏/窗口。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                case .window:
                    NumberField(title: "宽度", value: $profile.width)
                    NumberField(title: "高度", value: $profile.height)
                    LabeledContent("常用预设") {
                        Menu("选择…") {
                            ForEach(presets, id: \.0) { preset in
                                Button(preset.0) {
                                    profile.width = preset.1
                                    profile.height = preset.2
                                }
                            }
                        }
                        .frame(width: 160)
                    }
                case .percent:
                    Stepper(value: $profile.percent, in: 25...100, step: 5) {
                        LabeledContent("占本机屏幕") {
                            Text("\(profile.percent)%")
                        }
                    }
                }

                Toggle("窗口大小变化时自动调整远程分辨率", isOn: $profile.dynamicResolution)
                    .help("+dynamic-resolution")
                    .disabled(profile.resolutionMode == .fullscreen)
                Toggle("使用工作区 (避开菜单栏/Dock)", isOn: $profile.workarea)
                    .help("+workarea")
                Toggle("多显示器模式", isOn: $profile.multimon)
                    .help("+multimon, 全屏时每个显示器一个远程屏幕")
                Toggle("跨屏合并为一个大桌面", isOn: $profile.span)
                    .help("+span")
            }

            Section("画面") {
                Picker("颜色深度", selection: $profile.bpp) {
                    Text("16 位 (省带宽)").tag(16)
                    Text("24 位").tag(24)
                    Text("32 位 (推荐)").tag(32)
                }
                Picker("显示缩放", selection: $profile.scale) {
                    Text("100%").tag(100)
                    Text("140%").tag(140)
                    Text("180%").tag(180)
                }
                .help("/scale, HiDPI 屏幕上的远程内容缩放")
                Stepper(value: $profile.scaleDesktop, in: 100...500, step: 25) {
                    LabeledContent("远程桌面缩放") {
                        Text(profile.scaleDesktop == 100 ? "不缩放" : "\(profile.scaleDesktop)%")
                    }
                }
                .help("/scale-desktop, 让远程 Windows 放大 UI 元素")
                Toggle("智能缩放 (拉伸适应窗口)", isOn: $profile.smartSizing)
                    .help("+smart-sizing")
                Toggle("浮动工具栏 (全屏时显示)", isOn: $profile.floatbar)
                    .help("/floatbar")
            }
        }
        .formStyle(.grouped)
    }
}
