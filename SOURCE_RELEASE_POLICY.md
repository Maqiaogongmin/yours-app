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

执行发布前必须先使用 [Release Checklist](docs/release-checklist.md)，并按 [Release Record Template](docs/release-record-template.md) 留存证据。`tool/check_release_ready.dart` 只做只读预检；它不构建、不提交、不打 tag、不上传，也不能替代 App Store Connect 或 GitHub Release 的真实状态核验。

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
当前公开快照同步自内部 commit `014e1e8468ad61e1144a0ee132989096a6249602`，
项目版本为 `1.11.5+11174`。

App Store Connect 已核验的上一份公开基线：

- App ID: `6772104994`
- App Store version: `1.11.2`
- App Store state: `READY_FOR_SALE`
- App version state: `READY_FOR_DISTRIBUTION`
- Attached build ID: `2d9a3385-5619-4d89-a0aa-18d66c2aad26`
- Attached build number: `11136`
- Build processing state: `VALID`

本机构建记录可以确认内部 commit `9c040543acd78ee8f75f00dffe69e073547c999f`
紧接着生成了 iOS `1.11.2 (11136)` 构建和 Android 1.11.2 APK。

当前公开仓库 commit `75259ad1bd636d245e9e9f40d2baff0908726e9c` 是
基于该内部源码整理后的公开源码快照，包含开源文档、CI 固定、源码链接
和无用平台工程删除等发布整理改动。它可以作为 1.11.2 代码状态的公开、
可审计源码快照，但不声明为 App Store 当前二进制的逐字节可复现构建源。

当前 `1.11.5+11174` 公开源码快照对应 Android arm64-v8a 候选包。该包
通过 Release 健康门禁和 Redmi USB 真机运行验收，版本化证据见
`docs/releases/android-1.11.5+11174.md`。

下一个 iOS 或 Android 二进制发布应从公开仓库的已冻结 commit 构建，并在
发布前创建精确对应的版本 tag。
