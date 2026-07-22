import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:yours/redesign/data/yours_exception.dart';
import 'package:yours/redesign/localization/localization.dart';

String localizedErrorDetail(BuildContext context, Object error) {
  if (error is YoursException) {
    final detail = switch (error.code) {
      YoursErrorCode.backupMissing => context.l10n.errorBackupMissing,
      YoursErrorCode.backupEmpty => context.l10n.errorBackupEmpty,
      YoursErrorCode.invalidBackup => context.l10n.errorInvalidBackup,
      YoursErrorCode.backupManifestMissing => context.l10n.errorBackupManifestMissing,
      YoursErrorCode.backupDatabaseMissing => context.l10n.errorBackupDatabaseMissing,
      YoursErrorCode.iCloudUnavailable => context.l10n.profileICloudContainerUnavailable,
      YoursErrorCode.iCloudSignedOut => context.l10n.profileICloudSignedOut,
      YoursErrorCode.iCloudUnsupported => context.l10n.profileICloudUnsupported,
      YoursErrorCode.iCloudUnknown => context.l10n.profileICloudUnknown,
      YoursErrorCode.serverNotConfigured => context.l10n.profileConfigureServerFirst,
      YoursErrorCode.invalidServerAddress => context.l10n.errorInvalidServerAddress,
      YoursErrorCode.serverTimeout => context.l10n.errorServerTimeout,
      YoursErrorCode.serverTls => context.l10n.errorServerTls,
      YoursErrorCode.serverUnreachable => context.l10n.errorServerUnreachable,
      YoursErrorCode.serverInterrupted => context.l10n.errorServerInterrupted,
      YoursErrorCode.invalidServerResponse => context.l10n.errorInvalidServerResponse,
      YoursErrorCode.invalidServerEvents => context.l10n.errorInvalidServerEvents,
      YoursErrorCode.invalidServerStatus => context.l10n.errorInvalidServerStatus,
      YoursErrorCode.noServerBackup => context.l10n.errorNoServerBackup,
      YoursErrorCode.serverOutdated => context.l10n.errorServerOutdated(
        error.currentVersion ?? 0,
        error.requiredVersion ?? 0,
      ),
      YoursErrorCode.unappliedServerChanges => context.l10n.errorUnappliedServerChanges(
        error.count ?? 0,
      ),
      YoursErrorCode.workoutEmptySessionActionRequired =>
        context.l10n.errorWorkoutEmptySessionActionRequired,
    };
    final cause = error.cause?.toString().trim();
    if (cause == null || cause.isEmpty) {
      return detail;
    }
    return '$detail\n$cause';
  }

  if (error is PlatformException) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return error.code;
  }

  if (error is String) {
    final message = error.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }

  return context.l10n.commonUnknownError;
}
