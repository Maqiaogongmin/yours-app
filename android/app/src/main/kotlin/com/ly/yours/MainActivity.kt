package com.ly.yours

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val filesChannelName = "yours/files"
    private val publicRoot = "有思"
    private val backupPickerRequestCode = 4107
    private val storagePermissionRequestCode = 4108
    private var pendingBackupPickerResult: MethodChannel.Result? = null
    private var pendingStorageAction: (() -> Unit)? = null
    private var pendingStorageResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, filesChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncBackupToPublicDocuments" -> {
                        val sourcePath = call.argument<String>("path")
                        if (sourcePath.isNullOrBlank()) {
                            result.error("INVALID_PATH", "Missing backup path", null)
                            return@setMethodCallHandler
                        }
                        withLegacyStoragePermission(result) {
                            try {
                                val uri = syncBackupToPublicDocuments(File(sourcePath))
                                result.success(uri.toString())
                            } catch (error: Exception) {
                                result.error("SYNC_PUBLIC_BACKUP_FAILED", error.message, null)
                            }
                        }
                    }
                    "importPublicBackup" -> {
                        withLegacyStoragePermission(result) {
                            try {
                                result.success(importPublicBackup())
                            } catch (error: Exception) {
                                result.error("IMPORT_PUBLIC_BACKUP_FAILED", error.message, null)
                            }
                        }
                    }
                    "pickPublicBackup" -> {
                        try {
                            pickPublicBackup(result)
                        } catch (error: Exception) {
                            result.error("PICK_PUBLIC_BACKUP_FAILED", error.message, null)
                        }
                    }
                    "syncVaultToPublicDocuments" -> {
                        val sourcePath = call.argument<String>("path")
                        if (sourcePath.isNullOrBlank()) {
                            result.error("INVALID_PATH", "Missing vault path", null)
                            return@setMethodCallHandler
                        }
                        withLegacyStoragePermission(result) {
                            try {
                                result.success(syncVaultToPublicDocuments(File(sourcePath)))
                            } catch (error: Exception) {
                                result.error("SYNC_PUBLIC_VAULT_FAILED", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun syncBackupToPublicDocuments(source: File): Uri {
        if (!source.exists()) {
            throw IllegalStateException("Backup file does not exist")
        }

        val resolver = applicationContext.contentResolver
        val relativePath = "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/backups"
        val filename = "yours-backup.zip"
        return writePublicFile(source, relativePath, filename, "application/zip")
    }

    private fun syncVaultToPublicDocuments(source: File): Int {
        if (!source.exists() || !source.isDirectory) {
            throw IllegalStateException("Vault directory does not exist")
        }

        var copied = 0
        source.walkTopDown()
            .filter { it.isFile }
            .forEach { file ->
                val parent = file.parentFile
                val relativeParent = if (parent == null || parent == source) {
                    ""
                } else {
                    parent.relativeTo(source).path.replace(File.separatorChar, '/')
                }
                val relativePath = buildString {
                    append(Environment.DIRECTORY_DOCUMENTS)
                    append("/")
                    append(publicRoot)
                    append("/YoursVault")
                    if (relativeParent.isNotBlank()) {
                        append("/")
                        append(relativeParent)
                    }
                }
                writePublicFile(file, relativePath, file.name, mimeTypeFor(file))
                copied += 1
            }
        return copied
    }

    private fun writePublicFile(
        source: File,
        relativePath: String,
        filename: String,
        mimeType: String
    ): Uri {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val documents = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS
            )
            val relativeDirectory = relativePath
                .removePrefix("${Environment.DIRECTORY_DOCUMENTS}/")
                .trim('/')
            val destinationDirectory = File(documents, relativeDirectory)
            if (!destinationDirectory.exists() && !destinationDirectory.mkdirs()) {
                throw IllegalStateException("Unable to create public directory")
            }
            val destination = File(destinationDirectory, filename)
            source.inputStream().use { input ->
                destination.outputStream().use { output -> input.copyTo(output) }
            }
            return Uri.fromFile(destination)
        }

        val resolver = applicationContext.contentResolver
        val existing = findPublicFileUri(relativePath, filename)
            ?: if (filename == "yours-backup.zip") {
                findLatestPublicZipUri(relativePath)
            } else {
                null
            }
        val isNew = existing == null
        val uri = existing ?: resolver.insert(
            MediaStore.Files.getContentUri("external"),
            ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        ) ?: throw IllegalStateException("Unable to create public backup")

        try {
            resolver.openOutputStream(uri, "wt")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IllegalStateException("Unable to write public backup")
            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null
            )
        } catch (error: Exception) {
            if (isNew) {
                resolver.delete(uri, null, null)
            }
            throw error
        }
        return uri
    }

    private fun importPublicBackup(): String? {
        val publicBackupDir = "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/backups"
        val directFile = findLatestDirectPublicZip()
        if (directFile != null) {
            return copyFileToLocalBackup(directFile)
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }
        val uri = findPublicFileUri(publicBackupDir, "yours-backup.zip")
            ?: findLatestPublicZipUri(publicBackupDir)
            ?: return null
        return copyUriToLocalBackup(uri)
    }

    private fun pickPublicBackup(result: MethodChannel.Result) {
        if (pendingBackupPickerResult != null) {
            result.error("BACKUP_PICKER_BUSY", "Backup picker is already open", null)
            return
        }
        pendingBackupPickerResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/zip", "application/octet-stream", "application/x-zip-compressed")
            )
        }
        startActivityForResult(intent, backupPickerRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != backupPickerRequestCode) {
            return
        }
        val pending = pendingBackupPickerResult ?: return
        pendingBackupPickerResult = null
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            return
        }
        val uri = data?.data
        if (uri == null) {
            pending.success(null)
            return
        }
        try {
            pending.success(copyUriToLocalBackup(uri))
        } catch (error: Exception) {
            pending.error("PICKED_BACKUP_COPY_FAILED", error.message, null)
        }
    }

    private fun findLatestDirectPublicZip(): File? {
        val backupsDir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS),
            "$publicRoot/backups"
        )
        if (!backupsDir.exists() || !backupsDir.isDirectory) {
            return null
        }
        return backupsDir.listFiles { file ->
            file.isFile && file.extension.equals("zip", ignoreCase = true)
        }?.maxByOrNull { it.lastModified() }
    }

    private fun copyFileToLocalBackup(source: File): String? {
        if (!source.exists() || !source.isFile) {
            return null
        }
        val output = localBackupFile()
        source.inputStream().use { input ->
            output.outputStream().use { stream -> input.copyTo(stream) }
        }
        return output.absolutePath
    }

    private fun copyUriToLocalBackup(uri: Uri): String? {
        val output = localBackupFile()
        contentResolver.openInputStream(uri)?.use { input ->
            output.outputStream().use { stream -> input.copyTo(stream) }
        } ?: return null
        return output.absolutePath
    }

    private fun localBackupFile(): File {
        val backupsDir = File(filesDir.parentFile ?: filesDir, "app_flutter/backups")
        backupsDir.mkdirs()
        return File(backupsDir, "yours-backup.zip")
    }

    private fun findLatestPublicZipUri(relativePath: String): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }
        val collection = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        } else {
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        }
        val args = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf("%.zip", "$relativePath/")
        } else {
            arrayOf("%.zip")
        }
        val sortOrder = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
        contentResolver.query(collection, projection, selection, args, sortOrder)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                return Uri.withAppendedPath(collection, id.toString())
            }
        }
        return null
    }

    private fun findPublicFileUri(relativePath: String, filename: String): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return null
        }
        val collection = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        } else {
            "${MediaStore.MediaColumns.DISPLAY_NAME}=?"
        }
        val args = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            arrayOf(filename, "$relativePath/")
        } else {
            arrayOf(filename)
        }
        contentResolver.query(collection, projection, selection, args, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                return Uri.withAppendedPath(collection, id.toString())
            }
        }
        return null
    }

    private fun withLegacyStoragePermission(
        result: MethodChannel.Result,
        action: () -> Unit
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            action()
            return
        }
        if (pendingStorageAction != null) {
            result.error("STORAGE_PERMISSION_BUSY", "A storage permission request is active", null)
            return
        }
        pendingStorageAction = action
        pendingStorageResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ),
            storagePermissionRequestCode
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != storagePermissionRequestCode) {
            return
        }
        val action = pendingStorageAction
        val result = pendingStorageResult
        pendingStorageAction = null
        pendingStorageResult = null
        if (grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        ) {
            action?.invoke()
        } else {
            result?.error(
                "STORAGE_PERMISSION_DENIED",
                "Storage permission is required to use public Documents on this Android version",
                null
            )
        }
    }

    private fun mimeTypeFor(file: File): String {
        return when (file.extension.lowercase()) {
            "json" -> "application/json"
            "md" -> "text/markdown"
            "txt" -> "text/plain"
            "zip" -> "application/zip"
            else -> "application/octet-stream"
        }
    }
}
