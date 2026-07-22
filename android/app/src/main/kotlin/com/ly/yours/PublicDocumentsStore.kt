package com.ly.yours

import android.app.Activity
import android.content.ContentValues
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import java.io.File

internal class PublicDocumentsStore(
    private val activity: Activity,
    private val publicRoot: String = "有思"
) {
    private val resolver get() = activity.contentResolver

    private data class PublicFileCandidate(
        val id: Long,
        val displayName: String,
        val uri: Uri
    )

    fun syncBackup(source: File): Uri {
        require(source.exists()) { "Backup file does not exist" }
        return writePublicFile(
            source,
            "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/backups",
            "yours-backup.zip",
            "application/zip"
        )
    }

    fun syncVault(source: File): Int {
        require(source.exists() && source.isDirectory) { "Vault directory does not exist" }
        var copied = 0
        source.walkTopDown().filter { it.isFile }.forEach { file ->
            val relativeParent = file.parentFile?.takeUnless { it == source }
                ?.relativeTo(source)?.path?.replace(File.separatorChar, '/') ?: ""
            val relativePath = buildString {
                append("${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/YoursVault")
                if (relativeParent.isNotBlank()) append("/$relativeParent")
            }
            writePublicFile(file, relativePath, file.name, mimeTypeFor(file))
            copied += 1
        }
        return copied
    }

    fun importLatestBackup(): String? {
        val publicBackupDir = "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/backups"
        findLatestDirectPublicZip()?.let { return copyFileToLocalBackup(it) }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val uri = findPublicFileUri(publicBackupDir, "yours-backup.zip")
            ?: findLatestPublicZipUri(publicBackupDir)
            ?: return null
        return copyUriToLocalBackup(uri)
    }

    fun copyUriToLocalBackup(uri: Uri): String? {
        val output = localBackupFile()
        resolver.openInputStream(uri)?.use { input ->
            output.outputStream().use { stream -> input.copyTo(stream) }
        } ?: return null
        return output.absolutePath
    }

    fun writePublicFile(
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
            check(destinationDirectory.exists() || destinationDirectory.mkdirs()) {
                "Unable to create public directory"
            }
            val destination = File(destinationDirectory, filename)
            source.inputStream().use { input ->
                destination.outputStream().use { output -> input.copyTo(output) }
            }
            return Uri.fromFile(destination)
        }

        val ownedCandidates = ownedPublicFileCandidates(relativePath, filename)
        if (ownedCandidates.none { it.displayName == filename }) {
            overwritePersistedVaultFile(source, relativePath, filename)?.let { reconciled ->
                ownedCandidates.forEach { resolver.delete(it.uri, null, null) }
                return reconciled
            }
        }
        val existing = ownedCandidates.firstOrNull()?.uri
            ?: if (filename == "yours-backup.zip") findLatestPublicZipUri(relativePath) else null
        val isNew = existing == null
        val uri = existing ?: resolver.insert(
            MediaStore.Files.getContentUri("external"),
            ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, filename)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        ) ?: error("Unable to create public backup")

        try {
            resolver.openOutputStream(uri, "wt")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: error("Unable to write public backup")
            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null
            )
            removeOwnedPublicFileDuplicates(relativePath, filename, uri)
        } catch (error: Exception) {
            if (isNew) resolver.delete(uri, null, null)
            throw error
        }
        return uri
    }

    fun findPublicFileUri(relativePath: String, filename: String): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        return ownedPublicFileCandidates(relativePath, filename).firstOrNull()?.uri
    }

    private fun overwritePersistedVaultFile(
        source: File,
        relativePath: String,
        filename: String
    ): Uri? {
        val vaultPrefix = "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/YoursVault"
        if (relativePath != vaultPrefix && !relativePath.startsWith("$vaultPrefix/")) return null
        val root = resolver.persistedUriPermissions.asSequence()
            .filter { it.isReadPermission && it.isWritePermission }
            .mapNotNull { DocumentFile.fromTreeUri(activity, it.uri) }
            .firstOrNull {
                it.isDirectory && it.name.equals("YoursVault", ignoreCase = true)
            } ?: return null
        val relativeDirectory = relativePath.removePrefix(vaultPrefix).trim('/')
        var directory = root
        for (segment in relativeDirectory.split('/').filter { it.isNotEmpty() }) {
            directory = directory.findFile(segment)?.takeIf { it.isDirectory } ?: return null
        }
        val target = directory.findFile(filename)?.takeIf { it.isFile } ?: return null
        resolver.openOutputStream(target.uri, "wt")?.use { output ->
            source.inputStream().use { input -> input.copyTo(output) }
        } ?: return null
        return target.uri
    }

    private fun findLatestDirectPublicZip(): File? {
        val backupsDir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS),
            "$publicRoot/backups"
        )
        if (!backupsDir.isDirectory) return null
        return backupsDir.listFiles { file ->
            file.isFile && file.extension.equals("zip", ignoreCase = true)
        }?.maxByOrNull { it.lastModified() }
    }

    private fun copyFileToLocalBackup(source: File): String? {
        if (!source.isFile) return null
        val output = localBackupFile()
        source.inputStream().use { input ->
            output.outputStream().use { stream -> input.copyTo(stream) }
        }
        return output.absolutePath
    }

    private fun localBackupFile(): File {
        val backupsDir = File(
            activity.filesDir.parentFile ?: activity.filesDir,
            "app_flutter/backups"
        )
        backupsDir.mkdirs()
        return File(backupsDir, "yours-backup.zip")
    }

    private fun findLatestPublicZipUri(relativePath: String): Uri? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val collection = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection =
            "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val args = arrayOf("%.zip", "$relativePath/")
        val sortOrder = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
        resolver.query(collection, projection, selection, args, sortOrder)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                return Uri.withAppendedPath(collection, id.toString())
            }
        }
        return null
    }

    private fun ownedPublicFileCandidates(
        relativePath: String,
        filename: String
    ): List<PublicFileCandidate> {
        val collection = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME
        )
        val selection =
            "${MediaStore.MediaColumns.RELATIVE_PATH}=? AND ${MediaStore.MediaColumns.OWNER_PACKAGE_NAME}=?"
        val args = arrayOf("$relativePath/", activity.packageName)
        val candidates = mutableListOf<PublicFileCandidate>()
        resolver.query(collection, projection, selection, args, null)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            while (cursor.moveToNext()) {
                val displayName = cursor.getString(nameColumn) ?: continue
                if (!PublicFileNaming.isLogicalMatch(displayName, filename)) continue
                val id = cursor.getLong(idColumn)
                candidates += PublicFileCandidate(
                    id,
                    displayName,
                    Uri.withAppendedPath(collection, id.toString())
                )
            }
        }
        return candidates.sortedWith(
            compareBy<PublicFileCandidate> { it.displayName != filename }.thenBy { it.id }
        )
    }

    private fun removeOwnedPublicFileDuplicates(
        relativePath: String,
        filename: String,
        keep: Uri
    ) {
        ownedPublicFileCandidates(relativePath, filename)
            .filter { it.uri != keep }
            .forEach { resolver.delete(it.uri, null, null) }
    }

    private fun mimeTypeFor(file: File): String = when (file.extension.lowercase()) {
        "json" -> "application/json"
        "md" -> "text/markdown"
        "txt" -> "text/plain"
        "zip" -> "application/zip"
        else -> "application/octet-stream"
    }
}
