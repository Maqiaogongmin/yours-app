// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Yours';

  @override
  String get tabHome => 'Home';

  @override
  String get tabPlan => 'Plans';

  @override
  String get tabExercises => 'Exercises';

  @override
  String get tabProfile => 'Profile';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonSave => 'Save';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRestore => 'Restore';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonTest => 'Test';

  @override
  String get commonSyncNow => 'Sync Now';

  @override
  String get commonPendingSync => 'Pending';

  @override
  String get commonSynced => 'Synced';

  @override
  String get commonUnknownError => 'Unknown error';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get aboutYours => 'About Yours';

  @override
  String get officialWebsite => 'Website';

  @override
  String get githubRepository => 'GitHub Repository';

  @override
  String get planTitle => 'Training Plans';

  @override
  String get planCreate => 'New';

  @override
  String get planNewName => 'New Training Plan';

  @override
  String get planActive => 'Active';

  @override
  String get planArchived => 'Archived';

  @override
  String get planArchive => 'Archive';

  @override
  String get planRestoreActive => 'Restore';

  @override
  String get planNoActive => 'No training plans yet.';

  @override
  String get planNoArchived => 'No archived training plans.';

  @override
  String get planNone => 'No training plans';

  @override
  String planCount(int count) {
    return '$count plans · Local first';
  }

  @override
  String get planSwipeHint => 'Swipe left to edit or delete a plan';

  @override
  String get planScheduleReady => 'Schedule complete';

  @override
  String get planScheduleIncomplete => 'Schedule incomplete';

  @override
  String get planDeleteTitle => 'Delete Training Plan';

  @override
  String planDeleteMessage(String name) {
    return 'Delete “$name”? This change takes effect locally first and will be added to the sync queue.';
  }

  @override
  String planLocalSaveFailed(String error) {
    return 'Could not save the local training plan: $error';
  }

  @override
  String get planDaySelection => 'Choose Training Day';

  @override
  String planSummary(int weeks, int days) {
    return '$weeks weeks · $days days per week';
  }

  @override
  String planScheduledDays(String summary, int count) {
    return '$summary · $count scheduled days';
  }

  @override
  String planWeek(int week) {
    return 'Week $week';
  }

  @override
  String get planMarkWeekComplete => 'Mark as complete';

  @override
  String get planUnmarkWeekComplete => 'Remove completion mark';

  @override
  String get planNoActions => 'No exercises scheduled. Tap to add.';

  @override
  String get planRestoreArchivedTitle => 'Restore this plan?';

  @override
  String get planRestoreArchivedMessage =>
      'An archived plan must be restored before you can start a workout.';

  @override
  String planDatabaseInitFailed(String error) {
    return 'Could not initialize the local training database: $error';
  }

  @override
  String get planEditTitle => 'Edit Training Plan';

  @override
  String get planName => 'Plan Name';

  @override
  String get planCycle => 'Training Cycle';

  @override
  String get planWeeksSuffix => ' weeks  (1–12)';

  @override
  String get planDaysPerWeek => 'Days per Week';

  @override
  String get planDaysSuffix => ' days  (1–7)';

  @override
  String get planArrangement => 'Exercise Schedule';

  @override
  String planDayTitle(int week, int day) {
    return 'Week $week · D$day';
  }

  @override
  String get planDayName => 'Training Day Name';

  @override
  String get planAddExercise => 'Add Exercise';

  @override
  String planActionList(int count) {
    return 'Exercises ($count)';
  }

  @override
  String get planNoExerciseHint => 'No exercises yet. Tap Add Exercise to choose from the library.';

  @override
  String get planRemove => 'Remove';

  @override
  String get planSetSuffix => 'sets';

  @override
  String get planRepSuffix => 'reps';

  @override
  String get planRest => 'Rest';

  @override
  String get planDuration => 'Duration';

  @override
  String get planWeight => 'Weight';

  @override
  String get planNoteHint => 'Note, such as RIR 2, 6–8 reps, or slow eccentric';

  @override
  String get planAddFromLibrary => 'Add from Exercise Library';

  @override
  String planSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get planSearchLibrary => 'Search local exercise library';

  @override
  String get planNoMatchingExercise =>
      'No matching exercises. Add one in the Exercise Library first.';

  @override
  String get planAdded => 'Added';

  @override
  String get workoutEndTitle => 'End workout?';

  @override
  String get workoutEndIncomplete =>
      'This training plan is not complete. Saved workout data will be kept and marked as an incomplete workout.';

  @override
  String get workoutEndEmpty => 'No sets have been saved. Confirm to close workout mode.';

  @override
  String get workoutPostNote => 'Post-workout note';

  @override
  String get workoutPostNoteHint => 'For example: shoulder discomfort, skipped lateral raises';

  @override
  String get workoutEnd => 'End Workout';

  @override
  String get workoutTimer => 'Workout Timer';

  @override
  String get workoutSummary => 'Workout Summary';

  @override
  String get workoutDefaultDay => 'Default Training Day';

  @override
  String get workoutElapsed => 'Time';

  @override
  String get workoutExercise => 'Exercise';

  @override
  String get workoutCurrentExercise => 'Current Exercise';

  @override
  String get workoutRestSeconds => 'Rest s';

  @override
  String get workoutSaveSet => 'Save Set and Continue';

  @override
  String get workoutUndoSet => 'Undo Current Set';

  @override
  String get workoutRestBetween => 'Rest Between Sets';

  @override
  String get workoutNextSet => 'Next Set';

  @override
  String get workoutSkipRest => 'Skip Rest and Continue';

  @override
  String get workoutComplete => 'Workout Complete';

  @override
  String get workoutFinishSave => 'End and Save Workout';

  @override
  String get workoutOptional => 'Optional';

  @override
  String get workoutNote => 'Note';

  @override
  String get workoutTrainingNote => 'Workout Note';

  @override
  String workoutSavedBackup(String name) {
    return 'Workout saved and backed up automatically: $name';
  }

  @override
  String workoutSavedBackupFailed(String error) {
    return 'Workout saved, but automatic backup failed: $error';
  }

  @override
  String get workoutSetUndone => 'Current set record undone';

  @override
  String get workoutFirstSet => 'This is already the first set';

  @override
  String get workoutLastSet => 'This is already the last set';

  @override
  String workoutTimerStartFailed(String error) {
    return 'Workout timer failed to start: $error';
  }

  @override
  String get workoutNoActions =>
      'This training plan has no exercises yet. Edit the plan and add exercises first.';

  @override
  String get workoutNextSummary => 'Next: Workout Summary';

  @override
  String workoutNextSetLabel(String exercise, int set) {
    return 'Next set: $exercise · Set $set';
  }

  @override
  String get workoutUndoReturnLog => 'Undo current set and return to logging';

  @override
  String get workoutRestHint =>
      'The timer will pause here when it ends. Swiping only previews sets; it will not write or undo records.';

  @override
  String workoutCompletedSummary(int exercises, int sets) {
    return 'Completed $exercises exercises · $sets sets';
  }

  @override
  String get workoutUndoLastReturnLog => 'Undo last set and return to logging';

  @override
  String get workoutNoteHint => 'For example: RIR 2; rest 120s; rep range 6-8';

  @override
  String get homeTodayStatus => 'Today';

  @override
  String homeMonthTitle(int year, int month) {
    return '$month/$year';
  }

  @override
  String get homeWeekdays => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String homeDateTitle(int month, int day, String name) {
    return '$month/$day · $name';
  }

  @override
  String get homeNoWorkout => 'No workout';

  @override
  String get homeNoWorkoutRecord => 'No workout record for this day';

  @override
  String get homeRecorded => 'Recorded';

  @override
  String get homeIncomplete => 'Incomplete';

  @override
  String get homeTotalVolume => 'Total volume kg';

  @override
  String get homeEffectiveSets => 'Working sets';

  @override
  String get homeMinutes => 'Minutes';

  @override
  String get homeEmptyRecordMessage =>
      'No record for this day. Complete a workout to see volume, sets, duration, and notes here.';

  @override
  String get homeDefaultRecordName => 'Workout Record';

  @override
  String get homeDefaultIncompleteRecordName => 'Incomplete Workout';

  @override
  String get homeDefaultSavedNote => 'This workout has been saved to the local database.';

  @override
  String get homeIncompleteWorkoutMarker => 'Incomplete workout plan';

  @override
  String get homeRecordUpdated => 'Workout record updated';

  @override
  String homeSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get homeDeleteSessionTitle => 'Delete this workout record?';

  @override
  String homeDeleteSessionMessage(String time, int count) {
    return 'Delete the workout record at $time and its $count sets? This change will be added to the server sync queue.';
  }

  @override
  String get homeSessionDeleted => 'Workout record deleted';

  @override
  String homeDeleteFailed(String error) {
    return 'Could not delete: $error';
  }

  @override
  String homeWorkoutRecordTitle(int month, int day) {
    return 'Workout Records · $month/$day';
  }

  @override
  String get homeSaving => 'Saving...';

  @override
  String get homeNoSetRecords => 'No workout sets are available for this day.';

  @override
  String homeSetCount(int count) {
    return '$count sets';
  }

  @override
  String homeRecordCount(int count) {
    return '$count set records';
  }

  @override
  String homeStartedAt(String time) {
    return 'Started at $time';
  }

  @override
  String get homeSets => 'Sets';

  @override
  String get homeReps => 'Reps';

  @override
  String get homeWeightKg => 'Weight kg';

  @override
  String homeSetNote(String exercise, int setIndex, String note) {
    return '$exercise · Set $setIndex\n$note';
  }

  @override
  String get homeDashboardSettings => 'Dashboard Settings';

  @override
  String get homeCalendar => 'Calendar';

  @override
  String get commonDone => 'Done';

  @override
  String get sharePosterCreate => 'Create Poster';

  @override
  String get sharePosterTitle => 'Create Poster';

  @override
  String get sharePosterSaveToPhotos => 'Save to Photos';

  @override
  String get sharePosterSaving => 'Saving';

  @override
  String get sharePosterSavedToPhotos => 'Saved to Photos';

  @override
  String sharePosterSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get sharePosterRenderFailed => 'Could not render the workout poster.';

  @override
  String sharePosterPhotoFailed(String error) {
    return 'Could not choose photo: $error';
  }

  @override
  String get sharePosterBackground => 'Background';

  @override
  String get sharePosterComponents => 'Components';

  @override
  String get sharePosterUsePhoto => 'Use Photo';

  @override
  String get sharePosterPhotoSelected => 'Photo Background';

  @override
  String get sharePosterPresetDeepPurple => 'Deep Purple';

  @override
  String get sharePosterPresetWarmPaper => 'Warm Paper';

  @override
  String get sharePosterPresetEmber => 'Ember';

  @override
  String get sharePosterPresetForest => 'Forest';

  @override
  String get sharePosterWorkoutName => 'Workout Name';

  @override
  String get sharePosterDate => 'Date';

  @override
  String get sharePosterDuration => 'Duration';

  @override
  String get sharePosterExerciseCount => 'Exercises';

  @override
  String get sharePosterSetCount => 'Sets';

  @override
  String get sharePosterTotalVolume => 'Volume';

  @override
  String get sharePosterNote => 'Training Note';

  @override
  String get sharePosterBrand => 'Yours Mark';

  @override
  String get exerciseLibrary => 'Exercise Library';

  @override
  String get profileTitle => 'Profile';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get profileProcessingData => 'Processing data...';

  @override
  String get profileAboutLinks => 'Website and GitHub Repository';

  @override
  String get profileAboutLinksUpdate => 'Website, GitHub Repository, and Updates';

  @override
  String profileNewVersion(String version) {
    return 'New version $version';
  }

  @override
  String get profileVaultPathPending => 'Preparing path';

  @override
  String get profileVaultNotExported => 'Not exported yet';

  @override
  String profileLastVaultExport(String date) {
    return 'Last export: $date';
  }

  @override
  String get profileExportVault => 'Export Vault';

  @override
  String get profileImportInbox => 'Import inbox';

  @override
  String get profileBackupDescription =>
      'Create a backup, then save it to Files or another location';

  @override
  String get profileBackupPlaintextWarning =>
      'Backup files contain training data. Store them carefully and do not share them publicly.';

  @override
  String get profileBackupAndroidLocation =>
      'Backup files contain training data. On Android, they are visible in Documents/有思/backups.';

  @override
  String get profileBackupNotCreated => 'No backup yet';

  @override
  String profileLastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String profileLatestBackup(String name) {
    return 'Latest backup: $name';
  }

  @override
  String get profileProcessing => 'Processing...';

  @override
  String get profileCreateExport => 'Create and Export';

  @override
  String get profileRestoreFromFile => 'Restore from File';

  @override
  String get profileExportBackup => 'Export Backup';

  @override
  String get profileRestoreFromICloud => 'Restore from iCloud';

  @override
  String get profileCopyDiagnostics => 'Copy Diagnostics';

  @override
  String get profileLocalDataSafety => 'Local Data Safety';

  @override
  String get profileProcessingDataShort => 'Processing Data';

  @override
  String get profileExportingVault => 'Exporting Vault';

  @override
  String get profileNotCreated => 'Not created';

  @override
  String get profileAvailable => 'Available';

  @override
  String get profileManualExport => 'Manual Export';

  @override
  String get profileFile => 'File';

  @override
  String get profileReading => 'Loading';

  @override
  String profilePendingCount(int count) {
    return '$count';
  }

  @override
  String get profileConfigured => 'Configured';

  @override
  String get profileNotConfigured => 'Not configured';

  @override
  String get profileServerNotConfigured => 'Server sync is not configured';

  @override
  String get profileServerConfiguredHint =>
      'Server address is configured. Test the connection first.';

  @override
  String profileServerConnectionFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get profileNoServerSnapshot => 'No server snapshot';

  @override
  String profileRecentSnapshot(String date) {
    return 'Latest snapshot: $date';
  }

  @override
  String profileServerDetail(String backup, int events, int cursor) {
    return '$backup, $events events, cursor $cursor';
  }

  @override
  String get profileCheckingICloud => 'Checking iCloud Drive status';

  @override
  String get profileICloudAvailable => 'iCloud Drive is available.';

  @override
  String get profileICloudManualHint => 'Use it for manual export and restore';

  @override
  String get profileICloudSignedOut =>
      'This device is not signed in to iCloud, or iCloud Drive is disabled.';

  @override
  String get profileICloudContainerUnavailable =>
      'No iCloud data directory is available. Check iCloud Drive and the App ID configuration.';

  @override
  String get profileICloudUnsupported => 'iCloud Drive is not supported on this platform.';

  @override
  String get profileICloudUnknown => 'iCloud Drive status is unknown.';

  @override
  String get profileLocalFirstRecord => 'Local-first workout records';

  @override
  String get profileToggleDark => 'Switch to dark mode';

  @override
  String get profileToggleLight => 'Switch to light mode';

  @override
  String get profileServer => 'Server';

  @override
  String get profileCheckUpdates => 'Check for Updates';

  @override
  String get profileCheckingUpdates => 'Checking...';

  @override
  String get profileUpToDate => 'You are up to date';

  @override
  String get profileUpdateFailed => 'Could not check for updates';

  @override
  String get profileAndroidUpdate => 'Check for a new Android APK';

  @override
  String profileNewVersionDownload(String version) {
    return 'Version $version is available. Download it from the website.';
  }

  @override
  String get profileServerSettings => 'Server Backup Settings';

  @override
  String get profileServerAddress => 'Yours backup server address';

  @override
  String get profileApiKeyOptional => 'API key (optional)';

  @override
  String get profileApiKeyHint => 'Leave blank to omit Authorization';

  @override
  String get profileClear => 'Clear';

  @override
  String get serverSync => 'Server Sync';

  @override
  String get icloudDrive => 'iCloud Drive';

  @override
  String get backupPackage => 'Backup Package';

  @override
  String get notCategorized => 'Uncategorized';

  @override
  String get noDescription => 'No description';

  @override
  String get all => 'All';

  @override
  String get exerciseAdd => 'Add Exercise';

  @override
  String get exerciseEdit => 'Edit Exercise';

  @override
  String get exerciseSearchHint => 'Search exercises, such as bench press or squat';

  @override
  String get exerciseEmpty =>
      'Your local exercise library is empty. Tap Add to create an exercise.';

  @override
  String get exerciseNoMatch => 'No matching exercises. Try another category or clear the search.';

  @override
  String get exerciseLocalSubtitle => 'Curated locally · Available offline';

  @override
  String get exerciseName => 'Name';

  @override
  String get exerciseCategoryOne => 'Category 1';

  @override
  String get exerciseCategoryTwo => 'Category 2';

  @override
  String get exerciseDescription => 'Description';

  @override
  String get exerciseSaveLocal => 'Save to Local Exercise Library';

  @override
  String get exerciseNotFilled => 'Not provided';

  @override
  String get profileOpenLinkFailed => 'Could not open the link.';

  @override
  String profileRecentVaultExport(String name) {
    return 'Recently exported Vault: $name';
  }

  @override
  String profileVaultExportSummary(int plans, int workouts, int exercises) {
    return 'Yours Vault exported: $plans plans, $workouts workout records, $exercises exercises.';
  }

  @override
  String profileVaultExportAndroidSummary(int plans, int workouts, int exercises) {
    return 'Yours Vault exported: $plans plans, $workouts workout records, $exercises exercises. Public Documents will sync in the background.';
  }

  @override
  String profileRecentVaultExportFailed(String error) {
    return 'Recent Vault export failed: $error';
  }

  @override
  String profileVaultExportFailed(String error) {
    return 'Yours Vault export failed: $error';
  }

  @override
  String profileVaultImportSummary(int plans, int exercises, String skipped) {
    return 'Imported $plans plans and $exercises exercises from inbox$skipped.';
  }

  @override
  String profileSkippedFiles(int count) {
    return ', skipped $count files';
  }

  @override
  String profileVaultImportFailed(String error) {
    return 'Yours Vault import failed: $error';
  }

  @override
  String profileBackupCreated(String name) {
    return 'Backup package created: $name';
  }

  @override
  String profileBackupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String profileRecentBackupExport(String name) {
    return 'Recently exported backup: $name';
  }

  @override
  String profileBackupExportedICloud(String name) {
    return 'Backup exported to iCloud Drive: $name';
  }

  @override
  String profileRecentExportFailed(String error) {
    return 'Recent export failed: $error';
  }

  @override
  String profileICloudExportFailed(String error) {
    return 'iCloud Drive export failed: $error';
  }

  @override
  String profilePickBackupFailed(String error) {
    return 'Could not choose backup package: $error';
  }

  @override
  String get profilePickBackupCancelled => 'Backup selection canceled.';

  @override
  String get profileRestoreBackupTitle => 'Restore from this backup?';

  @override
  String profileRestoreBackupMessage(String name) {
    return 'Restore training plans, workout records, and the exercise library from $name. Yours will create a safety snapshot first.';
  }

  @override
  String profileRecentRestoreFailed(String error) {
    return 'Recent restore failed: $error';
  }

  @override
  String profilePickICloudBackupFailed(String error) {
    return 'Could not choose an iCloud Drive backup: $error';
  }

  @override
  String get profilePickICloudBackupCancelled => 'iCloud Drive backup selection canceled.';

  @override
  String get profileRestoreICloudTitle => 'Restore from iCloud Drive?';

  @override
  String get profileRestoringICloud => 'Restoring backup from iCloud Drive...';

  @override
  String get profileICloudRestoreComplete => 'iCloud Drive restore complete';

  @override
  String profileRecentICloudRestore(String name) {
    return 'Recently restored from iCloud Drive: $name';
  }

  @override
  String get profileServerAddressSaved => 'Server backup address saved.';

  @override
  String get profileServerAddressCleared => 'Server backup address cleared.';

  @override
  String get profileConfigureServerFirst => 'Configure the server backup address first.';

  @override
  String get profileConfigureServerSyncFirst => 'Configure the server sync address first.';

  @override
  String profileServerSyncFailed(String error) {
    return 'Server sync failed: $error';
  }

  @override
  String get profileServerSyncComplete => 'Server sync complete.';

  @override
  String get profileServerAlreadyLatest => 'Already up to date. Server snapshot refreshed.';

  @override
  String profileServerSyncSummary(int uploaded, int downloaded, int applied) {
    return 'Uploaded $uploaded changes, pulled $downloaded server events, and applied $applied events.';
  }

  @override
  String get profileServerBackupFound => 'Server backup found';

  @override
  String get profileServerBackupFoundMessage =>
      'This device has no local training data yet. A server backup is available. Restore it to this device? Yours will create a local safety snapshot first.';

  @override
  String get profileRestoreToDevice => 'Restore to this device';

  @override
  String get profileNormalSyncFailed => 'Normal sync failed';

  @override
  String profileNormalSyncFailedMessage(String error) {
    return 'Normal sync failed: $error\n\nYou can try restoring this device from the server backup. Yours will create a local safety snapshot first.';
  }

  @override
  String get profileRestoreFromBackup => 'Restore from backup';

  @override
  String profileServerAvailable(int version, int events) {
    return 'Server sync is available: protocol v$version, $events events.';
  }

  @override
  String profileServerTestFailed(String error) {
    return 'Server connection test failed: $error';
  }

  @override
  String get profileDiagnosticsCopied => 'Server sync diagnostics copied.';

  @override
  String get profileDiagnosticsFallbackCopied =>
      'Diagnostics were incomplete. Basic error info was copied.';

  @override
  String get profileRestoreComplete => 'Restore complete';

  @override
  String profileRestoreSummary(int count, String snapshot) {
    return 'Restored $count files.\nSafety snapshot: $snapshot\n\nPage data has been reloaded.';
  }

  @override
  String get profileAcknowledged => 'OK';

  @override
  String profileRestoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get profileServerRestoreComplete => 'Server restore complete';

  @override
  String profileServerSnapshotRestoreFailed(String error) {
    return 'Server snapshot restore failed: $error';
  }

  @override
  String get profileDatabasePreparing =>
      'The database was just restored and is preparing its connection. Try again shortly.';

  @override
  String get profileServerReturnedHtml =>
      'The server returned a web page. Check that the address points to the Yours backup server.';

  @override
  String get profileTargetServer => 'target server';

  @override
  String get planRecordModeStandard => 'Standard';

  @override
  String get planRecordModeFree => 'Free';

  @override
  String get workoutRecordMode => 'Record Mode';

  @override
  String get workoutReplaceExercise => 'Replace This Exercise';

  @override
  String get workoutChooseExercise => 'Choose';

  @override
  String workoutExerciseReplaced(String from, String to) {
    return 'Replaced $from with $to';
  }

  @override
  String get workoutCompleteFreeRecord => 'Complete Item';

  @override
  String get workoutUndoFreeRecord => 'Undo Item Record';

  @override
  String get workoutActivityElapsed => 'Item Time';

  @override
  String get workoutDurationSeconds => 'Duration s';

  @override
  String get workoutSavedLocal => 'Workout saved locally.';

  @override
  String workoutCompletedMixedSummary(int exercises, int sets, int freeRecords) {
    return 'Completed $exercises exercises · $sets sets · $freeRecords free items';
  }

  @override
  String get homeFreeRecords => 'Free Items';

  @override
  String homeSessionRecordCount(int sets, int freeRecords) {
    return '$sets sets · $freeRecords free items';
  }

  @override
  String homeActivityRecordCount(int count) {
    return '$count activity records';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsDescription => 'Appearance, language, and About Yours';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceDescription => 'Theme and display';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageDescription => 'Choose the language used by Yours';

  @override
  String get aboutDescription => 'Website, version, and updates';

  @override
  String settingsCurrentValue(String value) {
    return 'Current: $value';
  }

  @override
  String get errorBackupMissing => 'The backup package does not exist.';

  @override
  String get errorBackupEmpty => 'The server returned an empty backup package.';

  @override
  String get errorInvalidBackup => 'The selected file is not a valid Yours backup package.';

  @override
  String get errorBackupManifestMissing =>
      'The backup package is missing manifest.json, so its format cannot be verified.';

  @override
  String get errorBackupDatabaseMissing => 'The backup package is missing required database files.';

  @override
  String get errorInvalidServerAddress =>
      'The server address is invalid. Use a format such as https://example.com.';

  @override
  String get errorServerTimeout =>
      'The network request timed out. Check the server address, HTTPS, and current network.';

  @override
  String get errorServerTls =>
      'The HTTPS handshake failed. Check the domain, certificate, and current network.';

  @override
  String get errorServerUnreachable =>
      'Could not connect to the server. Check the address, port, HTTPS, and reverse proxy.';

  @override
  String get errorServerInterrupted =>
      'The network request was interrupted. Check the server address and current network.';

  @override
  String get errorInvalidServerResponse =>
      'The server response is invalid. Confirm the address points to the Yours self-hosted sync service.';

  @override
  String get errorInvalidServerEvents => 'The server events response is invalid.';

  @override
  String get errorInvalidServerStatus => 'The server status response is invalid.';

  @override
  String get errorNoServerBackup => 'No restorable backup package was found.';

  @override
  String errorServerOutdated(int current, int required) {
    return 'The self-hosted sync service is outdated. Current protocol v$current; required v$required.';
  }

  @override
  String errorUnappliedServerChanges(int count) {
    return '$count server changes could not be applied. Restore this device from the server backup.';
  }

  @override
  String get backupShareTitle => 'Export Yours Backup';

  @override
  String get backupShareSubject => 'Yours Backup';

  @override
  String get backupShareText =>
      'This is a Yours backup package. Save it to iCloud Drive, Files, or another location, then restore it from a file when needed.';

  @override
  String get exerciseExampleName => 'Example: Bench Press';

  @override
  String get exerciseExampleCategory => 'Example: Chest';

  @override
  String get exerciseExampleEquipment => 'Example: Barbell';

  @override
  String get yoursVaultName => 'Yours Vault';
}
