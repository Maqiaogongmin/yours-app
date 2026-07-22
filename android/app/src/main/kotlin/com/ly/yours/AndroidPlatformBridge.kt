package com.ly.yours

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

internal class AndroidPlatformBridge(private val activity: YoursPlatformActivity) {
    private val documents = PublicDocumentsStore(activity)
    private val backupPicker = BackupPickerCoordinator(activity, documents)
    private val photos = PhotoCoordinator(activity)
    private val permissions = StoragePermissionCoordinator(activity)
    private val vault = VaultInboxCoordinator(activity, documents, { backupPicker.isBusy })

    fun register(flutterEngine: FlutterEngine) {
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, "yours/files").setMethodCallHandler { call, result ->
            when (call.method) {
                "syncBackupToPublicDocuments" -> {
                    val sourcePath = call.argument<String>("path")
                    if (sourcePath.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Missing backup path", null)
                        return@setMethodCallHandler
                    }
                    permissions.run(result) {
                        try {
                            result.success(documents.syncBackup(File(sourcePath)).toString())
                        } catch (error: Exception) {
                            result.error("SYNC_PUBLIC_BACKUP_FAILED", error.message, null)
                        }
                    }
                }
                "importPublicBackup" -> permissions.run(result) {
                    try {
                        result.success(documents.importLatestBackup())
                    } catch (error: Exception) {
                        result.error("IMPORT_PUBLIC_BACKUP_FAILED", error.message, null)
                    }
                }
                "pickPublicBackup" -> try {
                    backupPicker.pick(result)
                } catch (error: Exception) {
                    result.error("PICK_PUBLIC_BACKUP_FAILED", error.message, null)
                }
                "prepareDefaultVaultInboxImport" -> permissions.run(result) {
                    try {
                        vault.prepareDefault(result)
                    } catch (error: Exception) {
                        result.error("VAULT_INBOX_PREPARE_FAILED", error.message, null)
                    }
                }
                "completeVaultInboxImport" -> try {
                    vault.complete(call, result)
                } catch (error: Exception) {
                    result.error("VAULT_IMPORT_COMPLETE_FAILED", error.message, null)
                }
                "syncVaultToPublicDocuments" -> {
                    val sourcePath = call.argument<String>("path")
                    if (sourcePath.isNullOrBlank()) {
                        result.error("INVALID_PATH", "Missing vault path", null)
                        return@setMethodCallHandler
                    }
                    permissions.run(result) {
                        try {
                            result.success(documents.syncVault(File(sourcePath)))
                        } catch (error: Exception) {
                            result.error("SYNC_PUBLIC_VAULT_FAILED", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, "yours/photos").setMethodCallHandler { call, result ->
            when (call.method) {
                "pickPosterBackground" -> try {
                    photos.pickBackground(result)
                } catch (error: Exception) {
                    result.error("PHOTO_PICKER_FAILED", error.message, null)
                }
                "saveImageToPhotos" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes == null || bytes.isEmpty()) {
                        result.error("BAD_ARGS", "Missing poster image data", null)
                        return@setMethodCallHandler
                    }
                    permissions.run(result) {
                        try {
                            photos.saveImage(bytes)
                            result.success(true)
                        } catch (error: Exception) {
                            result.error("PHOTO_SAVE_FAILED", error.message, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backupPicker.onActivityResult(requestCode, resultCode, data)) return
        if (vault.onActivityResult(requestCode, resultCode, data)) return
        photos.onActivityResult(requestCode, resultCode, data)
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray) {
        permissions.onRequestPermissionsResult(requestCode, grantResults)
    }
}
