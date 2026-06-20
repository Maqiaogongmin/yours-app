// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '有思';

  @override
  String get tabHome => '首页';

  @override
  String get tabPlan => '训练计划';

  @override
  String get tabExercises => '动作库';

  @override
  String get tabProfile => '用户';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonSave => '保存';

  @override
  String get commonAdd => '添加';

  @override
  String get commonClose => '关闭';

  @override
  String get commonRestore => '恢复';

  @override
  String get commonSettings => '设置';

  @override
  String get commonTest => '测试';

  @override
  String get commonSyncNow => '立即同步';

  @override
  String get commonPendingSync => '待同步';

  @override
  String get commonSynced => '已同步';

  @override
  String get commonUnknownError => '未知错误';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get aboutYours => '关于有思（Yours）';

  @override
  String get officialWebsite => '官网';

  @override
  String get githubRepository => 'GitHub 仓库';

  @override
  String get planTitle => '训练计划';

  @override
  String get planCreate => '新建';

  @override
  String get planNewName => '新训练计划';

  @override
  String get planActive => '使用中';

  @override
  String get planArchived => '已归档';

  @override
  String get planArchive => '归档';

  @override
  String get planRestoreActive => '恢复使用';

  @override
  String get planNoActive => '还没有训练计划。';

  @override
  String get planNoArchived => '还没有已归档的训练计划。';

  @override
  String get planNone => '暂无训练计划';

  @override
  String planCount(int count) {
    return '共 $count 个计划 · 本地优先';
  }

  @override
  String get planSwipeHint => '左滑计划可以进行编辑或删除';

  @override
  String get planScheduleReady => '已完成编排';

  @override
  String get planScheduleIncomplete => '编排未完成';

  @override
  String get planDeleteTitle => '删除训练计划';

  @override
  String planDeleteMessage(String name) {
    return '确定要删除「$name」吗？此操作会先在本地生效，并进入待同步队列。';
  }

  @override
  String planLocalSaveFailed(String error) {
    return '本地训练计划保存失败：$error';
  }

  @override
  String get planDaySelection => '训练日选择';

  @override
  String planSummary(int weeks, int days) {
    return '$weeks 周 · 每周 $days 天';
  }

  @override
  String planScheduledDays(String summary, int count) {
    return '$summary · 已编排 $count 个训练日';
  }

  @override
  String planWeek(int week) {
    return '第 $week 周';
  }

  @override
  String get planMarkWeekComplete => '标记为已完成';

  @override
  String get planUnmarkWeekComplete => '取消完成标记';

  @override
  String get planNoActions => '当天未安排动作，点击添加';

  @override
  String get planRestoreArchivedTitle => '恢复使用这份计划？';

  @override
  String get planRestoreArchivedMessage => '已归档计划需要先恢复为使用中，才能开始训练。';

  @override
  String planDatabaseInitFailed(String error) {
    return '本地训练数据库初始化失败：$error';
  }

  @override
  String get planEditTitle => '编辑训练计划';

  @override
  String get planName => '计划名称';

  @override
  String get planCycle => '训练周期';

  @override
  String get planWeeksSuffix => ' 周  (1–12)';

  @override
  String get planDaysPerWeek => '每周训练日';

  @override
  String get planDaysSuffix => ' 天  (1–7)';

  @override
  String get planArrangement => '动作安排';

  @override
  String planDayTitle(int week, int day) {
    return '第 $week 周 · D$day';
  }

  @override
  String get planDayName => '训练日名称';

  @override
  String get planAddExercise => '添加动作';

  @override
  String planActionList(int count) {
    return '动作列表 ($count)';
  }

  @override
  String get planNoExerciseHint => '还没有动作。点击「添加动作」从动作库选择。';

  @override
  String get planRemove => '移除';

  @override
  String get planSetSuffix => '组';

  @override
  String get planRepSuffix => '次';

  @override
  String get planRest => '休息';

  @override
  String get planDuration => '持续时间';

  @override
  String get planWeight => '重量';

  @override
  String get planNoteHint => '备注：例如 RIR 2；次数范围 6-8；动作节奏慢下放';

  @override
  String get planAddFromLibrary => '从动作库添加';

  @override
  String planSelectedCount(int count) {
    return '已选 $count';
  }

  @override
  String get planSearchLibrary => '搜索本地动作库';

  @override
  String get planNoMatchingExercise => '没有找到匹配动作。可以先到动作库页面添加。';

  @override
  String get planAdded => '已添加';

  @override
  String get workoutEndTitle => '结束训练？';

  @override
  String get workoutEndIncomplete => '当前训练计划还没有完成。已记录的训练数据会保留，并自动备注“未完成训练计划”。';

  @override
  String get workoutEndEmpty => '当前训练还没有保存任何组记录。确认后会直接关闭训练模式。';

  @override
  String get workoutPostNote => '练后备注';

  @override
  String get workoutPostNoteHint => '例如：肩部不适，放弃侧平举';

  @override
  String get workoutEnd => '结束训练';

  @override
  String get workoutTimer => '训练计时';

  @override
  String get workoutSummary => '训练总结';

  @override
  String get workoutDefaultDay => '默认训练日';

  @override
  String get workoutElapsed => '用时';

  @override
  String get workoutExercise => '动作';

  @override
  String get workoutCurrentExercise => '当前动作';

  @override
  String get workoutRestSeconds => '休息时间 s';

  @override
  String get workoutSaveSet => '保存本组并继续';

  @override
  String get workoutUndoSet => '撤销当前组记录';

  @override
  String get workoutRestBetween => '组间休息';

  @override
  String get workoutNextSet => '进入下一组';

  @override
  String get workoutSkipRest => '跳过休息，进入下一组';

  @override
  String get workoutComplete => '训练完成';

  @override
  String get workoutFinishSave => '结束并保存训练';

  @override
  String get workoutOptional => '可空';

  @override
  String get workoutNote => '备注';

  @override
  String get workoutTrainingNote => '训练备注';

  @override
  String workoutSavedBackup(String name) {
    return '训练已保存，并已自动备份：$name';
  }

  @override
  String workoutSavedBackupFailed(String error) {
    return '训练已保存，但自动备份失败：$error';
  }

  @override
  String get workoutSetUndone => '已撤销当前组记录';

  @override
  String get workoutFirstSet => '已经是第一组了';

  @override
  String get workoutLastSet => '已经是最后一组了';

  @override
  String workoutTimerStartFailed(String error) {
    return '训练计时启动失败：$error';
  }

  @override
  String get workoutNoActions => '这个训练计划还没有可执行动作。请先编辑计划并补充动作。';

  @override
  String get workoutNextSummary => '下一步：训练总结';

  @override
  String workoutNextSetLabel(String exercise, int set) {
    return '下一组：$exercise · 第 $set 组';
  }

  @override
  String get workoutUndoReturnLog => '撤销当前组，返回记录页';

  @override
  String get workoutRestHint => '倒计时结束后会停在这里；滑动只浏览，不会写入或撤销记录。';

  @override
  String workoutCompletedSummary(int exercises, int sets) {
    return '完成 $exercises 个动作 · $sets 组';
  }

  @override
  String get workoutUndoLastReturnLog => '撤销最后一组，返回记录页';

  @override
  String get workoutNoteHint => '例如：RIR 2；休息 120s；次数范围 6-8';

  @override
  String get homeTodayStatus => '今日状态';

  @override
  String homeMonthTitle(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get homeWeekdays => '一,二,三,四,五,六,日';

  @override
  String homeDateTitle(int month, int day, String name) {
    return '$month月$day日 · $name';
  }

  @override
  String get homeNoWorkout => '暂无训练';

  @override
  String get homeNoWorkoutRecord => '当天还没有训练记录';

  @override
  String get homeRecorded => '已记录';

  @override
  String get homeIncomplete => '未完成';

  @override
  String get homeTotalVolume => '总训练量 kg';

  @override
  String get homeEffectiveSets => '有效组';

  @override
  String get homeMinutes => '分钟';

  @override
  String get homeEmptyRecordMessage => '当天还没有记录。完成训练后，这里会自动显示训练量、组数、时长和备注。';

  @override
  String get homeDefaultRecordName => '训练记录';

  @override
  String get homeDefaultIncompleteRecordName => '未完成训练';

  @override
  String get homeDefaultSavedNote => '当天训练已保存到本地数据库。';

  @override
  String get homeIncompleteWorkoutMarker => '未完成训练计划';

  @override
  String get homeRecordUpdated => '训练记录已更新';

  @override
  String homeSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get homeDeleteSessionTitle => '删除本次训练记录？';

  @override
  String homeDeleteSessionMessage(String time, int count) {
    return '将删除 $time 的训练记录及其 $count 组数据。这个操作会进入服务器同步队列。';
  }

  @override
  String get homeSessionDeleted => '本次训练记录已删除';

  @override
  String homeDeleteFailed(String error) {
    return '删除失败：$error';
  }

  @override
  String homeWorkoutRecordTitle(int month, int day) {
    return '$month月$day日训练记录';
  }

  @override
  String get homeSaving => '保存中...';

  @override
  String get homeNoSetRecords => '当天还没有可查看的训练组记录。';

  @override
  String homeSetCount(int count) {
    return '$count 组';
  }

  @override
  String homeRecordCount(int count) {
    return '$count 组记录';
  }

  @override
  String homeStartedAt(String time) {
    return '$time 开始';
  }

  @override
  String get homeSets => '组数';

  @override
  String get homeReps => '次数';

  @override
  String get homeWeightKg => '重量 kg';

  @override
  String homeSetNote(String exercise, int setIndex, String note) {
    return '$exercise · 第 $setIndex 组\n$note';
  }

  @override
  String get homeDashboardSettings => '仪表盘设置';

  @override
  String get homeCalendar => '日历';

  @override
  String get commonDone => '完成';

  @override
  String get sharePosterCreate => '生成海报';

  @override
  String get sharePosterTitle => '生成海报';

  @override
  String get sharePosterSaveToPhotos => '保存到照片';

  @override
  String get sharePosterSaving => '正在保存';

  @override
  String get sharePosterSavedToPhotos => '已保存到照片';

  @override
  String sharePosterSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get sharePosterRenderFailed => '无法生成训练海报图片。';

  @override
  String sharePosterPhotoFailed(String error) {
    return '选择照片失败：$error';
  }

  @override
  String get sharePosterBackground => '背景';

  @override
  String get sharePosterComponents => '组件';

  @override
  String get sharePosterUsePhoto => '使用照片';

  @override
  String get sharePosterPhotoSelected => '照片背景';

  @override
  String get sharePosterPresetDeepPurple => '深紫黑';

  @override
  String get sharePosterPresetWarmPaper => '暖米';

  @override
  String get sharePosterPresetEmber => 'Ember';

  @override
  String get sharePosterPresetForest => 'Forest';

  @override
  String get sharePosterWorkoutName => '训练名称';

  @override
  String get sharePosterDate => '日期';

  @override
  String get sharePosterDuration => '总用时';

  @override
  String get sharePosterExerciseCount => '动作数';

  @override
  String get sharePosterSetCount => '总组数';

  @override
  String get sharePosterTotalVolume => '总容量';

  @override
  String get sharePosterNote => '训练备注';

  @override
  String get sharePosterBrand => 'Yours 标识';

  @override
  String get exerciseLibrary => '动作库';

  @override
  String get profileTitle => '用户';

  @override
  String get dataManagement => '数据管理';

  @override
  String get profileProcessingData => '正在处理数据...';

  @override
  String get profileAboutLinks => '官网、GitHub 仓库';

  @override
  String get profileAboutLinksUpdate => '官网、GitHub 仓库、检查更新';

  @override
  String profileNewVersion(String version) {
    return '发现新版本 $version';
  }

  @override
  String get profileVaultPathPending => '路径准备中';

  @override
  String get profileVaultNotExported => '尚未导出';

  @override
  String profileLastVaultExport(String date) {
    return '上次导出：$date';
  }

  @override
  String get profileExportVault => '导出 Vault';

  @override
  String get profileImportInbox => '导入 inbox';

  @override
  String get profileBackupDescription => '创建后可保存到文件 App 或其他位置';

  @override
  String get profileBackupPlaintextWarning => '备份文件包含训练数据，请妥善保存，不要公开分享。';

  @override
  String get profileBackupAndroidLocation =>
      '备份文件包含训练数据，请妥善保存。Android 可在 Documents/有思/backups 中查看。';

  @override
  String get profileBackupNotCreated => '尚未创建';

  @override
  String profileLastBackup(String date) {
    return '上次备份：$date';
  }

  @override
  String profileLatestBackup(String name) {
    return '最新备份：$name';
  }

  @override
  String get profileProcessing => '处理中...';

  @override
  String get profileCreateExport => '创建并导出';

  @override
  String get profileRestoreFromFile => '从文件恢复';

  @override
  String get profileExportBackup => '导出备份';

  @override
  String get profileRestoreFromICloud => '从 iCloud 恢复';

  @override
  String get profileCopyDiagnostics => '复制诊断';

  @override
  String get profileLocalDataSafety => '本地数据安全';

  @override
  String get profileProcessingDataShort => '正在处理数据';

  @override
  String get profileExportingVault => '正在导出 Vault';

  @override
  String get profileNotCreated => '未创建';

  @override
  String get profileAvailable => '已有';

  @override
  String get profileManualExport => '手动导出';

  @override
  String get profileFile => '文件';

  @override
  String get profileReading => '读取中';

  @override
  String profilePendingCount(int count) {
    return '$count 条';
  }

  @override
  String get profileConfigured => '已配置';

  @override
  String get profileNotConfigured => '未配置';

  @override
  String get profileServerNotConfigured => '未配置服务器同步地址';

  @override
  String get profileServerConfiguredHint => '已配置服务器地址，建议先测试连接';

  @override
  String profileServerConnectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get profileNoServerSnapshot => '暂无服务器快照';

  @override
  String profileRecentSnapshot(String date) {
    return '最近快照：$date';
  }

  @override
  String profileServerDetail(String backup, int events, int cursor) {
    return '$backup，事件 $events 条，游标 $cursor';
  }

  @override
  String get profileCheckingICloud => '正在检查 iCloud Drive 状态';

  @override
  String get profileICloudAvailable => 'iCloud Drive 可用。';

  @override
  String get profileICloudManualHint => '用于手动导出和恢复';

  @override
  String get profileICloudSignedOut => '当前设备未登录 iCloud，或 iCloud Drive 未启用。';

  @override
  String get profileICloudContainerUnavailable =>
      '当前设备没有可用的 iCloud 数据目录。请检查 iCloud Drive 与 App ID 配置。';

  @override
  String get profileICloudUnsupported => '当前平台不支持 iCloud Drive。';

  @override
  String get profileICloudUnknown => 'iCloud Drive 状态未知。';

  @override
  String get profileLocalFirstRecord => '本地优先训练记录';

  @override
  String get profileToggleDark => '切换到夜间模式';

  @override
  String get profileToggleLight => '切换到白天模式';

  @override
  String get profileServer => '服务器';

  @override
  String get profileCheckUpdates => '检查更新';

  @override
  String get profileCheckingUpdates => '正在检查...';

  @override
  String get profileUpToDate => '当前已是最新版本';

  @override
  String get profileUpdateFailed => '暂时无法检查更新';

  @override
  String get profileAndroidUpdate => '检查 Android APK 新版本';

  @override
  String profileNewVersionDownload(String version) {
    return '发现新版本 $version，去官网下载';
  }

  @override
  String get profileServerSettings => '服务器备份设置';

  @override
  String get profileServerAddress => 'Yours 备份服务器地址';

  @override
  String get profileApiKeyOptional => 'API 密钥（可选）';

  @override
  String get profileApiKeyHint => '留空则不发送 Authorization';

  @override
  String get profileClear => '清空';

  @override
  String get serverSync => '服务器同步';

  @override
  String get icloudDrive => 'iCloud Drive';

  @override
  String get backupPackage => '备份包';

  @override
  String get notCategorized => '未分类';

  @override
  String get noDescription => '暂无介绍';

  @override
  String get all => '全部';

  @override
  String get exerciseAdd => '添加动作';

  @override
  String get exerciseEdit => '编辑动作';

  @override
  String get exerciseSearchHint => '搜索动作，例如 卧推 / 深蹲 / 划船';

  @override
  String get exerciseEmpty => '本地动作库还没有动作。点击右上角「添加」先建立你的精选动作。';

  @override
  String get exerciseNoMatch => '没有找到匹配动作。可以尝试切换分类或清空搜索。';

  @override
  String get exerciseLocalSubtitle => '本地精选动作 · 离线可用';

  @override
  String get exerciseName => '名称';

  @override
  String get exerciseCategoryOne => '分类 1';

  @override
  String get exerciseCategoryTwo => '分类 2';

  @override
  String get exerciseDescription => '介绍';

  @override
  String get exerciseSaveLocal => '保存到本地动作库';

  @override
  String get exerciseNotFilled => '未填写';

  @override
  String get profileOpenLinkFailed => '无法打开链接。';

  @override
  String profileRecentVaultExport(String name) {
    return '最近已导出 Vault：$name';
  }

  @override
  String profileVaultExportSummary(int plans, int workouts, int exercises) {
    return 'Yours Vault 已导出：$plans 个计划、$workouts 份记录、$exercises 个动作。';
  }

  @override
  String profileVaultExportAndroidSummary(int plans, int workouts, int exercises) {
    return 'Yours Vault 已导出：$plans 个计划、$workouts 份记录、$exercises 个动作。公共 Documents 会在后台同步。';
  }

  @override
  String profileRecentVaultExportFailed(String error) {
    return '最近导出 Vault 失败：$error';
  }

  @override
  String profileVaultExportFailed(String error) {
    return 'Yours Vault 导出失败：$error';
  }

  @override
  String profileVaultImportSummary(int plans, int exercises, String skipped) {
    return '已从 inbox 导入 $plans 个计划、$exercises 个动作$skipped。';
  }

  @override
  String profileSkippedFiles(int count) {
    return '，跳过 $count 个文件';
  }

  @override
  String profileVaultImportFailed(String error) {
    return 'Yours Vault 导入失败：$error';
  }

  @override
  String profileBackupCreated(String name) {
    return '备份包已创建：$name';
  }

  @override
  String profileBackupFailed(String error) {
    return '备份失败：$error';
  }

  @override
  String profileRecentBackupExport(String name) {
    return '最近已导出备份：$name';
  }

  @override
  String profileBackupExportedICloud(String name) {
    return '备份包已导出到 iCloud Drive：$name';
  }

  @override
  String profileRecentExportFailed(String error) {
    return '最近导出失败：$error';
  }

  @override
  String profileICloudExportFailed(String error) {
    return 'iCloud Drive 导出失败：$error';
  }

  @override
  String profilePickBackupFailed(String error) {
    return '选择备份包失败：$error';
  }

  @override
  String get profilePickBackupCancelled => '已取消选择备份包。';

  @override
  String get profileRestoreBackupTitle => '从备份包恢复？';

  @override
  String profileRestoreBackupMessage(String name) {
    return '将从 $name 恢复训练计划、训练记录和动作库。恢复前会自动创建安全快照。';
  }

  @override
  String profileRecentRestoreFailed(String error) {
    return '最近恢复失败：$error';
  }

  @override
  String profilePickICloudBackupFailed(String error) {
    return '选择 iCloud Drive 备份包失败：$error';
  }

  @override
  String get profilePickICloudBackupCancelled => '已取消选择 iCloud Drive 备份包。';

  @override
  String get profileRestoreICloudTitle => '从 iCloud Drive 恢复？';

  @override
  String get profileRestoringICloud => '正在从 iCloud Drive 恢复备份...';

  @override
  String get profileICloudRestoreComplete => 'iCloud Drive 恢复完成';

  @override
  String profileRecentICloudRestore(String name) {
    return '最近已从 iCloud Drive 恢复：$name';
  }

  @override
  String get profileServerAddressSaved => '服务器备份地址已保存。';

  @override
  String get profileServerAddressCleared => '已清空服务器备份地址。';

  @override
  String get profileConfigureServerFirst => '请先配置服务器备份地址。';

  @override
  String get profileConfigureServerSyncFirst => '请先配置服务器同步地址。';

  @override
  String profileServerSyncFailed(String error) {
    return '服务器同步失败：$error';
  }

  @override
  String get profileServerSyncComplete => '服务器同步完成。';

  @override
  String get profileServerAlreadyLatest => '已是最新，并刷新服务器快照。';

  @override
  String profileServerSyncSummary(int uploaded, int downloaded, int applied) {
    return '已上传 $uploaded 条变化，拉取 $downloaded 条服务器事件，应用 $applied 条。';
  }

  @override
  String get profileServerBackupFound => '发现服务器备份';

  @override
  String get profileServerBackupFoundMessage => '这台设备还没有本地训练数据。服务器上已有备份，是否恢复到本机？恢复前会自动创建本地安全快照。';

  @override
  String get profileRestoreToDevice => '恢复到本机';

  @override
  String get profileNormalSyncFailed => '普通同步失败';

  @override
  String profileNormalSyncFailedMessage(String error) {
    return '普通同步失败：$error\n\n可以尝试从服务器备份恢复本机。恢复前会自动创建本地安全快照。';
  }

  @override
  String get profileRestoreFromBackup => '从备份恢复';

  @override
  String profileServerAvailable(int version, int events) {
    return '服务器同步可用：协议 v$version，事件 $events 条。';
  }

  @override
  String profileServerTestFailed(String error) {
    return '服务器连接测试失败：$error';
  }

  @override
  String get profileDiagnosticsCopied => '服务器同步诊断信息已复制。';

  @override
  String get profileDiagnosticsFallbackCopied => '诊断生成不完整，已复制基础错误信息。';

  @override
  String get profileRestoreComplete => '恢复完成';

  @override
  String profileRestoreSummary(int count, String snapshot) {
    return '已恢复 $count 个文件。\n安全快照：$snapshot\n\n页面数据已重新加载。';
  }

  @override
  String get profileAcknowledged => '知道了';

  @override
  String profileRestoreFailed(String error) {
    return '恢复失败：$error';
  }

  @override
  String get profileServerRestoreComplete => '服务器恢复完成';

  @override
  String profileServerSnapshotRestoreFailed(String error) {
    return '服务器快照恢复失败：$error';
  }

  @override
  String get profileDatabasePreparing => '数据库刚刚完成恢复，连接正在重新准备。请稍后重试。';

  @override
  String get profileServerReturnedHtml => '服务器返回了网页页面，请检查地址是否为 Yours 备份服务器。';

  @override
  String get profileTargetServer => '目标服务器';

  @override
  String get planRecordModeStandard => '标准记录';

  @override
  String get planRecordModeFree => '自由记录';

  @override
  String get workoutRecordMode => '记录方式';

  @override
  String get workoutReplaceExercise => '替换本次动作';

  @override
  String get workoutChooseExercise => '选择';

  @override
  String workoutExerciseReplaced(String from, String to) {
    return '已将「$from」替换为「$to」';
  }

  @override
  String get workoutCompleteFreeRecord => '完成本项';

  @override
  String get workoutUndoFreeRecord => '撤销本项记录';

  @override
  String get workoutActivityElapsed => '本项用时';

  @override
  String get workoutDurationSeconds => '持续时间 s';

  @override
  String get workoutSavedLocal => '训练已保存到本地。';

  @override
  String workoutCompletedMixedSummary(int exercises, int sets, int freeRecords) {
    return '完成 $exercises 个动作 · $sets 组 · $freeRecords 个自由项目';
  }

  @override
  String get homeFreeRecords => '自由项目';

  @override
  String homeSessionRecordCount(int sets, int freeRecords) {
    return '$sets 组 · $freeRecords 个自由项目';
  }

  @override
  String homeActivityRecordCount(int count) {
    return '$count 个活动记录';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsDescription => '外观、语言与关于有思';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceDescription => '主题与显示方式';

  @override
  String get themeTitle => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get languageDescription => '选择有思使用的语言';

  @override
  String get aboutDescription => '官网、版本与更新';

  @override
  String settingsCurrentValue(String value) {
    return '当前：$value';
  }

  @override
  String get errorBackupMissing => '备份包不存在。';

  @override
  String get errorBackupEmpty => '服务器返回的备份包为空。';

  @override
  String get errorInvalidBackup => '所选文件不是有效的有思备份包。';

  @override
  String get errorBackupManifestMissing => '备份包缺少 manifest.json，无法确认格式。';

  @override
  String get errorBackupDatabaseMissing => '备份包缺少必要数据库文件。';

  @override
  String get errorInvalidServerAddress => '服务器地址格式不正确，请使用 https://example.com 这样的格式。';

  @override
  String get errorServerTimeout => '网络超时。请检查服务器地址、HTTPS 和当前网络。';

  @override
  String get errorServerTls => 'HTTPS 握手失败。请检查服务器域名、证书和当前网络。';

  @override
  String get errorServerUnreachable => '无法连接服务器。请检查地址、端口、HTTPS 和反向代理配置。';

  @override
  String get errorServerInterrupted => '网络请求被中断。请检查服务器地址和当前网络。';

  @override
  String get errorInvalidServerResponse => '服务器返回格式不正确。请确认地址指向有思自托管同步服务。';

  @override
  String get errorInvalidServerEvents => '服务器事件接口返回格式不正确。';

  @override
  String get errorInvalidServerStatus => '服务器状态接口返回格式不正确。';

  @override
  String get errorNoServerBackup => '没有找到可恢复的备份包。';

  @override
  String errorServerOutdated(int current, int required) {
    return '自托管同步服务版本过旧。当前协议 v$current，需要 v$required。';
  }

  @override
  String errorUnappliedServerChanges(int count) {
    return '有 $count 条服务器变化暂时无法应用，建议从服务器备份恢复本机。';
  }

  @override
  String get backupShareTitle => '导出有思备份包';

  @override
  String get backupShareSubject => '有思备份包';

  @override
  String get backupShareText => '这是有思备份包。你可以将它保存到 iCloud Drive、文件 App 或其他位置，需要时再从文件恢复。';

  @override
  String get exerciseExampleName => '例如：杠铃卧推';

  @override
  String get exerciseExampleCategory => '例如：胸部';

  @override
  String get exerciseExampleEquipment => '例如：杠铃';

  @override
  String get yoursVaultName => 'Yours Vault';
}
