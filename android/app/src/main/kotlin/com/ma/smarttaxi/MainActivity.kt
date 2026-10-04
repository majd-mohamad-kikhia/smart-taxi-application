package com.ma.smarttaxi

import android.content.ActivityNotFoundException
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart_taxi/whatsapp")
            .setMethodCallHandler { call, result ->
                if (call.method != "sendFile") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName")
                val phone = call.argument<String>("phone")
                if (bytes == null || fileName == null || phone == null) {
                    result.error("bad_args", "bytes, fileName and phone are required", null)
                    return@setMethodCallHandler
                }
                val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                result.success(sendToWhatsApp(bytes, fileName, mimeType, phone, call.argument("text")))
            }
    }

    /**
     * Opens the WhatsApp chat of [phone] (international digits) with the file
     * attached. False when neither WhatsApp nor WhatsApp Business is installed.
     */
    private fun sendToWhatsApp(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        phone: String,
        text: String?,
    ): Boolean {
        val dir = File(cacheDir, SharedFileProvider.DIRECTORY).apply { mkdirs() }
        val file = File(dir, File(fileName).name).apply { writeBytes(bytes) }
        val uri = FileProvider.getUriForFile(this, "$packageName.shared_files", file)
        for (whatsApp in listOf("com.whatsapp", "com.whatsapp.w4b")) {
            val intent = Intent(Intent.ACTION_SEND).apply {
                setPackage(whatsApp)
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                if (text != null) putExtra(Intent.EXTRA_TEXT, text)
                putExtra("jid", "$phone@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                startActivity(intent)
                return true
            } catch (_: ActivityNotFoundException) {
            }
        }
        return false
    }
}
