package com.ma.smarttaxi

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smart_taxi/google_api")
            .setMethodCallHandler { call, result ->
                if (call.method == "identity") {
                    result.success(googleApiIdentity())
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * What Google's web APIs (Routes) check on a key restricted to Android
     * apps, so the Dart side can send it as headers: the maps key from the
     * manifest (the very key the map uses), the package name, and the SHA-1
     * of the certificate this build is signed with — the debug, upload or
     * Play signing key, depending on how the app was built and installed.
     */
    private fun googleApiIdentity(): Map<String, String?> = mapOf(
        "apiKey" to manifestMapsKey(),
        "packageName" to packageName,
        "certSha1" to signingCertSha1(),
    )

    @Suppress("DEPRECATION")
    private fun manifestMapsKey(): String? {
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getApplicationInfo(
                packageName,
                PackageManager.ApplicationInfoFlags.of(PackageManager.GET_META_DATA.toLong()),
            )
        } else {
            packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
        }
        return info.metaData?.getString("com.google.android.geo.API_KEY")
    }

    @Suppress("DEPRECATION")
    private fun signingCertSha1(): String? {
        val signature = (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager
                .getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                .signingInfo
                ?.apkContentsSigners
                ?.firstOrNull()
        } else {
            packageManager
                .getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                .signatures
                ?.firstOrNull()
        }) ?: return null
        return MessageDigest.getInstance("SHA-1")
            .digest(signature.toByteArray())
            .joinToString("") { "%02X".format(it) }
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
