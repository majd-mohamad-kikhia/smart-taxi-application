package com.ma.smarttaxi

import androidx.core.content.FileProvider

/**
 * Hands files the app sends to other apps (e.g. a trip bill to WhatsApp).
 * Its own subclass so it never clashes with a plugin's FileProvider entry.
 */
class SharedFileProvider : FileProvider() {
    companion object {
        /** Under the cache dir; must match res/xml/shared_files.xml. */
        const val DIRECTORY = "shared"
    }
}
