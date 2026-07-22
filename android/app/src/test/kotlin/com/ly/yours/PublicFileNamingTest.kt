package com.ly.yours

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PublicFileNamingTest {
    @Test
    fun matchesExactAndMediaStoreCollisionNames() {
        assertTrue(PublicFileNaming.isLogicalMatch("manifest.json", "manifest.json"))
        assertTrue(PublicFileNaming.isLogicalMatch("manifest (2).json", "manifest.json"))
        assertFalse(PublicFileNaming.isLogicalMatch("manifest-copy.json", "manifest.json"))
        assertFalse(PublicFileNaming.isLogicalMatch("manifest (x).json", "manifest.json"))
    }
}
