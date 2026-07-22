package com.ly.yours

internal object VaultInboxPolicy {
    fun isImportFile(name: String?): Boolean {
        return name?.endsWith(".plan.json", ignoreCase = true) == true ||
            name?.endsWith(".exercise.json", ignoreCase = true) == true
    }

    fun uniqueArchiveName(existingNames: Set<String>, name: String, timestamp: Long): String {
        return if (name in existingNames) "$timestamp-$name" else name
    }
}
