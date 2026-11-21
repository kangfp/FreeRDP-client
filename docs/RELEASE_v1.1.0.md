# v1.1.0 — 首个开源版本

原生 SwiftUI macOS 客户端，为命令行 FreeRDP 提供完整图形界面。

## 亮点

- 🎛 **六个设置页**覆盖 FreeRDP 常用参数：连接 (含 RD Gateway) / 显示 / 性能 / 本地资源 / 安全 / 高级
- 🗂 **连接配置管理**：保存 / 复制 / 删除 / 搜索
- 🔐 **密码存 macOS 钥匙串**，经 `/args-from:stdin` 传参，不出现在 `ps` 进程列表
- 📜 **命令行预览** (密码打码) + **会话实时日志**
- 🔗 **生命周期跟随**：关窗口即断开所有会话；应用崩溃/被强退时看门狗 ~1 秒内自动清理连接，不留孤儿进程
- 🛡 证书默认 TOFU，自签名环境 (GNOME Remote Desktop 等) 开箱即用

## 安装

1. 安装 FreeRDP：`brew install freerdp`
2. 下载下方 `FreeRDPClient-1.1.0.dmg`，打开后把应用拖进 Applications
3. **首次打开**：ad-hoc 签名未经 Apple 公证，若被 Gatekeeper 拦截，右键点应用 →「打开」→ 确认；或执行：
   ```bash
   xattr -dr com.apple.quarantine /Applications/FreeRDPClient.app
   ```

## 环境要求

- macOS 14 或更高
- FreeRDP 3 (Homebrew)

## 校验和

```
SHA256 (FreeRDPClient-1.1.0.dmg) =
bb2b69657e6ad5383cbea3761d451539818c70eaae99893dbbac881fe1f48fb1
```

## 说明

本项目为 FreeRDP 的非官方第三方前端，与 FreeRDP 官方项目无隶属关系。
仓库不含 FreeRDP 源码或二进制；FreeRDP 采用 Apache-2.0 许可证，由用户自行安装。
本客户端以 MIT 许可证开源。
