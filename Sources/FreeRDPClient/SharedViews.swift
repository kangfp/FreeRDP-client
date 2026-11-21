import SwiftUI
import AppKit

/// 密码输入行：明文/密文切换
struct PasswordField: View {
    let title: String
    @Binding var password: String
    @State private var revealed = false

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                Group {
                    if revealed {
                        TextField("", text: $password)
                    } else {
                        SecureField("", text: $password)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 240)
                Button {
                    revealed.toggle()
                } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .help(revealed ? "隐藏密码" : "显示密码")
            }
        }
    }
}

/// 数字输入行
struct NumberField: View {
    let title: String
    @Binding var value: Int
    var width: CGFloat = 90

    var body: some View {
        LabeledContent(title) {
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: width)
        }
    }
}

/// 选择文件夹（驱动器重定向用）
func chooseFolder(completion: @escaping (URL) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.prompt = "选择"
    panel.begin { response in
        if response == .OK, let url = panel.url {
            completion(url)
        }
    }
}

/// 选择可执行文件（自定义客户端路径用）
func chooseExecutable(completion: @escaping (URL) -> Void) {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    panel.showsHiddenFiles = true
    panel.prompt = "选择"
    panel.begin { response in
        if response == .OK, let url = panel.url {
            completion(url)
        }
    }
}
