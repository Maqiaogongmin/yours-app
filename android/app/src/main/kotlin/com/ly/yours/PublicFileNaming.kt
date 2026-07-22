package com.ly.yours

internal object PublicFileNaming {
    fun isLogicalMatch(displayName: String, filename: String): Boolean {
        if (displayName == filename) return true
        val extensionStart = filename.lastIndexOf('.')
        val stem = if (extensionStart > 0) filename.substring(0, extensionStart) else filename
        val extension = if (extensionStart > 0) filename.substring(extensionStart) else ""
        return Regex(
            "^${Regex.escape(stem)} \\(\\d+\\)${Regex.escape(extension)}$"
        ).matches(displayName)
    }
}
