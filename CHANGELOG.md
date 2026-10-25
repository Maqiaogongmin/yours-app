# Changelog

## 1.11.7+11178

- 修复同一次训练中重复同名动作互相覆盖的问题，按动作块保存每组记录。
- 保存替换动作的自定义参数与动作快照，冷启动后继续训练时保留替换结果。
- 同步备份与服务器同步中的动作身份、训练快照和数据库迁移。
- 修复训练记录标题中部分中文字形重影。
- Android 与 HarmonyOS 对齐 iOS 1.11.7 的共享业务代码。

## Unreleased

- Prepare the main Flutter application for public source distribution.
- Add AGPL-3.0-or-later licensing, App Store additional permission, source
  notices, security policy, contribution policy, and CI.
- Use the independent `yours-sync-server` repository as the authoritative
  self-hosted sync server implementation.

## 1.11.6+11176

- 调整训练计时中的组备注逻辑：计划动作备注可作为输入参考，但只有用户实际编辑后才写入训练记录。
- 支持已完成组的备注继续编辑，并通过本地草稿、训练记录和同步队列持久化。
- 训练结束时的练后备注与每组备注保持独立，训练记录页可分别查看和编辑。
- Android 版本已通过静态分析、180 项 Flutter 测试、模拟器运行验收和真机验收。
- 公开源码快照补入 HarmonyOS Flutter-OH 壳层、平台桥接、发布脚本和验收测试；签名资料、构建产物和本机发布状态不包含在仓库中。

## 1.11.5+11174

- 修复 Android Yours Vault 公共 Documents 目录初始化和 inbox 自动导入。
- 修复 MediaStore 重复导出产生 `manifest (1).json` 等副本的问题。
- 拆分 Android 平台桥接和高复杂度 Flutter 模块，补充关键单元测试与运行验收脚本。
- Android Release lint 降至 0，整体测试覆盖率提升至 71.85%，关键模块均超过 80%。

## 1.11.0

- 发布前清理源代码、内置数据和应用资源。
- 保留本地优先训练计划、训练记录、自定义动作库、备份和 Yours Vault 主线。
