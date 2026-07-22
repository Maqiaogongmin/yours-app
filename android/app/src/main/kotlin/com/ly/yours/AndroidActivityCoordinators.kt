package com.ly.yours

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import java.io.File

internal interface ActivityResultHandler {
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean
}

internal class BackupPickerCoordinator(
    private val activity: Activity,
    private val documents: PublicDocumentsStore
) : ActivityResultHandler {
    private val requestCode = 4107
    private var pendingResult: MethodChannel.Result? = null
    val isBusy get() = pendingResult != null

    fun pick(result: MethodChannel.Result) {
        if (isBusy) {
            result.error("BACKUP_PICKER_BUSY", "Backup picker is already open", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/zip", "application/octet-stream", "application/x-zip-compressed")
            )
        }
        activity.startActivityForResult(intent, requestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != this.requestCode) return false
        val pending = pendingResult ?: return true
        pendingResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(null)
            return true
        }
        try {
            pending.success(documents.copyUriToLocalBackup(uri))
        } catch (error: Exception) {
            pending.error("PICKED_BACKUP_COPY_FAILED", error.message, null)
        }
        return true
    }
}

internal class PhotoCoordinator(
    private val activity: Activity,
    private val publicRoot: String = "有思"
) : ActivityResultHandler {
    private val requestCode = 4109
    private var pendingResult: MethodChannel.Result? = null

    fun pickBackground(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("PHOTO_PICKER_BUSY", "A photo picker is already open", null)
            return
        }
        pendingResult = result
        activity.startActivityForResult(
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/*"
            },
            requestCode
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != this.requestCode) return false
        val pending = pendingResult ?: return true
        pendingResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(null)
            return true
        }
        try {
            pending.success(copyBackground(uri))
        } catch (error: Exception) {
            pending.error("PHOTO_PICKER_COPY_FAILED", error.message, null)
        }
        return true
    }

    private fun copyBackground(uri: Uri): String {
        val extension = when (activity.contentResolver.getType(uri)?.lowercase()) {
            "image/png" -> "png"
            "image/webp" -> "webp"
            else -> "jpg"
        }
        val directory = File(
            activity.filesDir.parentFile ?: activity.filesDir,
            "app_flutter/poster_backgrounds"
        )
        directory.mkdirs()
        val output = File(directory, "poster-background-${System.currentTimeMillis()}.$extension")
        activity.contentResolver.openInputStream(uri)?.use { input ->
            output.outputStream().use { stream -> input.copyTo(stream) }
        } ?: error("Unable to read selected photo")
        return output.absolutePath
    }

    fun saveImage(bytes: ByteArray): Uri {
        val filename = "yours-poster-${System.currentTimeMillis()}.png"
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val pictures = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
            val directory = File(pictures, publicRoot)
            check(directory.exists() || directory.mkdirs()) {
                "Unable to create public pictures directory"
            }
            val destination = File(directory, filename)
            destination.outputStream().use { it.write(bytes) }
            MediaScannerConnection.scanFile(
                activity.applicationContext,
                arrayOf(destination.absolutePath),
                arrayOf("image/png"),
                null
            )
            return Uri.fromFile(destination)
        }

        val resolver = activity.contentResolver
        val uri = resolver.insert(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/png")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/$publicRoot")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        ) ?: error("Unable to create photo entry")
        try {
            resolver.openOutputStream(uri, "w")?.use { it.write(bytes) }
                ?: error("Unable to write poster image")
            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null
            )
        } catch (error: Exception) {
            resolver.delete(uri, null, null)
            throw error
        }
        return uri
    }
}

internal class StoragePermissionCoordinator(private val activity: Activity) {
    private val requestCode = 4108
    private var pendingAction: (() -> Unit)? = null
    private var pendingResult: MethodChannel.Result? = null

    fun run(result: MethodChannel.Result, action: () -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            action()
            return
        }
        if (pendingAction != null) {
            result.error("STORAGE_PERMISSION_BUSY", "A storage permission request is active", null)
            return
        }
        pendingAction = action
        pendingResult = result
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            ),
            requestCode
        )
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != this.requestCode) return false
        val action = pendingAction
        val result = pendingResult
        pendingAction = null
        pendingResult = null
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
        return true
    }
}
