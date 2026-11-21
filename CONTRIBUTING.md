# 贡献指南 / Contributing

欢迎提 Issue 和 PR！中英文皆可。Issues and PRs welcome, in Chinese or English.

## 开发环境

- macOS 14+，Xcode 或 Command Line Tools (Swift 6+)
- `brew install freerdp` (集成测试需要真实的 `sdl-freerdp`)

## 构建与测试

```bash
swift build           # 编译
swift test            # 全部测试 (含真实进程集成测试)
./build.sh dmg        # 出 DMG 包
python3 scripts/test_watchdog.py   # 看门狗三场景验证
```

## 架构约定

- `Sources/FreeRDPKit/` — 核心逻辑库，**不依赖 UI**，可单测：
  - 新增连接参数：`ConnectionProfile` 加字段 → `ArgumentBuilder` 加翻译 → 对应 Tab 加控件 → `ArgumentBuilderTests` 加断言，四步成套
- `Sources/FreeRDPClient/` — SwiftUI 薄界面层，逻辑尽量下沉到 Kit
- 进程生命周期相关改动必须跑 `SessionManagerTests` 与 `test_watchdog.py`，
  确保「应用死 → 连接死」不留孤儿

## 提交

- 一个 PR 只做一件事，说明动机与测试方式
- 不要提交构建产物 (`build/`、`.build/` 已在 .gitignore)
- 不要提交任何真实主机凭据；示例一律用 `192.168.1.100` / `rdp.example.com` 这类占位
