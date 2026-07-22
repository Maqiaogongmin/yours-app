package com.ly.yours

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class VaultInboxPolicyTest {
    @Test
    fun acceptsOnlySupportedVaultFiles() {
        assertTrue(VaultInboxPolicy.isImportFile("plan.plan.json"))
        assertTrue(VaultInboxPolicy.isImportFile("MOVE.EXERCISE.JSON"))
        assertFalse(VaultInboxPolicy.isImportFile("manifest.json"))
        assertFalse(VaultInboxPolicy.isImportFile(null))
    }

    @Test
    fun archiveNameChangesOnlyForARealCollision() {
        val existing = setOf("plan.plan.json")
        assertEquals(
            "123-plan.plan.json",
            VaultInboxPolicy.uniqueArchiveName(existing, "plan.plan.json", 123)
        )
        assertEquals(
            "move.exercise.json",
            VaultInboxPolicy.uniqueArchiveName(existing, "move.exercise.json", 123)
        )
    }
}
