enum YoursErrorCode {
  backupMissing,
  backupEmpty,
  invalidBackup,
  backupManifestMissing,
  backupDatabaseMissing,
  iCloudUnavailable,
  iCloudSignedOut,
  iCloudUnsupported,
  iCloudUnknown,
  serverNotConfigured,
  invalidServerAddress,
  serverTimeout,
  serverTls,
  serverUnreachable,
  serverInterrupted,
  invalidServerResponse,
  invalidServerEvents,
  invalidServerStatus,
  noServerBackup,
  serverOutdated,
  unappliedServerChanges,
  workoutEmptySessionActionRequired,
}

final class YoursException implements Exception {
  const YoursException(
    this.code, {
    this.count,
    this.currentVersion,
    this.requiredVersion,
    this.cause,
  });

  final YoursErrorCode code;
  final int? count;
  final int? currentVersion;
  final int? requiredVersion;
  final Object? cause;

  @override
  String toString() => 'YoursException($code)';
}
