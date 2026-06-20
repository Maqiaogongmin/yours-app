# Yours UI Kit

Yours UI Kit 是有思内部的视觉基础设施层。它的角色类似 `localization/`：业务页面表达语义，视觉规则集中维护。

## Design Direction

- 保留暖橙主色、暖米浅色、紫黑深色。
- 保留圆角卡片、低噪声边框、克制阴影。
- 训练现场页面优先输入效率，不使用营销式大数字和无关装饰。
- `shareability` 后置；先让 App 内视觉系统稳定，再用分享卡反向校准。

## Layers

- `yours_design_tokens.dart`：语义 token，包括 tone、surface、text、radius、spacing。
- `yours_components.dart`：语义组件，例如 card、metric、status、time value、action。
- `yours_patterns.dart`：场景模板，例如 metric row、rest panel。
- `yours_design_system.dart`：barrel export，页面只从这里导入。

## Page Rules

- 页面优先使用 `YoursSurfaceCard`、`YoursMetricTile`、`YoursStatusPill`、`YoursTimeValue` 等语义组件。
- 新增页面代码不要直接新增裸 `Color(0x...)`、大段 `TextStyle` 或随意 `BoxShadow`。
- 若必须使用局部视觉细节，需要用短注释说明它属于特定场景，而不是新风格。
- 时间和数字必须按语义选择组件：训练总用时、本项用时、休息倒计时、开始时间和历史时间戳不能共用一种“大时钟”样式。

## First Migration Scope

- 首页训练记录卡已迁移到 surface card、metric row、status pill 和 note panel。
- 训练记录编辑的起始时间、本项用时和备注容器已接入共享 time/note 组件。
- 训练模式的 metric、rest panel 和 summary actions 已接入 UI Kit。

## Second Migration Scope

- 首页、计划页、动作库、设置页和用户页入口统一使用页面标题、列表卡、搜索、筛选、空状态和图标块语义。
- `YoursListActionCard` 统一处理点击、禁用、处理中、尾部箭头和最低触控高度。
- `YoursEmptyState` 统一处理说明、图标和可选操作。
- 页面只能导入 `yours_design_system.dart`；不要直接导入 UI Kit 内部文件。
- 数字 metric 和时间可以使用 condensed 字体；中文标题、正文、按钮保持系统字体。

## Pre-Phase-Three Closure Scope

- 计划编辑完整流程已接入 UI Kit，包括计划表单、周卡、日期编辑、动作列表、记录模式、目标参数和动作备注。
- 动作详情与动作编辑 Sheet 已接入统一 Sheet、表单、分组和操作按钮。
- 数据管理详情页已接入统一页面脚手架、状态面板、数据分区和管理操作容器；备份、Vault、iCloud、服务器同步逻辑不在 UI Kit 中。
- 关于有思 Sheet 和服务器同步设置 Sheet 已接入统一 Sheet 与表单组件。
- 深层页面已补 280px、1.4 字体倍率、深色主题 widget 覆盖。

本轮仍不做 `shareability`。分享海报、分享卡和外部传播视觉在 App 内视觉稳定后单独进入下一轮，并反向补充 card、metric、summary 语义。

## Phase 2.2 Hardening Scope

- `YoursManagementAction` 和 `YoursActionGroup` 统一承载备份、同步、恢复、危险操作和处理中状态。
- `YoursManagementAction` 支持 `density`，数据管理这类高密度工具页可使用 compact，保留同一套按钮语义但降低纵向重量。
- `YoursAsyncStatusPanel` 支持 `compactGrid`，常规宽度下用于 2x2 状态摘要，小屏或 1.4 字体倍率下仍自动纵向避让。
- `YoursStatBlock`、`YoursSummaryCard`、`YoursRecordCardPattern` 提供 shareability 前置语义：record、metric、summary、note、actions。
- 首页训练记录卡已迁移到 record pattern，后续分享海报应优先复用同一组语义，而不是重新写一套视觉。
- 数据管理操作已从零散按钮迁移到 management action 语义。
- 页面和导航目录中的历史 UI Guard allow 已清零。

## Shareability V1 Scope

- `shareability` 的产品定义是“生成训练记录海报”，不是外部分享、feed 发布或社交平台跳转。
- 单次/单日训练记录海报使用 `YoursWorkoutSharePoster`，固定 9:16 画布，并通过 `RepaintBoundary` 导出 PNG。
- 默认背景为深紫黑；可选背景为暖米、Ember、Forest，以及用户从系统“照片”应用选择的一张图片。
- 海报组件包括训练名称、日期、总用时、动作数、总组数、总容量、训练备注和 Yours 标识，均可显示或隐藏；空备注默认隐藏。
- 首页记录卡、训练记录详情页和训练完成页提供低调的 iOS 分享图标入口，语义为“生成海报”。
- 海报保存目标为 iOS“照片”应用；本阶段不保存到 Yours Backup / Yours Vault，也不保存用户模板或贴纸位置。
- 分享海报视觉集中在 `design_system` 与 `shareability` 模块维护，业务页面只传训练记录语义数据。

## Shareability V1 Device Feedback Rules

- 分享入口不得改变首页训练记录卡的信息密度；入口必须使用 `YoursRecordCardPattern.trailingAction` 或同等级语义动作位，不挤占标题、状态或指标布局。
- 首页当天只有自由记录时，记录卡只修正展示语义：显示“自由项目”，不显示“有效组”。自由记录模式的组数、重量、倒计时和完整训练流另开阶段处理。
- 海报背景、光晕、grain、panel、border、fg、muted 和 accent 必须集中在 `YoursSharePosterPalette`，不要在业务页面或海报子组件里散落颜色硬编码。
- 深紫黑与暖米海报背景保留 grain；Ember 和 Forest 使用纯渐变。照片背景只用于当前生成流程，并叠加稳定深色遮罩。
- 海报预览页使用固定中性 matte 背景，避免 App 浅色/深色主题影响用户判断导出效果。
- 训练海报中的 metric 数字使用 `RobotoCondensed`；中文标题、正文和按钮继续使用系统字体。
- AppIcon、LaunchImage 和分享入口不得出现旧品牌图形；如果真机仍出现旧图，先按安装缓存和派生资源路径复查，不把缓存误判成当前代码。

## Guard

运行：

```bash
dart run tool/check_ui_guard.dart
```

Guard 会扫描 `lib/redesign/pages/` 和 `lib/redesign/navigation/` 中新增或遗留的视觉硬编码。默认只报告，不失败。

CI 使用 baseline 阻止新增视觉硬编码：

```bash
dart run tool/check_ui_guard.dart --strict-new
```

当前 baseline 已收口为 0 个未解释发现，页面和导航目录不应再出现常驻 allow。新增或保留局部视觉必须满足其中一种条件：

- 迁移到 `design_system/` 的 token、component 或 pattern。
- 在同一行添加 `yours-ui-guard: allow`，并写明为什么这是少量场景特例；不能使用泛化的 legacy 理由。

只有在明确完成一批历史清理后，才更新 baseline：

```bash
dart run tool/check_ui_guard.dart --update-baseline
```

`--strict` 现在应保持通过，用来确认页面和导航目录没有未解释的视觉硬编码。
