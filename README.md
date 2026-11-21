# FreeRDP 客户端 (macOS)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

中文 | [English](README.en.md)

给命令行版 FreeRDP 套上的原生 macOS 图形界面。SwiftUI 编写，把常用参数全部做成图形选项，
连接配置可保存、复制、搜索，密码存 macOS 钥匙串，会话带实时日志。

> **非官方项目**：本项目是 [FreeRDP](https://www.freerdp.com) 的第三方图形前端，
> 独立开发维护，与 FreeRDP 官方项目无隶属关系。仓库不包含 FreeRDP 源码或二进制，
> FreeRDP 本身采用 Apache-2.0 许可证，由用户自行安装。

<!-- 添加界面截图后取消注释:
![界面](docs/screenshot.png)
-->

## 功能

- **连接管理**：多配置保存/复制/删除/搜索，双击侧栏「连接」上下文菜单即可发起会话
- **六个设置页**，覆盖 FreeRDP 常用参数：
  - **连接**：主机/端口/用户名/密码/域、窗口标题、管理员会话、RD Gateway、自动重连
  - **显示**：全屏/指定分辨率/屏幕百分比、动态分辨率、多显示器、跨屏、色深、HiDPI 缩放、智能缩放、浮动工具栏
  - **性能**：网络类型 (LAN/WAN/…)、图形管线 (自动/Progressive/H.264 AVC420/AVC444/RemoteFX/关闭)、压缩、JPEG、壁纸/字体平滑/主题/动画等桌面效果
  - **本地资源**：剪贴板 (含方向与文件剪贴板)、文件夹重定向 (图形选择)、主目录/全部挂载点、声音三模式、麦克风、打印机、智能卡、USB、键盘布局/Unicode/抓取、时区
  - **安全**：协议协商 (自动/NLA/TLS/RDP/Ext/AAD)、证书策略 (TOFU/忽略/严格)、TLS 安全级别与版本强制 (兼容老服务器)、受限管理模式
  - **高级**：客户端选择 (sdl-freerdp/xfreerdp/自定义路径)、日志级别、连接超时、防锁屏、多传输通道、额外参数 (每行一个)
- **命令行预览**：一键查看将要执行的完整命令 (密码打码)，可复制
- **会话管理**：实时日志、断开、退出码显示、清理已结束会话
- **生命周期跟随**：关闭主窗口即退出应用并断开所有会话；应用崩溃或被强制退出时，
  看门狗包装进程会在 ~1 秒内检测到并自动终止 FreeRDP 连接，不留孤儿进程

## 安全设计

- 密码保存在 **macOS 钥匙串**，不写入配置文件 (配置文件权限 0600)
- 启动时参数通过 `/args-from:stdin` 逐行传入，**密码不会出现在 `ps` 进程列表**
- 证书默认 **TOFU** (首次信任)：自签名证书环境 (如 GNOME Remote Desktop) 开箱即用，证书变化时拒绝连接

## 环境要求

- macOS 14+
- FreeRDP 3：`brew install freerdp` (使用其中的 `sdl-freerdp`，原生 SDL3，无需 XQuartz)
- 构建需要 Xcode 或 Command Line Tools (Swift 6+)

## 安装 (使用者)

1. 安装 FreeRDP (本应用调用系统中的 `sdl-freerdp`)：
   ```bash
   brew install freerdp
   ```
2. 从 [Releases](../../releases) 下载 `FreeRDPClient-<版本>.dmg`，双击打开，把图标拖进 Applications。

> **首次打开提示**：DMG 为 ad-hoc 签名 (未做 Apple 付费公证)，从网上下载后
> Gatekeeper 可能拦截。右键点应用 →「打开」→ 确认一次即可；或执行：
> ```bash
> xattr -dr com.apple.quarantine /Applications/FreeRDPClient.app
> ```

## 从源码构建 (开发者)

```bash
./build.sh            # 构建, 产物 build/FreeRDPClient.app
./build.sh install    # 构建并安装到 /Applications
./build.sh dmg        # 构建并生成拖拽安装 DMG
swift test            # 单元测试 + 真实进程集成测试
```

## 使用提示

- **连 Windows**：默认设置即可 (自动协商 + NLA)。老系统 (Win7) 连不上时，到「安全」页把 TLS 安全级别降为 0、强制 TLS 1.0。
- **连 Ubuntu GNOME Remote Desktop**：协议保持自动，证书 TOFU；GRD 要求 NLA 用户名密码，凭据填 GRD 里设置的那组。
- **中文输入**：保持「Unicode 输入」开启；键盘布局留空自动检测。
- **全屏切换**：会话中 `Ctrl+Alt+Enter`。
- **文件互传**：「本地资源」页添加文件夹重定向，远程「此电脑」里会出现网络驱动器；或直接开剪贴板文件复制。
- 重新构建后首次读取密码，macOS 可能弹窗询问钥匙串访问 (ad-hoc 签名身份变化所致)，点「始终允许」即可。

## 项目结构

```
Sources/FreeRDPKit/        核心库 (可单测)
  ConnectionProfile.swift  配置模型 (Codable)
  ArgumentBuilder.swift    配置 → FreeRDP 参数
  ProfileStore.swift       JSON 持久化
  KeychainHelper.swift     钥匙串读写
  FreeRDPBinary.swift      客户端定位
  SessionManager.swift     子进程/日志/断开
Sources/FreeRDPClient/     SwiftUI 界面
Tests/FreeRDPKitTests/     参数构建单元测试
scripts/                   图标生成等辅助脚本
build.sh                   一键构建 .app
```

## 进程生命周期设计

每个会话经 `/bin/sh` 看门狗脚本包装启动 (脚本内嵌于 `SessionManager.watchdogScript`)：

- FreeRDP 作为看门狗的后台子进程，参数仍经 stdin 传入 (`<&0` 显式继承)
- 看门狗每秒检查应用进程是否存活；应用死亡 (退出/崩溃/强退) 即终止 FreeRDP
- 终止采用「先 TERM 后 KILL」：FreeRDP 在早期连接阶段收到 SIGTERM 可能不退出
  (信号标志被连接流程消费)，宽限 3 秒后 SIGKILL 兜底
- 应用正常退出时 `applicationWillTerminate` 主动清理全部会话 (同样有 KILL 兜底)
- 关窗口即退应用：SwiftUI 不可靠响应 `applicationShouldTerminateAfterLastWindowClosed`，
  改用 `NSWindow.willCloseNotification` 观察器显式触发 `NSApp.terminate`

验证：`swift test` 含两个真实进程集成测试；`python3 scripts/test_watchdog.py` 覆盖
父进程强杀 / SIGTERM / 子进程自退三种场景。

## 已知限制

- 会话内证书/凭据交互弹窗由 sdl-freerdp 自己的 SDL 对话框处理；本客户端默认 TOFU + 显式凭据，正常流程无需交互
- 尚未支持 .rdp 文件导入/导出 (后续可加)

## 许可证

本项目以 [MIT License](LICENSE) 开源。

- 仓库仅包含图形前端的原创代码，不包含、不链接 FreeRDP 源码或二进制
- [FreeRDP](https://github.com/FreeRDP/FreeRDP) 是独立项目，采用 Apache-2.0 许可证，由用户通过 Homebrew 自行安装
- 界面图标使用 Apple SF Symbols，遵循其许可条款 (仅限运行于 Apple 平台的应用)
