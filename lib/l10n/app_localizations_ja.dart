// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Yours';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabPlan => 'プラン';

  @override
  String get tabExercises => '種目';

  @override
  String get tabProfile => 'ユーザー';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonDelete => '削除';

  @override
  String get commonEdit => '編集';

  @override
  String get commonSave => '保存';

  @override
  String get commonAdd => '追加';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonRestore => '復元';

  @override
  String get commonSettings => '設定';

  @override
  String get commonTest => 'テスト';

  @override
  String get commonSyncNow => '今すぐ同期';

  @override
  String get commonPendingSync => '保留中';

  @override
  String get commonSynced => '同期済み';

  @override
  String get commonUnknownError => '不明なエラー';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システム';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => '英語';

  @override
  String get aboutYours => 'Yoursについて';

  @override
  String get officialWebsite => 'Webサイト';

  @override
  String get githubRepository => 'GitHub リポジトリ';

  @override
  String get planTitle => 'トレーニングプラン';

  @override
  String get planCreate => '新規';

  @override
  String get planNewName => '新しいトレーニングプラン';

  @override
  String get planActive => 'アクティブ';

  @override
  String get planArchived => 'アーカイブ済み';

  @override
  String get planArchive => 'アーカイブ';

  @override
  String get planRestoreActive => '復元';

  @override
  String get planNoActive => 'トレーニングプランはまだありません。';

  @override
  String get planNoArchived => 'アーカイブ済みのトレーニングプランはありません。';

  @override
  String get planNone => 'トレーニングプランなし';

  @override
  String planCount(int count) {
    return '$count プラン · ローカルファースト';
  }

  @override
  String get planSwipeHint => '左にスワイプしてプランを編集または削除します';

  @override
  String get planScheduleReady => 'スケジュール設定済み';

  @override
  String get planScheduleIncomplete => 'スケジュール未完了';

  @override
  String get planDeleteTitle => 'トレーニングプランを削除';

  @override
  String planDeleteMessage(String name) {
    return '「$name」を削除しますか?この変更は最初にローカルで有効になり、同期キューに追加されます。';
  }

  @override
  String planLocalSaveFailed(String error) {
    return 'ローカル トレーニング プランを保存できませんでした: $error';
  }

  @override
  String get planDaySelection => 'トレーニング日を選択してください';

  @override
  String planSummary(int weeks, int days) {
    return '$weeks 週 · $days 日/週';
  }

  @override
  String planScheduledDays(String summary, int count) {
    return '$summary・$count予定日';
  }

  @override
  String planWeek(int week) {
    return '週 $week';
  }

  @override
  String get planMarkWeekComplete => '完了としてマークする';

  @override
  String get planUnmarkWeekComplete => '完了マークを削除する';

  @override
  String get planNoActions => 'エクササイズはまだありません。タップして追加してください。';

  @override
  String get planRestoreArchivedTitle => 'この計画を復元しますか?';

  @override
  String get planRestoreArchivedMessage => 'ワークアウトを開始する前に、アーカイブされたプランを復元する必要があります。';

  @override
  String planDatabaseInitFailed(String error) {
    return 'ローカル トレーニング データベースを初期化できませんでした: $error';
  }

  @override
  String get planEditTitle => 'トレーニングプランを編集';

  @override
  String get planName => 'プラン名';

  @override
  String get planCycle => 'トレーニングサイクル';

  @override
  String get planWeeksSuffix => '週 (1 ～ 12)';

  @override
  String get planDaysPerWeek => '週あたりの日数';

  @override
  String get planDaysSuffix => '日 (1 ～ 7)';

  @override
  String get planArrangement => '運動スケジュール';

  @override
  String planDayTitle(int week, int day) {
    return '週 $week · D$day';
  }

  @override
  String get planDayName => 'トレーニング日の名前';

  @override
  String get planAddExercise => 'エクササイズを追加';

  @override
  String planActionList(int count) {
    return 'エクササイズ（$count）';
  }

  @override
  String get planNoExerciseHint => 'エクササイズはまだありません。「エクササイズを追加」をタップしてライブラリから選択してください。';

  @override
  String get planRemove => '削除';

  @override
  String get planSetSuffix => 'セット';

  @override
  String get planRepSuffix => '回';

  @override
  String get planRest => '休憩';

  @override
  String get planDuration => '継続時間';

  @override
  String get planWeight => '重量';

  @override
  String get planNoteHint => 'RIR 2、6 ～ 8 レップ、またはスローエキセントリックなどの注意事項';

  @override
  String get planAddFromLibrary => 'エクササイズライブラリから追加';

  @override
  String planSelectedCount(int count) {
    return '$count が選択されました';
  }

  @override
  String get planSearchLibrary => 'ローカルのエクササイズライブラリを検索';

  @override
  String get planNoMatchingExercise => '一致するエクササイズがありません。先にライブラリへ追加してください。';

  @override
  String get planAdded => '追加済み';

  @override
  String get workoutEndTitle => 'トレーニングを終了しますか?';

  @override
  String get workoutEndIncomplete => 'このトレーニングプランは完了していません。保存済みのデータは保持され、未完了のトレーニングとして記録されます。';

  @override
  String get workoutEndEmpty => 'セットは保存されていません。ワークアウトモードを閉じることを確認します。';

  @override
  String get workoutPostNote => 'トレーニング後のメモ';

  @override
  String get workoutPostNoteHint => '例: 肩の不快感、横上げのスキップ';

  @override
  String get workoutEnd => 'ワークアウトを終了する';

  @override
  String get workoutTimer => 'ワークアウトタイマー';

  @override
  String get workoutSummary => 'ワークアウトの概要';

  @override
  String get workoutDefaultDay => 'デフォルトのトレーニング日';

  @override
  String get workoutElapsed => '時間';

  @override
  String get workoutExercise => 'エクササイズ';

  @override
  String get workoutCurrentExercise => '現在のエクササイズ';

  @override
  String get workoutRestSeconds => '休息';

  @override
  String get workoutSaveSet => 'セットを保存して続行';

  @override
  String get workoutUndoSet => '現在のセットを元に戻す';

  @override
  String get workoutRestBetween => 'セット間の休憩';

  @override
  String get workoutNextSet => '次のセット';

  @override
  String get workoutSkipRest => '休憩をスキップして続行';

  @override
  String get workoutComplete => 'ワークアウト完了';

  @override
  String get workoutFinishSave => 'ワークアウトを終了して保存する';

  @override
  String get workoutOptional => '任意';

  @override
  String get workoutNote => 'メモ';

  @override
  String get workoutTrainingNote => 'トレーニングノート';

  @override
  String workoutSavedBackup(String name) {
    return 'ワークアウトが自動的に保存およびバックアップされました: $name';
  }

  @override
  String workoutSavedBackupFailed(String error) {
    return 'ワークアウトは保存されましたが、自動バックアップに失敗しました: $error';
  }

  @override
  String get workoutSetUndone => '現在のセット記録を取り消しました';

  @override
  String get workoutFirstSet => 'これはすでに最初のセットです';

  @override
  String get workoutLastSet => 'もうこれが最終セットです';

  @override
  String workoutTimerStartFailed(String error) {
    return 'ワークアウトタイマーを開始できませんでした: $error';
  }

  @override
  String get workoutNoActions => 'このトレーニングプランにはエクササイズがありません。先にプランを編集して追加してください。';

  @override
  String get workoutNextSummary => '次へ: ワークアウトの概要';

  @override
  String workoutNextSetLabel(String exercise, int set) {
    return '次のセット：$exercise · セット $set';
  }

  @override
  String get workoutUndoReturnLog => '現在の設定を元に戻してログ記録に戻ります';

  @override
  String get workoutRestHint =>
      'タイマーが終了するとここで一時停止します。スワイプするとセットのプレビューのみが表示されます。レコードの書き込みや取り消しは行いません。';

  @override
  String workoutCompletedSummary(int exercises, int sets) {
    return '$exercises 種目完了 · $sets セット';
  }

  @override
  String get workoutUndoLastReturnLog => '最後の設定を元に戻してログ記録に戻ります';

  @override
  String get workoutNoteHint => '例：RIR 2、休憩120秒、回数範囲6～8';

  @override
  String get homeTodayStatus => '今日';

  @override
  String homeMonthTitle(int year, int month) {
    return '$month/$year';
  }

  @override
  String get homeWeekdays => '月、火、水、木、金、土、日';

  @override
  String homeDateTitle(int month, int day, String name) {
    return '$month/$day・$name';
  }

  @override
  String get homeNoWorkout => 'トレーニングなし';

  @override
  String get homeNoWorkoutRecord => 'この日のトレーニング記録はありません';

  @override
  String get homeRecorded => '記録済み';

  @override
  String get homeIncomplete => '未完了';

  @override
  String get homeTotalVolume => '総ボリューム kg';

  @override
  String get homeEffectiveSets => 'ワーキングセット';

  @override
  String get homeMinutes => '分';

  @override
  String get homeEmptyRecordMessage => 'この日の記録はありません。ワークアウトを完了すると、ここでボリューム、セット、期間、メモが表示されます。';

  @override
  String get homeDefaultRecordName => 'トレーニング記録';

  @override
  String get homeDefaultIncompleteRecordName => '未完了のトレーニング';

  @override
  String get homeDefaultSavedNote => 'このワークアウトはローカル データベースに保存されています。';

  @override
  String get homeIncompleteWorkoutMarker => '未完了のトレーニングプラン';

  @override
  String get homeRecordUpdated => 'トレーニング記録を更新しました';

  @override
  String homeSaveFailed(String error) {
    return '保存できませんでした: $error';
  }

  @override
  String get homeDeleteSessionTitle => 'このワークアウト記録を削除しますか?';

  @override
  String homeDeleteSessionMessage(String time, int count) {
    return '$time のワークアウト レコードとその $count セットを削除しますか?この変更はサーバー同期キューに追加されます。';
  }

  @override
  String get homeSessionDeleted => 'トレーニング記録が削除されました';

  @override
  String homeDeleteFailed(String error) {
    return '削除できませんでした: $error';
  }

  @override
  String homeWorkoutRecordTitle(int month, int day) {
    return 'ワークアウト記録 · $month/$day';
  }

  @override
  String get homeSaving => '保存中...';

  @override
  String get homeNoSetRecords => 'この日のセット記録はありません。';

  @override
  String homeSetCount(int count) {
    return '$count セット';
  }

  @override
  String homeRecordCount(int count) {
    return '$count 件のセット記録';
  }

  @override
  String homeStartedAt(String time) {
    return '$time から開始';
  }

  @override
  String get homeSets => 'セット';

  @override
  String get homeReps => '回数';

  @override
  String get homeWeightKg => '重量kg';

  @override
  String homeSetNote(String exercise, int setIndex, String note) {
    return '$exercise · $setIndex を設定する\n$note';
  }

  @override
  String get homeDashboardSettings => 'ダッシュボードの設定';

  @override
  String get homeCalendar => 'カレンダー';

  @override
  String get commonDone => '完了';

  @override
  String get sharePosterCreate => 'ポスターを作成';

  @override
  String get sharePosterTitle => 'ポスターを作成';

  @override
  String get sharePosterSaveToPhotos => '写真に保存';

  @override
  String get sharePosterSaving => '保存中';

  @override
  String get sharePosterSavedToPhotos => '写真に保存しました';

  @override
  String sharePosterSaveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get sharePosterRenderFailed => 'トレーニングポスターを生成できませんでした。';

  @override
  String sharePosterPhotoFailed(String error) {
    return '写真を選択できませんでした: $error';
  }

  @override
  String get sharePosterBackground => '背景';

  @override
  String get sharePosterComponents => 'コンポーネント';

  @override
  String get sharePosterUsePhoto => '写真を使う';

  @override
  String get sharePosterPhotoSelected => '写真背景';

  @override
  String get sharePosterPresetDeepPurple => 'ディープパープル';

  @override
  String get sharePosterPresetWarmPaper => 'ウォームペーパー';

  @override
  String get sharePosterPresetEmber => 'Ember';

  @override
  String get sharePosterPresetForest => 'Forest';

  @override
  String get sharePosterWorkoutName => 'トレーニング名';

  @override
  String get sharePosterDate => '日付';

  @override
  String get sharePosterDuration => '合計時間';

  @override
  String get sharePosterExerciseCount => '種目数';

  @override
  String get sharePosterSetCount => 'セット数';

  @override
  String get sharePosterTotalVolume => '総ボリューム';

  @override
  String get sharePosterNote => 'トレーニングメモ';

  @override
  String get sharePosterBrand => 'Yours 表示';

  @override
  String get exerciseLibrary => 'エクササイズ';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get dataManagement => 'データ管理';

  @override
  String get profileProcessingData => 'データを処理中...';

  @override
  String get profileAboutLinks => 'Web サイトと GitHub リポジトリ';

  @override
  String get profileAboutLinksUpdate => 'Web サイト、GitHub リポジトリ、およびアップデート';

  @override
  String profileNewVersion(String version) {
    return '新バージョン $version';
  }

  @override
  String get profileVaultPathPending => 'パスの準備中';

  @override
  String get profileVaultNotExported => 'まだエクスポートされていません';

  @override
  String profileLastVaultExport(String date) {
    return '前回のエクスポート: $date';
  }

  @override
  String get profileExportVault => 'Vaultをエクスポート';

  @override
  String get profileImportInbox => 'inboxをインポート';

  @override
  String get profileBackupDescription => 'バックアップを作成し、ファイルまたは別の場所に保存します。';

  @override
  String get profileBackupPlaintextWarning => 'バックアップファイルにはトレーニングデータが含まれます。大切に保管し、公開共有しないでください。';

  @override
  String get profileBackupAndroidLocation =>
      'バックアップファイルにはトレーニングデータが含まれます。Androidでは Documents/有思/backups で確認できます。';

  @override
  String get profileBackupNotCreated => 'まだ作成されていません';

  @override
  String profileLastBackup(String date) {
    return '前回のバックアップ: $date';
  }

  @override
  String profileLatestBackup(String name) {
    return '最新のバックアップ: $name';
  }

  @override
  String get profileProcessing => '処理...';

  @override
  String get profileCreateExport => '作成してエクスポート';

  @override
  String get profileRestoreFromFile => 'ファイルから復元';

  @override
  String get profileExportBackup => 'バックアップのエクスポート';

  @override
  String get profileRestoreFromICloud => 'iCloudから復元';

  @override
  String get profileCopyDiagnostics => '診断情報をコピー';

  @override
  String get profileLocalDataSafety => 'ローカルデータの安全性';

  @override
  String get profileProcessingDataShort => 'データの処理';

  @override
  String get profileExportingVault => 'Vault をエクスポート中';

  @override
  String get profileNotCreated => '作成されていません';

  @override
  String get profileAvailable => '利用可能';

  @override
  String get profileManualExport => '手動エクスポート';

  @override
  String get profileFile => 'ファイル';

  @override
  String get profileReading => '読み込み中';

  @override
  String profilePendingCount(int count) {
    return '$count';
  }

  @override
  String get profileConfigured => '設定済み';

  @override
  String get profileNotConfigured => '未設定';

  @override
  String get profileServerNotConfigured => 'サーバー同期が構成されていません';

  @override
  String get profileServerConfiguredHint => 'サーバーアドレスが設定されています。まず接続をテストします。';

  @override
  String profileServerConnectionFailed(String error) {
    return '接続に失敗しました: $error';
  }

  @override
  String get profileNoServerSnapshot => 'サーバーのスナップショットがありません';

  @override
  String profileRecentSnapshot(String date) {
    return '最新のスナップショット: $date';
  }

  @override
  String profileServerDetail(String backup, int events, int cursor) {
    return '$backup、$events イベント、カーソル $cursor';
  }

  @override
  String get profileCheckingICloud => 'iCloud Driveの状態を確認中';

  @override
  String get profileICloudAvailable => 'iCloudドライブが利用可能です。';

  @override
  String get profileICloudManualHint => '手動エクスポートと復元に使用します';

  @override
  String get profileICloudSignedOut => 'このデバイスは iCloud にサインインしていないか、iCloud Drive が無効になっています。';

  @override
  String get profileICloudContainerUnavailable =>
      '使用可能な iCloud データ ディレクトリがありません。 iCloud DriveとApp IDの設定を確認してください。';

  @override
  String get profileICloudUnsupported => 'iCloud Drive はこのプラットフォームではサポートされていません。';

  @override
  String get profileICloudUnknown => 'iCloudドライブのステータスが不明です。';

  @override
  String get profileLocalFirstRecord => 'ローカルファーストのトレーニング記録';

  @override
  String get profileToggleDark => 'ダークモードに切り替える';

  @override
  String get profileToggleLight => 'ライトモードに切り替える';

  @override
  String get profileServer => 'サーバ';

  @override
  String get profileCheckUpdates => 'アップデートをチェックする';

  @override
  String get profileCheckingUpdates => 'チェック中...';

  @override
  String get profileUpToDate => '最新バージョンです';

  @override
  String get profileUpdateFailed => 'アップデートを確認できませんでした';

  @override
  String get profileAndroidUpdate => '新しい Android APK を確認する';

  @override
  String profileNewVersionDownload(String version) {
    return 'バージョン $version が利用可能です。ウェブサイトからダウンロードしてください。';
  }

  @override
  String get profileServerSettings => 'サーバーバックアップ設定';

  @override
  String get profileServerAddress => 'Yoursバックアップサーバーのアドレス';

  @override
  String get profileApiKeyOptional => 'APIキー(オプション)';

  @override
  String get profileApiKeyHint => '認証を省略するには空白のままにします';

  @override
  String get profileClear => 'クリア';

  @override
  String get serverSync => 'サーバー同期';

  @override
  String get icloudDrive => 'iCloudドライブ';

  @override
  String get backupPackage => 'バックアップパッケージ';

  @override
  String get notCategorized => '未分類';

  @override
  String get noDescription => '説明なし';

  @override
  String get all => '全て';

  @override
  String get exerciseAdd => 'エクササイズを追加';

  @override
  String get exerciseEdit => 'エクササイズを編集';

  @override
  String get exerciseSearchHint => 'ベンチプレスやスクワットなどのエクササイズを検索する';

  @override
  String get exerciseEmpty => 'ローカルのエクササイズ ライブラリが空です。 「追加」をタップしてエクササイズを作成します。';

  @override
  String get exerciseNoMatch => '一致するエクササイズがありません。カテゴリを変更するか検索をクリアしてください。';

  @override
  String get exerciseLocalSubtitle => 'ローカルで厳選・オフラインで利用可能';

  @override
  String get exerciseName => '名前';

  @override
  String get exerciseCategoryOne => 'カテゴリー1';

  @override
  String get exerciseCategoryTwo => 'カテゴリー2';

  @override
  String get exerciseDescription => '説明';

  @override
  String get exerciseSaveLocal => 'ローカルエクササイズライブラリに保存';

  @override
  String get exerciseNotFilled => '未入力';

  @override
  String get profileOpenLinkFailed => 'リンクを開けませんでした。';

  @override
  String profileRecentVaultExport(String name) {
    return '最近エクスポートしたVault：$name';
  }

  @override
  String profileVaultExportSummary(int plans, int workouts, int exercises) {
    return 'エクスポートされた Vault: $plans プラン、$workouts ワークアウト記録、$exercises エクササイズ。';
  }

  @override
  String profileVaultExportAndroidSummary(int plans, int workouts, int exercises) {
    return 'エクスポートされた Vault: $plans プラン、$workouts ワークアウト記録、$exercises エクササイズ。公開 Documents はバックグラウンドで同期されます。';
  }

  @override
  String profileRecentVaultExportFailed(String error) {
    return '最近の Vault エクスポートに失敗しました: $error';
  }

  @override
  String profileVaultExportFailed(String error) {
    return 'Vault のエクスポートに失敗しました: $error';
  }

  @override
  String profileVaultImportSummary(int plans, int exercises, String skipped) {
    return 'inboxからプラン$plans件、エクササイズ$exercises件をインポートしました$skipped。';
  }

  @override
  String profileSkippedFiles(int count) {
    return '、$count ファイルをスキップしました';
  }

  @override
  String profileVaultImportFailed(String error) {
    return 'Vault のインポートに失敗しました: $error';
  }

  @override
  String profileBackupCreated(String name) {
    return '作成されたバックアップ パッケージ: $name';
  }

  @override
  String profileBackupFailed(String error) {
    return 'バックアップに失敗しました: $error';
  }

  @override
  String profileRecentBackupExport(String name) {
    return '最近エクスポートされたバックアップ: $name';
  }

  @override
  String profileBackupExportedICloud(String name) {
    return 'iCloud Drive にエクスポートされたバックアップ: $name';
  }

  @override
  String profileRecentExportFailed(String error) {
    return '最近のエクスポートに失敗しました: $error';
  }

  @override
  String profileICloudExportFailed(String error) {
    return 'iCloud Drive のエクスポートに失敗しました: $error';
  }

  @override
  String profilePickBackupFailed(String error) {
    return 'バックアップ パッケージを選択できませんでした: $error';
  }

  @override
  String get profilePickBackupCancelled => 'バックアップの選択がキャンセルされました。';

  @override
  String get profileRestoreBackupTitle => 'このバックアップから復元しますか?';

  @override
  String profileRestoreBackupMessage(String name) {
    return '$name からトレーニング プラン、トレーニング記録、エクササイズ ライブラリを復元します。まず安全スナップショットを作成します。';
  }

  @override
  String profileRecentRestoreFailed(String error) {
    return '最近の復元に失敗しました: $error';
  }

  @override
  String profilePickICloudBackupFailed(String error) {
    return 'iCloud Drive バックアップを選択できませんでした: $error';
  }

  @override
  String get profilePickICloudBackupCancelled => 'iCloud Drive バックアップの選択がキャンセルされました。';

  @override
  String get profileRestoreICloudTitle => 'iCloud Driveから復元しますか？';

  @override
  String get profileRestoringICloud => 'iCloud Drive からバックアップを復元しています...';

  @override
  String get profileICloudRestoreComplete => 'iCloudドライブの復元が完了しました';

  @override
  String profileRecentICloudRestore(String name) {
    return '最近 iCloud Drive から復元されました: $name';
  }

  @override
  String get profileServerAddressSaved => 'サーバーのバックアップアドレスが保存されました。';

  @override
  String get profileServerAddressCleared => 'サーバーのバックアップアドレスがクリアされました。';

  @override
  String get profileConfigureServerFirst => '最初にサーバーのバックアップ アドレスを構成します。';

  @override
  String get profileConfigureServerSyncFirst => '最初にサーバー同期アドレスを構成します。';

  @override
  String profileServerSyncFailed(String error) {
    return 'サーバー同期に失敗しました: $error';
  }

  @override
  String get profileServerSyncComplete => 'サーバーの同期が完了しました。';

  @override
  String get profileServerAlreadyLatest => 'すでに最新です。サーバーのスナップショットが更新されました。';

  @override
  String profileServerSyncSummary(int uploaded, int downloaded, int applied) {
    return '$uploaded の変更をアップロードし、$downloaded サーバー イベントをプルし、$applied イベントを適用しました。';
  }

  @override
  String get profileServerBackupFound => 'サーバーのバックアップが見つかりました';

  @override
  String get profileServerBackupFoundMessage =>
      'このデバイスにはまだローカル トレーニング データがありません。サーバーのバックアップが利用可能です。このデバイスに復元しますか?まずローカルの安全スナップショットを作成します。';

  @override
  String get profileRestoreToDevice => 'このデバイスに復元';

  @override
  String get profileNormalSyncFailed => '通常の同期に失敗しました';

  @override
  String profileNormalSyncFailedMessage(String error) {
    return '通常の同期に失敗しました: $error\n\nサーバーのバックアップからこのデバイスを復元してみてください。まずローカルの安全スナップショットを作成します。';
  }

  @override
  String get profileRestoreFromBackup => 'バックアップから復元する';

  @override
  String profileServerAvailable(int version, int events) {
    return 'サーバー同期が利用可能です: プロトコル v$version、$events イベント。';
  }

  @override
  String profileServerTestFailed(String error) {
    return 'サーバー接続テストが失敗しました: $error';
  }

  @override
  String get profileDiagnosticsCopied => 'サーバー同期診断がコピーされました。';

  @override
  String get profileDiagnosticsFallbackCopied => '診断情報を完全に取得できなかったため、基本的なエラー情報をコピーしました。';

  @override
  String get profileRestoreComplete => '復元が完了しました';

  @override
  String profileRestoreSummary(int count, String snapshot) {
    return '$count ファイルを復元しました。\n安全スナップショット: $snapshot\n\nページデータがリロードされました。';
  }

  @override
  String get profileAcknowledged => 'わかりました';

  @override
  String profileRestoreFailed(String error) {
    return '復元に失敗しました: $error';
  }

  @override
  String get profileServerRestoreComplete => 'サーバーの復元が完了しました';

  @override
  String profileServerSnapshotRestoreFailed(String error) {
    return 'サーバースナップショットの復元に失敗しました: $error';
  }

  @override
  String get profileDatabasePreparing => 'データベースは復元されたばかりで、接続の準備中です。しばらくしてからもう一度お試しください。';

  @override
  String get profileServerReturnedHtml =>
      'サーバーからWebページが返されました。アドレスがYoursバックアップサーバーを指しているか確認してください。';

  @override
  String get profileTargetServer => 'ターゲットサーバー';

  @override
  String get planRecordModeStandard => '標準';

  @override
  String get planRecordModeFree => 'フリー記録';

  @override
  String get workoutRecordMode => '記録モード';

  @override
  String get workoutReplaceExercise => 'この種目を置き換える';

  @override
  String get workoutChooseExercise => '選択';

  @override
  String workoutExerciseReplaced(String from, String to) {
    return '「$from」を「$to」に置き換えました';
  }

  @override
  String get workoutCompleteFreeRecord => 'この項目を完了';

  @override
  String get workoutUndoFreeRecord => '項目の記録を取り消す';

  @override
  String get workoutActivityElapsed => '項目の所要時間';

  @override
  String get workoutDurationSeconds => '継続時間 s';

  @override
  String get workoutSavedLocal => 'ワークアウトをローカルに保存しました。';

  @override
  String workoutCompletedMixedSummary(int exercises, int sets, int freeRecords) {
    return '$exercises種目 · $setsセット · フリー項目$freeRecords件を完了';
  }

  @override
  String get homeFreeRecords => 'フリー項目';

  @override
  String homeSessionRecordCount(int sets, int freeRecords) {
    return '$setsセット · フリー項目$freeRecords件';
  }

  @override
  String homeActivityRecordCount(int count) {
    return 'アクティビティ記録$count件';
  }

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsDescription => '外観、言語、Yoursについて';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearanceDescription => 'テーマとディスプレイ';

  @override
  String get themeTitle => 'テーマ';

  @override
  String get themeSystem => 'システム';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get languageDescription => 'Yoursで使用する言語を選択';

  @override
  String get aboutDescription => 'Web サイト、バージョン、アップデート';

  @override
  String settingsCurrentValue(String value) {
    return '現在: $value';
  }

  @override
  String get errorBackupMissing => 'バックアップパッケージが存在しません。';

  @override
  String get errorBackupEmpty => 'サーバーは空のバックアップ パッケージを返しました。';

  @override
  String get errorInvalidBackup => '選択したファイルは有効なバックアップ パッケージではありません。';

  @override
  String get errorBackupManifestMissing => 'バックアップ パッケージには、manifest.json がないため、その形式を検証できません。';

  @override
  String get errorBackupDatabaseMissing => 'バックアップ パッケージに必要なデータベース ファイルがありません。';

  @override
  String get errorInvalidServerAddress => 'サーバーアドレスが無効です。 https://example.com などの形式を使用します。';

  @override
  String get errorServerTimeout => 'ネットワーク要求がタイムアウトしました。サーバーアドレス、HTTPS、および現在のネットワークを確認してください。';

  @override
  String get errorServerTls => 'HTTPS ハンドシェイクが失敗しました。ドメイン、証明書、現在のネットワークを確認してください。';

  @override
  String get errorServerUnreachable => 'サーバーに接続できませんでした。アドレス、ポート、HTTPS、リバースプロキシを確認してください。';

  @override
  String get errorServerInterrupted => 'ネットワーク要求が中断されました。サーバーアドレスと現在のネットワークを確認してください。';

  @override
  String get errorInvalidServerResponse => 'サーバーの応答が無効です。アドレスが Yours セルフホステッド同期サービスを指していることを確認します。';

  @override
  String get errorInvalidServerEvents => 'サーバー イベントの応答が無効です。';

  @override
  String get errorInvalidServerStatus => 'サーバーステータス応答が無効です。';

  @override
  String get errorNoServerBackup => '復元可能なバックアップ パッケージが見つかりませんでした。';

  @override
  String errorServerOutdated(int current, int required) {
    return 'セルフホスト型同期サービスは時代遅れです。現在のプロトコル v$current。 v$required が必要です。';
  }

  @override
  String errorUnappliedServerChanges(int count) {
    return '$count サーバーの変更を適用できませんでした。このデバイスをサーバーのバックアップから復元します。';
  }

  @override
  String get backupShareTitle => 'Yoursバックアップをエクスポート';

  @override
  String get backupShareSubject => 'Yoursバックアップ';

  @override
  String get backupShareText =>
      'これはYoursのバックアップパッケージです。iCloud Drive、ファイル、または別の場所に保存し、必要なときにファイルから復元できます。';

  @override
  String get exerciseExampleName => '例: ベンチプレス';

  @override
  String get exerciseExampleCategory => '例: 胸部';

  @override
  String get exerciseExampleEquipment => '例: バーベル';

  @override
  String get yoursVaultName => 'Yours Vault';
}
