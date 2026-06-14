# 有思 Yours

有思是一款本地优先的个人训练记录 App。它用于管理训练计划、训练计时、训练记录、自定义动作库、备份包和 Yours Vault，并让用户能够把长期训练数据交给自己选择的 AI agents 和工具分析。

## 核心原则

- **本地优先**：训练数据先写入设备本地 SQLite，训练过程不依赖在线账号。
- **数据自主**：支持备份、恢复、Yours Vault 导出和可选的自托管同步。
- **开放协作**：Yours Vault 使用可审阅文件连接用户自己的 agents 和工具链。
- **移动优先**：官方维护和发布重点为 iOS 与 Android。

## 仓库分工

- 本仓库：有思 Flutter 主 App 源码。
- [YoursVault](https://github.com/Maqiaogongmin/YoursVault)：安装包、校验值、版本说明、Vault 协议和 Agent Skill。
- [Yours Sync Server](https://github.com/Maqiaogongmin/yours-sync-server)：协议 v2 自托管同步服务器，独立采用 Apache-2.0。

App 内部数据库不是外部工具接口。外部工具应通过 Yours Vault 或公开同步协议协作，不应直接修改 App 数据库。

## 开发

环境要求：

- Flutter stable，Dart `>=3.10.0 <4.0.0`
- iOS 构建需要 macOS 与 Xcode
- Android 构建需要 Android SDK

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

主要目录：

- `lib/redesign/`：当前 App 主体、数据层和页面。
- `assets/data/`：有思内置动作 seed 和空白演示数据。
- `tool/yours_cli/`：面向 Yours Vault 和 agents 的本地命令行工具。
- `test/`：数据、同步、平台和界面行为测试。

`pubspec.yaml` 保留 `publish_to: "none"`，避免误发布到 pub.dev。

## 支持范围

- iOS、Android：官方维护和发布目标。
- 自托管同步：使用 `protocolVersion: 2` 和 `identityMode: syncId`。

未使用且没有正式发布记录的 macOS、Windows、Linux runner 未纳入本仓库。

## 许可证

本项目作为一个整体按 **GNU Affero General Public License v3.0 or later** 发布，并附带 [App Store Additional Permission](APP_STORE_EXCEPTION.md)。

官方 App Store 版本可以收费。收费不改变接收者依据 AGPL 获得、修改和再分发对应源码的权利。源码版本与发布二进制的对应关系记录在 [SOURCE_RELEASE_POLICY.md](SOURCE_RELEASE_POLICY.md) 和 GitHub Releases 中。

有思最早从开源健身项目 [wger](https://github.com/wger-project/flutter) 的代码和工程实践中起步，后来经过持续拆解、重写和产品方向调整。详细来源与第三方归属见 [NOTICE.md](NOTICE.md) 和 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 反馈与贡献

当前欢迎通过 GitHub Issues 报告问题和提出建议。Pull Request 可以提交，但项目暂不承诺评审或合并；详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

安全问题请按 [SECURITY.md](SECURITY.md) 私下报告，不要公开提交密钥、认证绕过或数据暴露细节。
