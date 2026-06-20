import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ja'), Locale('zh')];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'有思'**
  String get appName;

  /// No description provided for @tabHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get tabHome;

  /// No description provided for @tabPlan.
  ///
  /// In zh, this message translates to:
  /// **'训练计划'**
  String get tabPlan;

  /// No description provided for @tabExercises.
  ///
  /// In zh, this message translates to:
  /// **'动作库'**
  String get tabExercises;

  /// No description provided for @tabProfile.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get tabProfile;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonRestore.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get commonRestore;

  /// No description provided for @commonSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get commonSettings;

  /// No description provided for @commonTest.
  ///
  /// In zh, this message translates to:
  /// **'测试'**
  String get commonTest;

  /// No description provided for @commonSyncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get commonSyncNow;

  /// No description provided for @commonPendingSync.
  ///
  /// In zh, this message translates to:
  /// **'待同步'**
  String get commonPendingSync;

  /// No description provided for @commonSynced.
  ///
  /// In zh, this message translates to:
  /// **'已同步'**
  String get commonSynced;

  /// No description provided for @commonUnknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get commonUnknownError;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @aboutYours.
  ///
  /// In zh, this message translates to:
  /// **'关于有思（Yours）'**
  String get aboutYours;

  /// No description provided for @officialWebsite.
  ///
  /// In zh, this message translates to:
  /// **'官网'**
  String get officialWebsite;

  /// No description provided for @githubRepository.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 仓库'**
  String get githubRepository;

  /// No description provided for @planTitle.
  ///
  /// In zh, this message translates to:
  /// **'训练计划'**
  String get planTitle;

  /// No description provided for @planCreate.
  ///
  /// In zh, this message translates to:
  /// **'新建'**
  String get planCreate;

  /// No description provided for @planNewName.
  ///
  /// In zh, this message translates to:
  /// **'新训练计划'**
  String get planNewName;

  /// No description provided for @planActive.
  ///
  /// In zh, this message translates to:
  /// **'使用中'**
  String get planActive;

  /// No description provided for @planArchived.
  ///
  /// In zh, this message translates to:
  /// **'已归档'**
  String get planArchived;

  /// No description provided for @planArchive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get planArchive;

  /// No description provided for @planRestoreActive.
  ///
  /// In zh, this message translates to:
  /// **'恢复使用'**
  String get planRestoreActive;

  /// No description provided for @planNoActive.
  ///
  /// In zh, this message translates to:
  /// **'还没有训练计划。'**
  String get planNoActive;

  /// No description provided for @planNoArchived.
  ///
  /// In zh, this message translates to:
  /// **'还没有已归档的训练计划。'**
  String get planNoArchived;

  /// No description provided for @planNone.
  ///
  /// In zh, this message translates to:
  /// **'暂无训练计划'**
  String get planNone;

  /// No description provided for @planCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个计划 · 本地优先'**
  String planCount(int count);

  /// No description provided for @planSwipeHint.
  ///
  /// In zh, this message translates to:
  /// **'左滑计划可以进行编辑或删除'**
  String get planSwipeHint;

  /// No description provided for @planScheduleReady.
  ///
  /// In zh, this message translates to:
  /// **'已完成编排'**
  String get planScheduleReady;

  /// No description provided for @planScheduleIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'编排未完成'**
  String get planScheduleIncomplete;

  /// No description provided for @planDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除训练计划'**
  String get planDeleteTitle;

  /// No description provided for @planDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除「{name}」吗？此操作会先在本地生效，并进入待同步队列。'**
  String planDeleteMessage(String name);

  /// No description provided for @planLocalSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'本地训练计划保存失败：{error}'**
  String planLocalSaveFailed(String error);

  /// No description provided for @planDaySelection.
  ///
  /// In zh, this message translates to:
  /// **'训练日选择'**
  String get planDaySelection;

  /// No description provided for @planSummary.
  ///
  /// In zh, this message translates to:
  /// **'{weeks} 周 · 每周 {days} 天'**
  String planSummary(int weeks, int days);

  /// No description provided for @planScheduledDays.
  ///
  /// In zh, this message translates to:
  /// **'{summary} · 已编排 {count} 个训练日'**
  String planScheduledDays(String summary, int count);

  /// No description provided for @planWeek.
  ///
  /// In zh, this message translates to:
  /// **'第 {week} 周'**
  String planWeek(int week);

  /// No description provided for @planMarkWeekComplete.
  ///
  /// In zh, this message translates to:
  /// **'标记为已完成'**
  String get planMarkWeekComplete;

  /// No description provided for @planUnmarkWeekComplete.
  ///
  /// In zh, this message translates to:
  /// **'取消完成标记'**
  String get planUnmarkWeekComplete;

  /// No description provided for @planNoActions.
  ///
  /// In zh, this message translates to:
  /// **'当天未安排动作，点击添加'**
  String get planNoActions;

  /// No description provided for @planRestoreArchivedTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复使用这份计划？'**
  String get planRestoreArchivedTitle;

  /// No description provided for @planRestoreArchivedMessage.
  ///
  /// In zh, this message translates to:
  /// **'已归档计划需要先恢复为使用中，才能开始训练。'**
  String get planRestoreArchivedMessage;

  /// No description provided for @planDatabaseInitFailed.
  ///
  /// In zh, this message translates to:
  /// **'本地训练数据库初始化失败：{error}'**
  String planDatabaseInitFailed(String error);

  /// No description provided for @planEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑训练计划'**
  String get planEditTitle;

  /// No description provided for @planName.
  ///
  /// In zh, this message translates to:
  /// **'计划名称'**
  String get planName;

  /// No description provided for @planCycle.
  ///
  /// In zh, this message translates to:
  /// **'训练周期'**
  String get planCycle;

  /// No description provided for @planWeeksSuffix.
  ///
  /// In zh, this message translates to:
  /// **' 周  (1–12)'**
  String get planWeeksSuffix;

  /// No description provided for @planDaysPerWeek.
  ///
  /// In zh, this message translates to:
  /// **'每周训练日'**
  String get planDaysPerWeek;

  /// No description provided for @planDaysSuffix.
  ///
  /// In zh, this message translates to:
  /// **' 天  (1–7)'**
  String get planDaysSuffix;

  /// No description provided for @planArrangement.
  ///
  /// In zh, this message translates to:
  /// **'动作安排'**
  String get planArrangement;

  /// No description provided for @planDayTitle.
  ///
  /// In zh, this message translates to:
  /// **'第 {week} 周 · D{day}'**
  String planDayTitle(int week, int day);

  /// No description provided for @planDayName.
  ///
  /// In zh, this message translates to:
  /// **'训练日名称'**
  String get planDayName;

  /// No description provided for @planAddExercise.
  ///
  /// In zh, this message translates to:
  /// **'添加动作'**
  String get planAddExercise;

  /// No description provided for @planActionList.
  ///
  /// In zh, this message translates to:
  /// **'动作列表 ({count})'**
  String planActionList(int count);

  /// No description provided for @planNoExerciseHint.
  ///
  /// In zh, this message translates to:
  /// **'还没有动作。点击「添加动作」从动作库选择。'**
  String get planNoExerciseHint;

  /// No description provided for @planRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get planRemove;

  /// No description provided for @planSetSuffix.
  ///
  /// In zh, this message translates to:
  /// **'组'**
  String get planSetSuffix;

  /// No description provided for @planRepSuffix.
  ///
  /// In zh, this message translates to:
  /// **'次'**
  String get planRepSuffix;

  /// No description provided for @planRest.
  ///
  /// In zh, this message translates to:
  /// **'休息'**
  String get planRest;

  /// No description provided for @planDuration.
  ///
  /// In zh, this message translates to:
  /// **'持续时间'**
  String get planDuration;

  /// No description provided for @planWeight.
  ///
  /// In zh, this message translates to:
  /// **'重量'**
  String get planWeight;

  /// No description provided for @planNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'备注：例如 RIR 2；次数范围 6-8；动作节奏慢下放'**
  String get planNoteHint;

  /// No description provided for @planAddFromLibrary.
  ///
  /// In zh, this message translates to:
  /// **'从动作库添加'**
  String get planAddFromLibrary;

  /// No description provided for @planSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count}'**
  String planSelectedCount(int count);

  /// No description provided for @planSearchLibrary.
  ///
  /// In zh, this message translates to:
  /// **'搜索本地动作库'**
  String get planSearchLibrary;

  /// No description provided for @planNoMatchingExercise.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配动作。可以先到动作库页面添加。'**
  String get planNoMatchingExercise;

  /// No description provided for @planAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加'**
  String get planAdded;

  /// No description provided for @workoutEndTitle.
  ///
  /// In zh, this message translates to:
  /// **'结束训练？'**
  String get workoutEndTitle;

  /// No description provided for @workoutEndIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'当前训练计划还没有完成。已记录的训练数据会保留，并自动备注“未完成训练计划”。'**
  String get workoutEndIncomplete;

  /// No description provided for @workoutEndEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前训练还没有保存任何组记录。确认后会直接关闭训练模式。'**
  String get workoutEndEmpty;

  /// No description provided for @workoutPostNote.
  ///
  /// In zh, this message translates to:
  /// **'练后备注'**
  String get workoutPostNote;

  /// No description provided for @workoutPostNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：肩部不适，放弃侧平举'**
  String get workoutPostNoteHint;

  /// No description provided for @workoutEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束训练'**
  String get workoutEnd;

  /// No description provided for @workoutTimer.
  ///
  /// In zh, this message translates to:
  /// **'训练计时'**
  String get workoutTimer;

  /// No description provided for @workoutSummary.
  ///
  /// In zh, this message translates to:
  /// **'训练总结'**
  String get workoutSummary;

  /// No description provided for @workoutDefaultDay.
  ///
  /// In zh, this message translates to:
  /// **'默认训练日'**
  String get workoutDefaultDay;

  /// No description provided for @workoutElapsed.
  ///
  /// In zh, this message translates to:
  /// **'用时'**
  String get workoutElapsed;

  /// No description provided for @workoutExercise.
  ///
  /// In zh, this message translates to:
  /// **'动作'**
  String get workoutExercise;

  /// No description provided for @workoutCurrentExercise.
  ///
  /// In zh, this message translates to:
  /// **'当前动作'**
  String get workoutCurrentExercise;

  /// No description provided for @workoutRestSeconds.
  ///
  /// In zh, this message translates to:
  /// **'休息时间 s'**
  String get workoutRestSeconds;

  /// No description provided for @workoutSaveSet.
  ///
  /// In zh, this message translates to:
  /// **'保存本组并继续'**
  String get workoutSaveSet;

  /// No description provided for @workoutUndoSet.
  ///
  /// In zh, this message translates to:
  /// **'撤销当前组记录'**
  String get workoutUndoSet;

  /// No description provided for @workoutRestBetween.
  ///
  /// In zh, this message translates to:
  /// **'组间休息'**
  String get workoutRestBetween;

  /// No description provided for @workoutNextSet.
  ///
  /// In zh, this message translates to:
  /// **'进入下一组'**
  String get workoutNextSet;

  /// No description provided for @workoutSkipRest.
  ///
  /// In zh, this message translates to:
  /// **'跳过休息，进入下一组'**
  String get workoutSkipRest;

  /// No description provided for @workoutComplete.
  ///
  /// In zh, this message translates to:
  /// **'训练完成'**
  String get workoutComplete;

  /// No description provided for @workoutFinishSave.
  ///
  /// In zh, this message translates to:
  /// **'结束并保存训练'**
  String get workoutFinishSave;

  /// No description provided for @workoutOptional.
  ///
  /// In zh, this message translates to:
  /// **'可空'**
  String get workoutOptional;

  /// No description provided for @workoutNote.
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get workoutNote;

  /// No description provided for @workoutTrainingNote.
  ///
  /// In zh, this message translates to:
  /// **'训练备注'**
  String get workoutTrainingNote;

  /// No description provided for @workoutSavedBackup.
  ///
  /// In zh, this message translates to:
  /// **'训练已保存，并已自动备份：{name}'**
  String workoutSavedBackup(String name);

  /// No description provided for @workoutSavedBackupFailed.
  ///
  /// In zh, this message translates to:
  /// **'训练已保存，但自动备份失败：{error}'**
  String workoutSavedBackupFailed(String error);

  /// No description provided for @workoutSetUndone.
  ///
  /// In zh, this message translates to:
  /// **'已撤销当前组记录'**
  String get workoutSetUndone;

  /// No description provided for @workoutFirstSet.
  ///
  /// In zh, this message translates to:
  /// **'已经是第一组了'**
  String get workoutFirstSet;

  /// No description provided for @workoutLastSet.
  ///
  /// In zh, this message translates to:
  /// **'已经是最后一组了'**
  String get workoutLastSet;

  /// No description provided for @workoutTimerStartFailed.
  ///
  /// In zh, this message translates to:
  /// **'训练计时启动失败：{error}'**
  String workoutTimerStartFailed(String error);

  /// No description provided for @workoutNoActions.
  ///
  /// In zh, this message translates to:
  /// **'这个训练计划还没有可执行动作。请先编辑计划并补充动作。'**
  String get workoutNoActions;

  /// No description provided for @workoutNextSummary.
  ///
  /// In zh, this message translates to:
  /// **'下一步：训练总结'**
  String get workoutNextSummary;

  /// No description provided for @workoutNextSetLabel.
  ///
  /// In zh, this message translates to:
  /// **'下一组：{exercise} · 第 {set} 组'**
  String workoutNextSetLabel(String exercise, int set);

  /// No description provided for @workoutUndoReturnLog.
  ///
  /// In zh, this message translates to:
  /// **'撤销当前组，返回记录页'**
  String get workoutUndoReturnLog;

  /// No description provided for @workoutRestHint.
  ///
  /// In zh, this message translates to:
  /// **'倒计时结束后会停在这里；滑动只浏览，不会写入或撤销记录。'**
  String get workoutRestHint;

  /// No description provided for @workoutCompletedSummary.
  ///
  /// In zh, this message translates to:
  /// **'完成 {exercises} 个动作 · {sets} 组'**
  String workoutCompletedSummary(int exercises, int sets);

  /// No description provided for @workoutUndoLastReturnLog.
  ///
  /// In zh, this message translates to:
  /// **'撤销最后一组，返回记录页'**
  String get workoutUndoLastReturnLog;

  /// No description provided for @workoutNoteHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：RIR 2；休息 120s；次数范围 6-8'**
  String get workoutNoteHint;

  /// No description provided for @homeTodayStatus.
  ///
  /// In zh, this message translates to:
  /// **'今日状态'**
  String get homeTodayStatus;

  /// No description provided for @homeMonthTitle.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月'**
  String homeMonthTitle(int year, int month);

  /// No description provided for @homeWeekdays.
  ///
  /// In zh, this message translates to:
  /// **'一,二,三,四,五,六,日'**
  String get homeWeekdays;

  /// No description provided for @homeDateTitle.
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日 · {name}'**
  String homeDateTitle(int month, int day, String name);

  /// No description provided for @homeNoWorkout.
  ///
  /// In zh, this message translates to:
  /// **'暂无训练'**
  String get homeNoWorkout;

  /// No description provided for @homeNoWorkoutRecord.
  ///
  /// In zh, this message translates to:
  /// **'当天还没有训练记录'**
  String get homeNoWorkoutRecord;

  /// No description provided for @homeRecorded.
  ///
  /// In zh, this message translates to:
  /// **'已记录'**
  String get homeRecorded;

  /// No description provided for @homeIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'未完成'**
  String get homeIncomplete;

  /// No description provided for @homeTotalVolume.
  ///
  /// In zh, this message translates to:
  /// **'总训练量 kg'**
  String get homeTotalVolume;

  /// No description provided for @homeEffectiveSets.
  ///
  /// In zh, this message translates to:
  /// **'有效组'**
  String get homeEffectiveSets;

  /// No description provided for @homeMinutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get homeMinutes;

  /// No description provided for @homeEmptyRecordMessage.
  ///
  /// In zh, this message translates to:
  /// **'当天还没有记录。完成训练后，这里会自动显示训练量、组数、时长和备注。'**
  String get homeEmptyRecordMessage;

  /// No description provided for @homeDefaultRecordName.
  ///
  /// In zh, this message translates to:
  /// **'训练记录'**
  String get homeDefaultRecordName;

  /// No description provided for @homeDefaultIncompleteRecordName.
  ///
  /// In zh, this message translates to:
  /// **'未完成训练'**
  String get homeDefaultIncompleteRecordName;

  /// No description provided for @homeDefaultSavedNote.
  ///
  /// In zh, this message translates to:
  /// **'当天训练已保存到本地数据库。'**
  String get homeDefaultSavedNote;

  /// No description provided for @homeIncompleteWorkoutMarker.
  ///
  /// In zh, this message translates to:
  /// **'未完成训练计划'**
  String get homeIncompleteWorkoutMarker;

  /// No description provided for @homeRecordUpdated.
  ///
  /// In zh, this message translates to:
  /// **'训练记录已更新'**
  String get homeRecordUpdated;

  /// No description provided for @homeSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String homeSaveFailed(String error);

  /// No description provided for @homeDeleteSessionTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除本次训练记录？'**
  String get homeDeleteSessionTitle;

  /// No description provided for @homeDeleteSessionMessage.
  ///
  /// In zh, this message translates to:
  /// **'将删除 {time} 的训练记录及其 {count} 组数据。这个操作会进入服务器同步队列。'**
  String homeDeleteSessionMessage(String time, int count);

  /// No description provided for @homeSessionDeleted.
  ///
  /// In zh, this message translates to:
  /// **'本次训练记录已删除'**
  String get homeSessionDeleted;

  /// No description provided for @homeDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败：{error}'**
  String homeDeleteFailed(String error);

  /// No description provided for @homeWorkoutRecordTitle.
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日训练记录'**
  String homeWorkoutRecordTitle(int month, int day);

  /// No description provided for @homeSaving.
  ///
  /// In zh, this message translates to:
  /// **'保存中...'**
  String get homeSaving;

  /// No description provided for @homeNoSetRecords.
  ///
  /// In zh, this message translates to:
  /// **'当天还没有可查看的训练组记录。'**
  String get homeNoSetRecords;

  /// No description provided for @homeSetCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 组'**
  String homeSetCount(int count);

  /// No description provided for @homeRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 组记录'**
  String homeRecordCount(int count);

  /// No description provided for @homeStartedAt.
  ///
  /// In zh, this message translates to:
  /// **'{time} 开始'**
  String homeStartedAt(String time);

  /// No description provided for @homeSets.
  ///
  /// In zh, this message translates to:
  /// **'组数'**
  String get homeSets;

  /// No description provided for @homeReps.
  ///
  /// In zh, this message translates to:
  /// **'次数'**
  String get homeReps;

  /// No description provided for @homeWeightKg.
  ///
  /// In zh, this message translates to:
  /// **'重量 kg'**
  String get homeWeightKg;

  /// No description provided for @homeSetNote.
  ///
  /// In zh, this message translates to:
  /// **'{exercise} · 第 {setIndex} 组\n{note}'**
  String homeSetNote(String exercise, int setIndex, String note);

  /// No description provided for @homeDashboardSettings.
  ///
  /// In zh, this message translates to:
  /// **'仪表盘设置'**
  String get homeDashboardSettings;

  /// No description provided for @homeCalendar.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get homeCalendar;

  /// No description provided for @commonDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get commonDone;

  /// No description provided for @sharePosterCreate.
  ///
  /// In zh, this message translates to:
  /// **'生成海报'**
  String get sharePosterCreate;

  /// No description provided for @sharePosterTitle.
  ///
  /// In zh, this message translates to:
  /// **'生成海报'**
  String get sharePosterTitle;

  /// No description provided for @sharePosterSaveToPhotos.
  ///
  /// In zh, this message translates to:
  /// **'保存到照片'**
  String get sharePosterSaveToPhotos;

  /// No description provided for @sharePosterSaving.
  ///
  /// In zh, this message translates to:
  /// **'正在保存'**
  String get sharePosterSaving;

  /// No description provided for @sharePosterSavedToPhotos.
  ///
  /// In zh, this message translates to:
  /// **'已保存到照片'**
  String get sharePosterSavedToPhotos;

  /// No description provided for @sharePosterSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败：{error}'**
  String sharePosterSaveFailed(String error);

  /// No description provided for @sharePosterRenderFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法生成训练海报图片。'**
  String get sharePosterRenderFailed;

  /// No description provided for @sharePosterPhotoFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择照片失败：{error}'**
  String sharePosterPhotoFailed(String error);

  /// No description provided for @sharePosterBackground.
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get sharePosterBackground;

  /// No description provided for @sharePosterComponents.
  ///
  /// In zh, this message translates to:
  /// **'组件'**
  String get sharePosterComponents;

  /// No description provided for @sharePosterUsePhoto.
  ///
  /// In zh, this message translates to:
  /// **'使用照片'**
  String get sharePosterUsePhoto;

  /// No description provided for @sharePosterPhotoSelected.
  ///
  /// In zh, this message translates to:
  /// **'照片背景'**
  String get sharePosterPhotoSelected;

  /// No description provided for @sharePosterPresetDeepPurple.
  ///
  /// In zh, this message translates to:
  /// **'深紫黑'**
  String get sharePosterPresetDeepPurple;

  /// No description provided for @sharePosterPresetWarmPaper.
  ///
  /// In zh, this message translates to:
  /// **'暖米'**
  String get sharePosterPresetWarmPaper;

  /// No description provided for @sharePosterPresetEmber.
  ///
  /// In zh, this message translates to:
  /// **'Ember'**
  String get sharePosterPresetEmber;

  /// No description provided for @sharePosterPresetForest.
  ///
  /// In zh, this message translates to:
  /// **'Forest'**
  String get sharePosterPresetForest;

  /// No description provided for @sharePosterWorkoutName.
  ///
  /// In zh, this message translates to:
  /// **'训练名称'**
  String get sharePosterWorkoutName;

  /// No description provided for @sharePosterDate.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get sharePosterDate;

  /// No description provided for @sharePosterDuration.
  ///
  /// In zh, this message translates to:
  /// **'总用时'**
  String get sharePosterDuration;

  /// No description provided for @sharePosterExerciseCount.
  ///
  /// In zh, this message translates to:
  /// **'动作数'**
  String get sharePosterExerciseCount;

  /// No description provided for @sharePosterSetCount.
  ///
  /// In zh, this message translates to:
  /// **'总组数'**
  String get sharePosterSetCount;

  /// No description provided for @sharePosterTotalVolume.
  ///
  /// In zh, this message translates to:
  /// **'总容量'**
  String get sharePosterTotalVolume;

  /// No description provided for @sharePosterNote.
  ///
  /// In zh, this message translates to:
  /// **'训练备注'**
  String get sharePosterNote;

  /// No description provided for @sharePosterBrand.
  ///
  /// In zh, this message translates to:
  /// **'Yours 标识'**
  String get sharePosterBrand;

  /// No description provided for @exerciseLibrary.
  ///
  /// In zh, this message translates to:
  /// **'动作库'**
  String get exerciseLibrary;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get profileTitle;

  /// No description provided for @dataManagement.
  ///
  /// In zh, this message translates to:
  /// **'数据管理'**
  String get dataManagement;

  /// No description provided for @profileProcessingData.
  ///
  /// In zh, this message translates to:
  /// **'正在处理数据...'**
  String get profileProcessingData;

  /// No description provided for @profileAboutLinks.
  ///
  /// In zh, this message translates to:
  /// **'官网、GitHub 仓库'**
  String get profileAboutLinks;

  /// No description provided for @profileAboutLinksUpdate.
  ///
  /// In zh, this message translates to:
  /// **'官网、GitHub 仓库、检查更新'**
  String get profileAboutLinksUpdate;

  /// No description provided for @profileNewVersion.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {version}'**
  String profileNewVersion(String version);

  /// No description provided for @profileVaultPathPending.
  ///
  /// In zh, this message translates to:
  /// **'路径准备中'**
  String get profileVaultPathPending;

  /// No description provided for @profileVaultNotExported.
  ///
  /// In zh, this message translates to:
  /// **'尚未导出'**
  String get profileVaultNotExported;

  /// No description provided for @profileLastVaultExport.
  ///
  /// In zh, this message translates to:
  /// **'上次导出：{date}'**
  String profileLastVaultExport(String date);

  /// No description provided for @profileExportVault.
  ///
  /// In zh, this message translates to:
  /// **'导出 Vault'**
  String get profileExportVault;

  /// No description provided for @profileImportInbox.
  ///
  /// In zh, this message translates to:
  /// **'导入 inbox'**
  String get profileImportInbox;

  /// No description provided for @profileBackupDescription.
  ///
  /// In zh, this message translates to:
  /// **'创建后可保存到文件 App 或其他位置'**
  String get profileBackupDescription;

  /// No description provided for @profileBackupPlaintextWarning.
  ///
  /// In zh, this message translates to:
  /// **'备份文件包含训练数据，请妥善保存，不要公开分享。'**
  String get profileBackupPlaintextWarning;

  /// No description provided for @profileBackupAndroidLocation.
  ///
  /// In zh, this message translates to:
  /// **'备份文件包含训练数据，请妥善保存。Android 可在 Documents/有思/backups 中查看。'**
  String get profileBackupAndroidLocation;

  /// No description provided for @profileBackupNotCreated.
  ///
  /// In zh, this message translates to:
  /// **'尚未创建'**
  String get profileBackupNotCreated;

  /// No description provided for @profileLastBackup.
  ///
  /// In zh, this message translates to:
  /// **'上次备份：{date}'**
  String profileLastBackup(String date);

  /// No description provided for @profileLatestBackup.
  ///
  /// In zh, this message translates to:
  /// **'最新备份：{name}'**
  String profileLatestBackup(String name);

  /// No description provided for @profileProcessing.
  ///
  /// In zh, this message translates to:
  /// **'处理中...'**
  String get profileProcessing;

  /// No description provided for @profileCreateExport.
  ///
  /// In zh, this message translates to:
  /// **'创建并导出'**
  String get profileCreateExport;

  /// No description provided for @profileRestoreFromFile.
  ///
  /// In zh, this message translates to:
  /// **'从文件恢复'**
  String get profileRestoreFromFile;

  /// No description provided for @profileExportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份'**
  String get profileExportBackup;

  /// No description provided for @profileRestoreFromICloud.
  ///
  /// In zh, this message translates to:
  /// **'从 iCloud 恢复'**
  String get profileRestoreFromICloud;

  /// No description provided for @profileCopyDiagnostics.
  ///
  /// In zh, this message translates to:
  /// **'复制诊断'**
  String get profileCopyDiagnostics;

  /// No description provided for @profileLocalDataSafety.
  ///
  /// In zh, this message translates to:
  /// **'本地数据安全'**
  String get profileLocalDataSafety;

  /// No description provided for @profileProcessingDataShort.
  ///
  /// In zh, this message translates to:
  /// **'正在处理数据'**
  String get profileProcessingDataShort;

  /// No description provided for @profileExportingVault.
  ///
  /// In zh, this message translates to:
  /// **'正在导出 Vault'**
  String get profileExportingVault;

  /// No description provided for @profileNotCreated.
  ///
  /// In zh, this message translates to:
  /// **'未创建'**
  String get profileNotCreated;

  /// No description provided for @profileAvailable.
  ///
  /// In zh, this message translates to:
  /// **'已有'**
  String get profileAvailable;

  /// No description provided for @profileManualExport.
  ///
  /// In zh, this message translates to:
  /// **'手动导出'**
  String get profileManualExport;

  /// No description provided for @profileFile.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get profileFile;

  /// No description provided for @profileReading.
  ///
  /// In zh, this message translates to:
  /// **'读取中'**
  String get profileReading;

  /// No description provided for @profilePendingCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 条'**
  String profilePendingCount(int count);

  /// No description provided for @profileConfigured.
  ///
  /// In zh, this message translates to:
  /// **'已配置'**
  String get profileConfigured;

  /// No description provided for @profileNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get profileNotConfigured;

  /// No description provided for @profileServerNotConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置服务器同步地址'**
  String get profileServerNotConfigured;

  /// No description provided for @profileServerConfiguredHint.
  ///
  /// In zh, this message translates to:
  /// **'已配置服务器地址，建议先测试连接'**
  String get profileServerConfiguredHint;

  /// No description provided for @profileServerConnectionFailed.
  ///
  /// In zh, this message translates to:
  /// **'连接失败：{error}'**
  String profileServerConnectionFailed(String error);

  /// No description provided for @profileNoServerSnapshot.
  ///
  /// In zh, this message translates to:
  /// **'暂无服务器快照'**
  String get profileNoServerSnapshot;

  /// No description provided for @profileRecentSnapshot.
  ///
  /// In zh, this message translates to:
  /// **'最近快照：{date}'**
  String profileRecentSnapshot(String date);

  /// No description provided for @profileServerDetail.
  ///
  /// In zh, this message translates to:
  /// **'{backup}，事件 {events} 条，游标 {cursor}'**
  String profileServerDetail(String backup, int events, int cursor);

  /// No description provided for @profileCheckingICloud.
  ///
  /// In zh, this message translates to:
  /// **'正在检查 iCloud Drive 状态'**
  String get profileCheckingICloud;

  /// No description provided for @profileICloudAvailable.
  ///
  /// In zh, this message translates to:
  /// **'iCloud Drive 可用。'**
  String get profileICloudAvailable;

  /// No description provided for @profileICloudManualHint.
  ///
  /// In zh, this message translates to:
  /// **'用于手动导出和恢复'**
  String get profileICloudManualHint;

  /// No description provided for @profileICloudSignedOut.
  ///
  /// In zh, this message translates to:
  /// **'当前设备未登录 iCloud，或 iCloud Drive 未启用。'**
  String get profileICloudSignedOut;

  /// No description provided for @profileICloudContainerUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前设备没有可用的 iCloud 数据目录。请检查 iCloud Drive 与 App ID 配置。'**
  String get profileICloudContainerUnavailable;

  /// No description provided for @profileICloudUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前平台不支持 iCloud Drive。'**
  String get profileICloudUnsupported;

  /// No description provided for @profileICloudUnknown.
  ///
  /// In zh, this message translates to:
  /// **'iCloud Drive 状态未知。'**
  String get profileICloudUnknown;

  /// No description provided for @profileLocalFirstRecord.
  ///
  /// In zh, this message translates to:
  /// **'本地优先训练记录'**
  String get profileLocalFirstRecord;

  /// No description provided for @profileToggleDark.
  ///
  /// In zh, this message translates to:
  /// **'切换到夜间模式'**
  String get profileToggleDark;

  /// No description provided for @profileToggleLight.
  ///
  /// In zh, this message translates to:
  /// **'切换到白天模式'**
  String get profileToggleLight;

  /// No description provided for @profileServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器'**
  String get profileServer;

  /// No description provided for @profileCheckUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get profileCheckUpdates;

  /// No description provided for @profileCheckingUpdates.
  ///
  /// In zh, this message translates to:
  /// **'正在检查...'**
  String get profileCheckingUpdates;

  /// No description provided for @profileUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本'**
  String get profileUpToDate;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法检查更新'**
  String get profileUpdateFailed;

  /// No description provided for @profileAndroidUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查 Android APK 新版本'**
  String get profileAndroidUpdate;

  /// No description provided for @profileNewVersionDownload.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {version}，去官网下载'**
  String profileNewVersionDownload(String version);

  /// No description provided for @profileServerSettings.
  ///
  /// In zh, this message translates to:
  /// **'服务器备份设置'**
  String get profileServerSettings;

  /// No description provided for @profileServerAddress.
  ///
  /// In zh, this message translates to:
  /// **'Yours 备份服务器地址'**
  String get profileServerAddress;

  /// No description provided for @profileApiKeyOptional.
  ///
  /// In zh, this message translates to:
  /// **'API 密钥（可选）'**
  String get profileApiKeyOptional;

  /// No description provided for @profileApiKeyHint.
  ///
  /// In zh, this message translates to:
  /// **'留空则不发送 Authorization'**
  String get profileApiKeyHint;

  /// No description provided for @profileClear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get profileClear;

  /// No description provided for @serverSync.
  ///
  /// In zh, this message translates to:
  /// **'服务器同步'**
  String get serverSync;

  /// No description provided for @icloudDrive.
  ///
  /// In zh, this message translates to:
  /// **'iCloud Drive'**
  String get icloudDrive;

  /// No description provided for @backupPackage.
  ///
  /// In zh, this message translates to:
  /// **'备份包'**
  String get backupPackage;

  /// No description provided for @notCategorized.
  ///
  /// In zh, this message translates to:
  /// **'未分类'**
  String get notCategorized;

  /// No description provided for @noDescription.
  ///
  /// In zh, this message translates to:
  /// **'暂无介绍'**
  String get noDescription;

  /// No description provided for @all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @exerciseAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加动作'**
  String get exerciseAdd;

  /// No description provided for @exerciseEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑动作'**
  String get exerciseEdit;

  /// No description provided for @exerciseSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索动作，例如 卧推 / 深蹲 / 划船'**
  String get exerciseSearchHint;

  /// No description provided for @exerciseEmpty.
  ///
  /// In zh, this message translates to:
  /// **'本地动作库还没有动作。点击右上角「添加」先建立你的精选动作。'**
  String get exerciseEmpty;

  /// No description provided for @exerciseNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配动作。可以尝试切换分类或清空搜索。'**
  String get exerciseNoMatch;

  /// No description provided for @exerciseLocalSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'本地精选动作 · 离线可用'**
  String get exerciseLocalSubtitle;

  /// No description provided for @exerciseName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get exerciseName;

  /// No description provided for @exerciseCategoryOne.
  ///
  /// In zh, this message translates to:
  /// **'分类 1'**
  String get exerciseCategoryOne;

  /// No description provided for @exerciseCategoryTwo.
  ///
  /// In zh, this message translates to:
  /// **'分类 2'**
  String get exerciseCategoryTwo;

  /// No description provided for @exerciseDescription.
  ///
  /// In zh, this message translates to:
  /// **'介绍'**
  String get exerciseDescription;

  /// No description provided for @exerciseSaveLocal.
  ///
  /// In zh, this message translates to:
  /// **'保存到本地动作库'**
  String get exerciseSaveLocal;

  /// No description provided for @exerciseNotFilled.
  ///
  /// In zh, this message translates to:
  /// **'未填写'**
  String get exerciseNotFilled;

  /// No description provided for @profileOpenLinkFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接。'**
  String get profileOpenLinkFailed;

  /// No description provided for @profileRecentVaultExport.
  ///
  /// In zh, this message translates to:
  /// **'最近已导出 Vault：{name}'**
  String profileRecentVaultExport(String name);

  /// No description provided for @profileVaultExportSummary.
  ///
  /// In zh, this message translates to:
  /// **'Yours Vault 已导出：{plans} 个计划、{workouts} 份记录、{exercises} 个动作。'**
  String profileVaultExportSummary(int plans, int workouts, int exercises);

  /// No description provided for @profileVaultExportAndroidSummary.
  ///
  /// In zh, this message translates to:
  /// **'Yours Vault 已导出：{plans} 个计划、{workouts} 份记录、{exercises} 个动作。公共 Documents 会在后台同步。'**
  String profileVaultExportAndroidSummary(int plans, int workouts, int exercises);

  /// No description provided for @profileRecentVaultExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'最近导出 Vault 失败：{error}'**
  String profileRecentVaultExportFailed(String error);

  /// No description provided for @profileVaultExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'Yours Vault 导出失败：{error}'**
  String profileVaultExportFailed(String error);

  /// No description provided for @profileVaultImportSummary.
  ///
  /// In zh, this message translates to:
  /// **'已从 inbox 导入 {plans} 个计划、{exercises} 个动作{skipped}。'**
  String profileVaultImportSummary(int plans, int exercises, String skipped);

  /// No description provided for @profileSkippedFiles.
  ///
  /// In zh, this message translates to:
  /// **'，跳过 {count} 个文件'**
  String profileSkippedFiles(int count);

  /// No description provided for @profileVaultImportFailed.
  ///
  /// In zh, this message translates to:
  /// **'Yours Vault 导入失败：{error}'**
  String profileVaultImportFailed(String error);

  /// No description provided for @profileBackupCreated.
  ///
  /// In zh, this message translates to:
  /// **'备份包已创建：{name}'**
  String profileBackupCreated(String name);

  /// No description provided for @profileBackupFailed.
  ///
  /// In zh, this message translates to:
  /// **'备份失败：{error}'**
  String profileBackupFailed(String error);

  /// No description provided for @profileRecentBackupExport.
  ///
  /// In zh, this message translates to:
  /// **'最近已导出备份：{name}'**
  String profileRecentBackupExport(String name);

  /// No description provided for @profileBackupExportedICloud.
  ///
  /// In zh, this message translates to:
  /// **'备份包已导出到 iCloud Drive：{name}'**
  String profileBackupExportedICloud(String name);

  /// No description provided for @profileRecentExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'最近导出失败：{error}'**
  String profileRecentExportFailed(String error);

  /// No description provided for @profileICloudExportFailed.
  ///
  /// In zh, this message translates to:
  /// **'iCloud Drive 导出失败：{error}'**
  String profileICloudExportFailed(String error);

  /// No description provided for @profilePickBackupFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择备份包失败：{error}'**
  String profilePickBackupFailed(String error);

  /// No description provided for @profilePickBackupCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消选择备份包。'**
  String get profilePickBackupCancelled;

  /// No description provided for @profileRestoreBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'从备份包恢复？'**
  String get profileRestoreBackupTitle;

  /// No description provided for @profileRestoreBackupMessage.
  ///
  /// In zh, this message translates to:
  /// **'将从 {name} 恢复训练计划、训练记录和动作库。恢复前会自动创建安全快照。'**
  String profileRestoreBackupMessage(String name);

  /// No description provided for @profileRecentRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'最近恢复失败：{error}'**
  String profileRecentRestoreFailed(String error);

  /// No description provided for @profilePickICloudBackupFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择 iCloud Drive 备份包失败：{error}'**
  String profilePickICloudBackupFailed(String error);

  /// No description provided for @profilePickICloudBackupCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消选择 iCloud Drive 备份包。'**
  String get profilePickICloudBackupCancelled;

  /// No description provided for @profileRestoreICloudTitle.
  ///
  /// In zh, this message translates to:
  /// **'从 iCloud Drive 恢复？'**
  String get profileRestoreICloudTitle;

  /// No description provided for @profileRestoringICloud.
  ///
  /// In zh, this message translates to:
  /// **'正在从 iCloud Drive 恢复备份...'**
  String get profileRestoringICloud;

  /// No description provided for @profileICloudRestoreComplete.
  ///
  /// In zh, this message translates to:
  /// **'iCloud Drive 恢复完成'**
  String get profileICloudRestoreComplete;

  /// No description provided for @profileRecentICloudRestore.
  ///
  /// In zh, this message translates to:
  /// **'最近已从 iCloud Drive 恢复：{name}'**
  String profileRecentICloudRestore(String name);

  /// No description provided for @profileServerAddressSaved.
  ///
  /// In zh, this message translates to:
  /// **'服务器备份地址已保存。'**
  String get profileServerAddressSaved;

  /// No description provided for @profileServerAddressCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清空服务器备份地址。'**
  String get profileServerAddressCleared;

  /// No description provided for @profileConfigureServerFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先配置服务器备份地址。'**
  String get profileConfigureServerFirst;

  /// No description provided for @profileConfigureServerSyncFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先配置服务器同步地址。'**
  String get profileConfigureServerSyncFirst;

  /// No description provided for @profileServerSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'服务器同步失败：{error}'**
  String profileServerSyncFailed(String error);

  /// No description provided for @profileServerSyncComplete.
  ///
  /// In zh, this message translates to:
  /// **'服务器同步完成。'**
  String get profileServerSyncComplete;

  /// No description provided for @profileServerAlreadyLatest.
  ///
  /// In zh, this message translates to:
  /// **'已是最新，并刷新服务器快照。'**
  String get profileServerAlreadyLatest;

  /// No description provided for @profileServerSyncSummary.
  ///
  /// In zh, this message translates to:
  /// **'已上传 {uploaded} 条变化，拉取 {downloaded} 条服务器事件，应用 {applied} 条。'**
  String profileServerSyncSummary(int uploaded, int downloaded, int applied);

  /// No description provided for @profileServerBackupFound.
  ///
  /// In zh, this message translates to:
  /// **'发现服务器备份'**
  String get profileServerBackupFound;

  /// No description provided for @profileServerBackupFoundMessage.
  ///
  /// In zh, this message translates to:
  /// **'这台设备还没有本地训练数据。服务器上已有备份，是否恢复到本机？恢复前会自动创建本地安全快照。'**
  String get profileServerBackupFoundMessage;

  /// No description provided for @profileRestoreToDevice.
  ///
  /// In zh, this message translates to:
  /// **'恢复到本机'**
  String get profileRestoreToDevice;

  /// No description provided for @profileNormalSyncFailed.
  ///
  /// In zh, this message translates to:
  /// **'普通同步失败'**
  String get profileNormalSyncFailed;

  /// No description provided for @profileNormalSyncFailedMessage.
  ///
  /// In zh, this message translates to:
  /// **'普通同步失败：{error}\n\n可以尝试从服务器备份恢复本机。恢复前会自动创建本地安全快照。'**
  String profileNormalSyncFailedMessage(String error);

  /// No description provided for @profileRestoreFromBackup.
  ///
  /// In zh, this message translates to:
  /// **'从备份恢复'**
  String get profileRestoreFromBackup;

  /// No description provided for @profileServerAvailable.
  ///
  /// In zh, this message translates to:
  /// **'服务器同步可用：协议 v{version}，事件 {events} 条。'**
  String profileServerAvailable(int version, int events);

  /// No description provided for @profileServerTestFailed.
  ///
  /// In zh, this message translates to:
  /// **'服务器连接测试失败：{error}'**
  String profileServerTestFailed(String error);

  /// No description provided for @profileDiagnosticsCopied.
  ///
  /// In zh, this message translates to:
  /// **'服务器同步诊断信息已复制。'**
  String get profileDiagnosticsCopied;

  /// No description provided for @profileDiagnosticsFallbackCopied.
  ///
  /// In zh, this message translates to:
  /// **'诊断生成不完整，已复制基础错误信息。'**
  String get profileDiagnosticsFallbackCopied;

  /// No description provided for @profileRestoreComplete.
  ///
  /// In zh, this message translates to:
  /// **'恢复完成'**
  String get profileRestoreComplete;

  /// No description provided for @profileRestoreSummary.
  ///
  /// In zh, this message translates to:
  /// **'已恢复 {count} 个文件。\n安全快照：{snapshot}\n\n页面数据已重新加载。'**
  String profileRestoreSummary(int count, String snapshot);

  /// No description provided for @profileAcknowledged.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get profileAcknowledged;

  /// No description provided for @profileRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'恢复失败：{error}'**
  String profileRestoreFailed(String error);

  /// No description provided for @profileServerRestoreComplete.
  ///
  /// In zh, this message translates to:
  /// **'服务器恢复完成'**
  String get profileServerRestoreComplete;

  /// No description provided for @profileServerSnapshotRestoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'服务器快照恢复失败：{error}'**
  String profileServerSnapshotRestoreFailed(String error);

  /// No description provided for @profileDatabasePreparing.
  ///
  /// In zh, this message translates to:
  /// **'数据库刚刚完成恢复，连接正在重新准备。请稍后重试。'**
  String get profileDatabasePreparing;

  /// No description provided for @profileServerReturnedHtml.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回了网页页面，请检查地址是否为 Yours 备份服务器。'**
  String get profileServerReturnedHtml;

  /// No description provided for @profileTargetServer.
  ///
  /// In zh, this message translates to:
  /// **'目标服务器'**
  String get profileTargetServer;

  /// No description provided for @planRecordModeStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准记录'**
  String get planRecordModeStandard;

  /// No description provided for @planRecordModeFree.
  ///
  /// In zh, this message translates to:
  /// **'自由记录'**
  String get planRecordModeFree;

  /// No description provided for @workoutRecordMode.
  ///
  /// In zh, this message translates to:
  /// **'记录方式'**
  String get workoutRecordMode;

  /// No description provided for @workoutReplaceExercise.
  ///
  /// In zh, this message translates to:
  /// **'替换本次动作'**
  String get workoutReplaceExercise;

  /// No description provided for @workoutChooseExercise.
  ///
  /// In zh, this message translates to:
  /// **'选择'**
  String get workoutChooseExercise;

  /// No description provided for @workoutExerciseReplaced.
  ///
  /// In zh, this message translates to:
  /// **'已将「{from}」替换为「{to}」'**
  String workoutExerciseReplaced(String from, String to);

  /// No description provided for @workoutCompleteFreeRecord.
  ///
  /// In zh, this message translates to:
  /// **'完成本项'**
  String get workoutCompleteFreeRecord;

  /// No description provided for @workoutUndoFreeRecord.
  ///
  /// In zh, this message translates to:
  /// **'撤销本项记录'**
  String get workoutUndoFreeRecord;

  /// No description provided for @workoutActivityElapsed.
  ///
  /// In zh, this message translates to:
  /// **'本项用时'**
  String get workoutActivityElapsed;

  /// No description provided for @workoutDurationSeconds.
  ///
  /// In zh, this message translates to:
  /// **'持续时间 s'**
  String get workoutDurationSeconds;

  /// No description provided for @workoutSavedLocal.
  ///
  /// In zh, this message translates to:
  /// **'训练已保存到本地。'**
  String get workoutSavedLocal;

  /// No description provided for @workoutCompletedMixedSummary.
  ///
  /// In zh, this message translates to:
  /// **'完成 {exercises} 个动作 · {sets} 组 · {freeRecords} 个自由项目'**
  String workoutCompletedMixedSummary(int exercises, int sets, int freeRecords);

  /// No description provided for @homeFreeRecords.
  ///
  /// In zh, this message translates to:
  /// **'自由项目'**
  String get homeFreeRecords;

  /// No description provided for @homeSessionRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'{sets} 组 · {freeRecords} 个自由项目'**
  String homeSessionRecordCount(int sets, int freeRecords);

  /// No description provided for @homeActivityRecordCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个活动记录'**
  String homeActivityRecordCount(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsDescription.
  ///
  /// In zh, this message translates to:
  /// **'外观、语言与关于有思'**
  String get settingsDescription;

  /// No description provided for @appearanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearanceTitle;

  /// No description provided for @appearanceDescription.
  ///
  /// In zh, this message translates to:
  /// **'主题与显示方式'**
  String get appearanceDescription;

  /// No description provided for @themeTitle.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @languageDescription.
  ///
  /// In zh, this message translates to:
  /// **'选择有思使用的语言'**
  String get languageDescription;

  /// No description provided for @aboutDescription.
  ///
  /// In zh, this message translates to:
  /// **'官网、版本与更新'**
  String get aboutDescription;

  /// No description provided for @settingsCurrentValue.
  ///
  /// In zh, this message translates to:
  /// **'当前：{value}'**
  String settingsCurrentValue(String value);

  /// No description provided for @errorBackupMissing.
  ///
  /// In zh, this message translates to:
  /// **'备份包不存在。'**
  String get errorBackupMissing;

  /// No description provided for @errorBackupEmpty.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回的备份包为空。'**
  String get errorBackupEmpty;

  /// No description provided for @errorInvalidBackup.
  ///
  /// In zh, this message translates to:
  /// **'所选文件不是有效的有思备份包。'**
  String get errorInvalidBackup;

  /// No description provided for @errorBackupManifestMissing.
  ///
  /// In zh, this message translates to:
  /// **'备份包缺少 manifest.json，无法确认格式。'**
  String get errorBackupManifestMissing;

  /// No description provided for @errorBackupDatabaseMissing.
  ///
  /// In zh, this message translates to:
  /// **'备份包缺少必要数据库文件。'**
  String get errorBackupDatabaseMissing;

  /// No description provided for @errorInvalidServerAddress.
  ///
  /// In zh, this message translates to:
  /// **'服务器地址格式不正确，请使用 https://example.com 这样的格式。'**
  String get errorInvalidServerAddress;

  /// No description provided for @errorServerTimeout.
  ///
  /// In zh, this message translates to:
  /// **'网络超时。请检查服务器地址、HTTPS 和当前网络。'**
  String get errorServerTimeout;

  /// No description provided for @errorServerTls.
  ///
  /// In zh, this message translates to:
  /// **'HTTPS 握手失败。请检查服务器域名、证书和当前网络。'**
  String get errorServerTls;

  /// No description provided for @errorServerUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'无法连接服务器。请检查地址、端口、HTTPS 和反向代理配置。'**
  String get errorServerUnreachable;

  /// No description provided for @errorServerInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'网络请求被中断。请检查服务器地址和当前网络。'**
  String get errorServerInterrupted;

  /// No description provided for @errorInvalidServerResponse.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回格式不正确。请确认地址指向有思自托管同步服务。'**
  String get errorInvalidServerResponse;

  /// No description provided for @errorInvalidServerEvents.
  ///
  /// In zh, this message translates to:
  /// **'服务器事件接口返回格式不正确。'**
  String get errorInvalidServerEvents;

  /// No description provided for @errorInvalidServerStatus.
  ///
  /// In zh, this message translates to:
  /// **'服务器状态接口返回格式不正确。'**
  String get errorInvalidServerStatus;

  /// No description provided for @errorNoServerBackup.
  ///
  /// In zh, this message translates to:
  /// **'没有找到可恢复的备份包。'**
  String get errorNoServerBackup;

  /// No description provided for @errorServerOutdated.
  ///
  /// In zh, this message translates to:
  /// **'自托管同步服务版本过旧。当前协议 v{current}，需要 v{required}。'**
  String errorServerOutdated(int current, int required);

  /// No description provided for @errorUnappliedServerChanges.
  ///
  /// In zh, this message translates to:
  /// **'有 {count} 条服务器变化暂时无法应用，建议从服务器备份恢复本机。'**
  String errorUnappliedServerChanges(int count);

  /// No description provided for @backupShareTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出有思备份包'**
  String get backupShareTitle;

  /// No description provided for @backupShareSubject.
  ///
  /// In zh, this message translates to:
  /// **'有思备份包'**
  String get backupShareSubject;

  /// No description provided for @backupShareText.
  ///
  /// In zh, this message translates to:
  /// **'这是有思备份包。你可以将它保存到 iCloud Drive、文件 App 或其他位置，需要时再从文件恢复。'**
  String get backupShareText;

  /// No description provided for @exerciseExampleName.
  ///
  /// In zh, this message translates to:
  /// **'例如：杠铃卧推'**
  String get exerciseExampleName;

  /// No description provided for @exerciseExampleCategory.
  ///
  /// In zh, this message translates to:
  /// **'例如：胸部'**
  String get exerciseExampleCategory;

  /// No description provided for @exerciseExampleEquipment.
  ///
  /// In zh, this message translates to:
  /// **'例如：杠铃'**
  String get exerciseExampleEquipment;

  /// No description provided for @yoursVaultName.
  ///
  /// In zh, this message translates to:
  /// **'Yours Vault'**
  String get yoursVaultName;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
