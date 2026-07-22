# Changelog

## Unreleased

- Prepare the main Flutter application for public source distribution.
- Add AGPL-3.0-or-later licensing, App Store additional permission, source
  notices, security policy, contribution policy, and CI.
- Use the independent `yours-sync-server` repository as the authoritative
  self-hosted sync server implementation.

## 1.11.5+11174

- 修复 Android Yours Vault 公共 Documents 目录初始化和 inbox 自动导入。
- 修复 MediaStore 重复导出产生 `manifest (1).json` 等副本的问题。
- 拆分 Android 平台桥接和高复杂度 Flutter 模块，补充关键单元测试与运行验收脚本。
- Android Release lint 降至 0，整体测试覆盖率提升至 71.85%，关键模块均超过 80%。

## 1.11.0

- 发布前清理源代码、内置数据和应用资源。
- 保留本地优先训练计划、训练记录、自定义动作库、备份和 Yours Vault 主线。
