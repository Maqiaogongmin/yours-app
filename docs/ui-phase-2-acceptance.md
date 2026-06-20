# 有思第二阶段 UI 验收矩阵

日期：2026-06-15

## 自动化验收

| 页面 | 已覆盖状态 |
| --- | --- |
| 首页 | 空记录、训练记录卡、长训练备注 |
| 计划页 | 使用中、已归档、空状态、长标题、同步状态、滑动编辑/删除、归档/恢复菜单 |
| 动作库 | 搜索、分类筛选、无结果、长动作卡、详情 Sheet、添加入口 |
| 设置页 | 外观入口、语言入口、关于回调 |
| 用户页 | 账户卡、数据管理入口、设置入口、设置导航 |

公共边界：

- 280px 宽度和 1.4 字体倍率无 overflow。
- 中英文混合长标题、日文长分类和长说明可换行或省略。
- UI Kit disabled、busy、empty action 和搜索清除状态有组件测试。
- 页面通过 `yours_design_system.dart` barrel 使用 UI Kit。

## 模拟器验收

目标设备：iPhone 17 Pro，简体中文，浅色主题。

| 页面 | 正常字体 | 1.4 字体 | 检查项 |
| --- | --- | --- | --- |
| 首页 | [通过](screenshots/ui-phase-2/home-normal.jpg) | [通过](screenshots/ui-phase-2/home-xxl.jpg) | 标题、日历、记录卡、长备注 |
| 计划页 | [通过](screenshots/ui-phase-2/plan-normal.jpg) | [通过](screenshots/ui-phase-2/plan-xxl.jpg) | 筛选、计划卡、菜单、滑动区域 |
| 动作库 | [通过](screenshots/ui-phase-2/exercises-normal.jpg) | [通过](screenshots/ui-phase-2/exercises-xxl.jpg) | 搜索、横向筛选、动作卡、空状态 |
| 设置页 | [通过](screenshots/ui-phase-2/settings-normal.jpg) | [通过](screenshots/ui-phase-2/settings-xxl.jpg) | 入口卡、外观和语言选项 |
| 用户页 | [通过](screenshots/ui-phase-2/profile-normal.jpg) | [通过](screenshots/ui-phase-2/profile-xxl.jpg) | 账户、数据管理和设置入口 |

模拟器检查结论：

- 五页均无 RenderFlex overflow、文字遮挡或异常缩放。
- 底部导航已补充 button、selected 和 label 语义。
- 计划页隐藏的滑动操作不再进入辅助功能语义树，展开后仍可操作。

## 防回退

- CI 顺序：静态分析、UI Guard `--strict-new`、UI Kit/入口页测试、全量测试、Android debug 构建。
- `tool/ui_guard_baseline.json` 记录历史硬编码；新增裸颜色、文字样式和阴影会失败。
- 深层编辑页、数据管理详情、暗色页面级精修和 shareability 留到后续阶段。
