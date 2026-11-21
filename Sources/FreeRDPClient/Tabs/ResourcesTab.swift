import SwiftUI
import FreeRDPKit

struct ResourcesTab: View {
    @Binding var profile: ConnectionProfile

    private let timezonePresets = [
        "China Standard Time",
        "Tokyo Standard Time",
        "Singapore Standard Time",
        "UTC",
        "Pacific Standard Time",
        "Eastern Standard Time",
        "W. Europe Standard Time",
    ]

    var body: some View {
        Form {
            Section("剪贴板") {
                Toggle("共享剪贴板", isOn: $profile.clipboard)
                    .help("-clipboard 关闭")
                if profile.clipboard {
                    Picker("方向", selection: $profile.clipboardDirection) {
                        ForEach(ClipboardDirection.allCases) { d in
                            Text(d.label).tag(d)
                        }
                    }
                    Toggle("允许复制文件", isOn: $profile.clipboardFiles)
                        .help("files-to:off 关闭文件剪贴板")
                }
            }

            Section("驱动器重定向") {
                Toggle("重定向本机主目录", isOn: $profile.homeDrive)
                    .help("+home-drive")
                Toggle("重定向所有挂载点", isOn: $profile.allDrives)
                    .help("+drives")
                ForEach($profile.drives) { $drive in
                    HStack(spacing: 6) {
                        TextField("名称", text: $drive.name)
                            .frame(width: 80)
                        TextField("本机文件夹路径", text: $drive.path)
                        Button {
                            chooseFolder { url in
                                drive.path = url.path
                                if drive.name.isEmpty {
                                    drive.name = url.lastPathComponent
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.borderless)
                        .help("选择文件夹")
                        Button {
                            profile.drives.removeAll { $0.id == drive.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                        .help("移除")
                    }
                }
                Button {
                    profile.drives.append(DriveRedirect(name: "", path: ""))
                } label: {
                    Label("添加文件夹", systemImage: "plus")
                }
                Text("添加后，远程会话的「此电脑」里会出现对应的网络驱动器。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("音频") {
                Picker("远程声音", selection: $profile.soundMode) {
                    ForEach(SoundMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                Toggle("重定向麦克风到远程", isOn: $profile.microphone)
                    .help("/microphone, 首次使用 macOS 会请求麦克风权限")
            }

            Section("其他设备") {
                Toggle("打印机", isOn: $profile.printer)
                    .help("/printer")
                Toggle("智能卡", isOn: $profile.smartcard)
                    .help("/smartcard")
                Toggle("USB 设备 (自动, 实验性)", isOn: $profile.usbAuto)
                    .help("/usb:auto, 需要服务端支持且可能不稳定")
            }

            Section("键盘与时区") {
                TextField("键盘布局", text: $profile.keyboardLayout,
                          prompt: Text("留空自动检测, 如 0x00000804 (中文) 或 0x00000409 (美式)"))
                    .help("/kbd:layout:")
                Toggle("Unicode 输入", isOn: $profile.keyboardUnicode)
                    .help("/kbd:unicode, 中文输入法建议开启")
                Toggle("抓取键盘 (快捷键发送到远程)", isOn: $profile.grabKeyboard)
                    .help("-grab-keyboard 关闭后系统快捷键保留在本机")
                LabeledContent("时区重定向") {
                    HStack {
                        TextField("留空不发送", text: $profile.timezone)
                            .frame(maxWidth: 220)
                        Menu("常用") {
                            ForEach(timezonePresets, id: \.self) { tz in
                                Button(tz) { profile.timezone = tz }
                            }
                            Divider()
                            Button("清空") { profile.timezone = "" }
                        }
                        .frame(width: 80)
                    }
                }
                .help("/timezone, 需使用 Windows 时区名称")
            }
        }
        .formStyle(.grouped)
    }
}
