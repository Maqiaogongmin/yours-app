package com.ly.yours

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

internal class VaultInboxCoordinator(
    private val activity: Activity,
    private val documents: PublicDocumentsStore,
    private val otherPickerBusy: () -> Boolean,
    private val publicRoot: String = "有思"
) : ActivityResultHandler {
    private val requestCode = 4110
    private val logTag = "YoursFilesBridge"
    private var pendingResult: MethodChannel.Result? = null
    private val sessions = mutableMapOf<String, VaultInboxSession>()

    private data class VaultInboxSession(
        val stagingDirectory: File,
        val files: Map<String, Uri>,
        val documentTreeUri: Uri? = null
    )

    private data class DocumentVaultInbox(
        val treeUri: Uri,
        val inbox: DocumentFile
    )

    fun prepareDefault(result: MethodChannel.Result) {
        val persistedInbox = findPersistedDocumentVaultInbox()
        if (persistedInbox != null) {
            prepareSession(
                result,
                listDocumentVaultInboxFiles(persistedInbox.inbox),
                documentTreeUri = persistedInbox.treeUri
            )
            return
        }
        val relativePath = "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/YoursVault/inbox"
        val sources = findPublicVaultInboxFiles(relativePath)
        if (sources.isEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            pick(result)
            return
        }
        prepareSession(result, sources)
    }

    fun complete(call: MethodCall, result: MethodChannel.Result) {
        val session = call.argument<String>("token")?.let { sessions.remove(it) }
        if (session == null) {
            result.error(
                "VAULT_IMPORT_SESSION_MISSING",
                "The selected Vault import session is no longer available",
                null
            )
            return
        }
        val importedFiles = call.argument<List<String>>("importedFiles") ?: emptyList()
        val failures = mutableListOf<String>()
        try {
            if (session.documentTreeUri == null) {
                importedFiles.forEach { name ->
                    val sourceUri = session.files[name] ?: return@forEach
                    try {
                        archivePublicFile(
                            name,
                            sourceUri,
                            File(session.stagingDirectory, "inbox/$name")
                        )
                    } catch (_: Exception) {
                        failures += name
                    }
                }
            } else if (importedFiles.isNotEmpty()) {
                try {
                    archiveDocumentFiles(
                        session.documentTreeUri,
                        session,
                        importedFiles,
                        failures
                    )
                } catch (error: Exception) {
                    Log.w(logTag, "Unable to archive imported YoursVault files", error)
                    failures += importedFiles
                }
            }
            result.success(failures.distinct())
        } finally {
            session.stagingDirectory.deleteRecursively()
        }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pendingResult != null || otherPickerBusy()) {
            result.error("VAULT_PICKER_BUSY", "A file picker is already open", null)
            return
        }
        pendingResult = result
        activity.startActivityForResult(
            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
            },
            requestCode
        )
    }

    @SuppressLint("WrongConstant")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != this.requestCode) return false
        val pending = pendingResult ?: return true
        pendingResult = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            prepareSession(pending, emptyList())
            return true
        }
        try {
            val grantFlags = data.flags and
                (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            activity.contentResolver.takePersistableUriPermission(treeUri, grantFlags)
            val selectedInbox = resolveDocumentVaultInbox(treeUri)
                ?: error("The selected folder has no YoursVault/inbox directory")
            prepareSession(
                pending,
                listDocumentVaultInboxFiles(selectedInbox.inbox),
                documentTreeUri = selectedInbox.treeUri
            )
        } catch (error: Exception) {
            pending.error("VAULT_PICKER_FAILED", error.message, null)
        }
        return true
    }

    private fun prepareSession(
        result: MethodChannel.Result,
        sources: List<Pair<String, Uri>>,
        documentTreeUri: Uri? = null
    ) {
        val token = UUID.randomUUID().toString()
        val stagingDirectory = File(activity.cacheDir, "YoursVaultImports/$token")
        val stagingInbox = File(stagingDirectory, "inbox")
        check(stagingInbox.mkdirs() || stagingInbox.isDirectory) {
            "Unable to create Vault import staging directory"
        }
        val files = linkedMapOf<String, Uri>()
        try {
            sources.forEach { (name, source) ->
                activity.contentResolver.openInputStream(source)?.use { input ->
                    FileOutputStream(File(stagingInbox, name)).use { output ->
                        input.copyTo(output)
                    }
                } ?: error("Unable to read $name")
                files[name] = source
            }
            sessions[token] = VaultInboxSession(stagingDirectory, files, documentTreeUri)
            result.success(
                mapOf(
                    "token" to token,
                    "stagingPath" to stagingDirectory.path,
                    "scannedSources" to listOf("Documents/有思/YoursVault"),
                    "unavailableSources" to emptyList<String>(),
                    "conflictFiles" to emptyList<String>()
                )
            )
        } catch (error: Exception) {
            stagingDirectory.deleteRecursively()
            throw error
        }
    }

    private fun archiveDocumentFiles(
        documentTreeUri: Uri,
        session: VaultInboxSession,
        importedFiles: List<String>,
        failures: MutableList<String>
    ) {
        val resolver = activity.contentResolver
        val inbox = resolveDocumentVaultInbox(documentTreeUri)?.inbox
            ?: error("Unable to access the selected Vault inbox")
        val imported = inbox.findFile("imported") ?: inbox.createDirectory("imported")
            ?: error("Unable to create inbox/imported")
        importedFiles.forEach { name ->
            val sourceUri = session.files[name] ?: return@forEach
            try {
                val source = DocumentFile.fromSingleUri(activity, sourceUri)
                    ?: error("Unable to access $name")
                val destinationName = uniqueArchiveName(imported, name)
                val moved = DocumentsContract.moveDocument(
                    resolver,
                    sourceUri,
                    inbox.uri,
                    imported.uri
                )
                if (moved == null) {
                    val copy = imported.createFile("application/json", destinationName)
                        ?: error("Unable to archive $name")
                    resolver.openInputStream(sourceUri)?.use { input ->
                        resolver.openOutputStream(copy.uri)?.use { output -> input.copyTo(output) }
                            ?: error("Unable to archive $name")
                    } ?: error("Unable to read $name")
                    check(source.delete()) { "Unable to remove $name after archiving" }
                } else if (destinationName != name) {
                    DocumentsContract.renameDocument(resolver, moved, destinationName)
                }
            } catch (_: Exception) {
                failures += name
            }
        }
    }

    private fun findPersistedDocumentVaultInbox(): DocumentVaultInbox? {
        return activity.contentResolver.persistedUriPermissions.asSequence()
            .filter { it.isReadPermission && it.isWritePermission }
            .sortedByDescending { it.uri.toString().length }
            .mapNotNull { resolveDocumentVaultInbox(it.uri) }
            .firstOrNull()
    }

    private fun resolveDocumentVaultInbox(treeUri: Uri): DocumentVaultInbox? {
        val root = DocumentFile.fromTreeUri(activity, treeUri)?.takeIf { it.isDirectory }
            ?: return null
        val inbox = when {
            root.name.equals("inbox", ignoreCase = true) -> root
            root.name.equals("YoursVault", ignoreCase = true) ->
                root.findFile("inbox")?.takeIf { it.isDirectory }
            root.name == publicRoot -> root.findFile("YoursVault")
                ?.takeIf { it.isDirectory }
                ?.findFile("inbox")
                ?.takeIf { it.isDirectory }
            else -> null
        } ?: return null
        return DocumentVaultInbox(treeUri, inbox)
    }

    private fun listDocumentVaultInboxFiles(inbox: DocumentFile): List<Pair<String, Uri>> {
        return inbox.listFiles()
            .filter { it.isFile && VaultInboxPolicy.isImportFile(it.name) }
            .sortedBy { it.name }
            .mapNotNull { document -> document.name?.let { it to document.uri } }
    }

    private fun uniqueArchiveName(directory: DocumentFile, name: String): String {
        val existingNames = directory.listFiles().mapNotNull { it.name }.toSet()
        return VaultInboxPolicy.uniqueArchiveName(existingNames, name, System.currentTimeMillis())
    }

    private fun findPublicVaultInboxFiles(relativePath: String): List<Pair<String, Uri>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val inbox = File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS),
                "$publicRoot/YoursVault/inbox"
            )
            return inbox.listFiles()
                ?.filter { it.isFile && VaultInboxPolicy.isImportFile(it.name) }
                ?.sortedBy { it.name }
                ?.map { it.name to Uri.fromFile(it) }
                ?: emptyList()
        }
        val collection = MediaStore.Files.getContentUri("external")
        val projection = arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DISPLAY_NAME)
        val selection = "${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val args = arrayOf("$relativePath/")
        val files = mutableListOf<Pair<String, Uri>>()
        activity.contentResolver.query(
            collection,
            projection,
            selection,
            args,
            "${MediaStore.MediaColumns.DISPLAY_NAME} ASC"
        )?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            while (cursor.moveToNext()) {
                val name = cursor.getString(nameColumn) ?: continue
                if (!VaultInboxPolicy.isImportFile(name)) continue
                files += name to Uri.withAppendedPath(
                    collection,
                    cursor.getLong(idColumn).toString()
                )
            }
        }
        return files
    }

    private fun archivePublicFile(name: String, sourceUri: Uri, stagedFile: File) {
        check(stagedFile.exists()) { "Missing staged Vault file: $name" }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val source = File(sourceUri.path ?: error("Invalid source path"))
            val imported = File(source.parentFile, "imported")
            check(imported.exists() || imported.mkdirs()) { "Unable to create inbox/imported" }
            var destination = File(imported, name)
            if (destination.exists()) destination = File(imported, "${System.currentTimeMillis()}-$name")
            check(source.renameTo(destination)) { "Unable to archive $name" }
            return
        }
        val importedPath =
            "${Environment.DIRECTORY_DOCUMENTS}/$publicRoot/YoursVault/inbox/imported"
        val destinationName = if (documents.findPublicFileUri(importedPath, name) == null) {
            name
        } else {
            "${System.currentTimeMillis()}-$name"
        }
        documents.writePublicFile(stagedFile, importedPath, destinationName, "application/json")
        check(activity.contentResolver.delete(sourceUri, null, null) != 0) {
            "Unable to remove $name after archiving"
        }
    }
}
