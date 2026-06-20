import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yours/redesign/data/backup_models.dart';
import 'package:yours/redesign/data/yours_exception.dart';

class BackupPlatformBridge {
  static const _visibleFilesChannel = MethodChannel('yours/files');

  Future<ShareResult> shareBackup(
    File backup, {
    Rect? sharePositionOrigin,
    required String title,
    required String subject,
    required String text,
  }) async {
    if (!backup.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }
    return SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: subject,
        text: text,
        files: [XFile(backup.path, mimeType: 'application/zip')],
        fileNameOverrides: const ['yours-backup.zip'],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  Future<ICloudDriveStatus> getICloudStatus() async {
    if (!Platform.isIOS) {
      return ICloudDriveStatus.unsupported;
    }
    try {
      final raw = await _visibleFilesChannel.invokeMethod<Map<Object?, Object?>>(
        'getICloudStatus',
      );
      if (raw == null) {
        return const ICloudDriveStatus(
          available: false,
          state: 'unknown',
          message: '无法读取 iCloud Drive 状态。',
        );
      }
      return ICloudDriveStatus.fromMap(raw);
    } on MissingPluginException {
      return const ICloudDriveStatus(
        available: false,
        state: 'missingPlugin',
        message: '当前安装包缺少 iCloud Drive 文件通道。',
      );
    } on PlatformException catch (error) {
      return ICloudDriveStatus(
        available: false,
        state: error.code,
        message: friendlyPlatformMessage(error),
      );
    }
  }

  Future<ICloudDriveExportResult> exportBackupToICloudDrive(File backup) async {
    if (!Platform.isIOS) {
      throw const YoursException(YoursErrorCode.iCloudUnsupported);
    }
    if (!backup.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>(
        'exportBackupToICloudDrive',
        {'path': backup.path},
      );
      if (path == null || path.trim().isEmpty) {
        throw StateError('iCloud Drive 未返回导出路径。');
      }
      return ICloudDriveExportResult(path: path, exportedAt: DateTime.now());
    } on PlatformException catch (error) {
      throw StateError(friendlyPlatformMessage(error));
    }
  }

  Future<File?> pickBackupFile() async {
    if (Platform.isIOS) {
      return pickICloudBackup();
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final picked = result.files.single;
    final path = picked.path;
    if (path == null || path.trim().isEmpty) {
      throw const YoursException(YoursErrorCode.invalidBackup);
    }
    final file = File(path);
    if (!file.existsSync()) {
      throw const YoursException(YoursErrorCode.backupMissing);
    }
    return file;
  }

  Future<File?> pickICloudBackup() async {
    if (!Platform.isIOS) {
      return null;
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>('pickICloudBackup');
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      final file = File(path);
      if (!file.existsSync()) {
        throw const YoursException(YoursErrorCode.backupMissing);
      }
      if (!looksLikeZip(
        await file
            .openRead(0, 4)
            .fold<List<int>>(
              <int>[],
              (bytes, chunk) => bytes..addAll(chunk),
            ),
      )) {
        throw const YoursException(YoursErrorCode.invalidBackup);
      }
      return file;
    } on MissingPluginException {
      throw StateError('当前安装包缺少 iCloud Drive 文件选择通道。');
    } on PlatformException catch (error) {
      throw StateError(friendlyPlatformMessage(error));
    }
  }

  Future<void> syncBackupToVisibleDocuments(File backup) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _visibleFilesChannel.invokeMethod<String>(
        'syncBackupToPublicDocuments',
        {'path': backup.path},
      );
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  Future<File?> copyVisibleBackupIntoLocalDirectory() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>('importPublicBackup');
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      final file = File(path);
      return file.existsSync() ? file : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<File?> pickVisibleBackupIntoLocalDirectory() async {
    if (!Platform.isAndroid) {
      return null;
    }
    try {
      final path = await _visibleFilesChannel.invokeMethod<String>('pickPublicBackup');
      if (path == null || path.trim().isEmpty) {
        return null;
      }
      final file = File(path);
      return file.existsSync() ? file : null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static bool looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);
  }

  static String friendlyPlatformMessage(PlatformException error) {
    final message = error.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    if (error.code.contains('icloud')) {
      return 'iCloud Drive 操作失败。请确认设备已登录 iCloud，且 iCloud Drive 已开启。';
    }
    return '文件操作失败：${error.code}';
  }
}
