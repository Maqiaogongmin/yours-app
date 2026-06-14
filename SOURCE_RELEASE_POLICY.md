# Source and Release Policy

## Source of truth

本仓库是有思 iOS 和 Android App 的源码来源。公开发布资料、Android APK 和校验值由 [YoursVault](https://github.com/Maqiaogongmin/YoursVault) 提供。

自托管同步服务器位于 [yours-sync-server](https://github.com/Maqiaogongmin/yours-sync-server)，不包含在本仓库中。

## Version mapping

每个正式二进制版本必须记录：

- App 显示版本；
- iOS build number 或 Android versionCode；
- 对应源码 commit 和不可移动 tag；
- 发布平台；
- Android APK SHA-256；
- App Store 或 GitHub Release 链接。

无法证明准确对应关系的历史二进制不会被标记为已验证源码版本。

## Release order

1. 冻结并测试源码 commit。
2. 从该 commit 构建二进制。
3. 创建版本 tag。
4. 发布源码归档和版本说明。
5. 发布 App Store 版本或 Android APK。

正式版本不得从未提交修改、临时副本或旧工程构建。

## Current snapshot

首次公开快照基于内部 commit `9c040543acd78ee8f75f00dffe69e073547c999f`，项目版本为 `1.11.2+11136`。

App Store Connect 已核验：

- App ID: `6772104994`
- App Store version: `1.11.2`
- App Store state: `READY_FOR_SALE`
- App version state: `READY_FOR_DISTRIBUTION`
- Attached build ID: `2d9a3385-5619-4d89-a0aa-18d66c2aad26`
- Attached build number: `11136`
- Build processing state: `VALID`

本机构建记录可以确认内部 commit `9c040543acd78ee8f75f00dffe69e073547c999f`
紧接着生成了 iOS `1.11.2 (11136)` 构建和 Android 1.11.2 APK。

当前公开仓库 tag `v1.11.2-public-source.1` 指向的提交是
基于该内部源码整理后的公开源码快照，包含开源文档、CI 固定、源码链接
和无用平台工程删除等发布整理改动。它可以作为 1.11.2 代码状态的公开、
可审计源码快照，但不声明为 App Store 当前二进制的逐字节可复现构建源。

下一个 iOS 或 Android 二进制发布应从公开仓库的已冻结 commit 构建，并在
发布前创建精确对应的版本 tag。
