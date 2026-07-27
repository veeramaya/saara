package com.realmaya.saara

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity is required by the Health Connect plugin (§10) for
// its permissions flow.
//
// §9 Share-to-Saara: another app (WhatsApp, Files, email) can share — or "open
// with" — a Saara ledger file straight into the app. We read the shared file's
// bytes here and hand the text to Flutter over a method channel; Flutter runs
// the normal ledger import. No third-party share-intent plugin is used: the
// only maintained one needs compileSdk 37, which our build pins away from (see
// android/app/build.gradle.kts), so the handful of lines it would save aren't
// worth reintroducing that conflict.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "saara/incoming_share"
    private var pendingSharedText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The intent that launched us (a cold start via Share / Open with).
        readSharedFrom(intent)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                // Flutter polls this on launch and on resume; returning the text
                // clears it so a file is delivered exactly once.
                "consumeSharedText" -> {
                    result.success(pendingSharedText)
                    pendingSharedText = null
                }
                else -> result.notImplemented()
            }
        }
    }

    // A share to a singleTop activity that's already running arrives here.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readSharedFrom(intent)
    }

    // Pull the text of a shared / opened ledger file out of [intent], if any.
    private fun readSharedFrom(intent: Intent?) {
        if (intent == null) return
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_SEND -> intent.getParcelableExtra(Intent.EXTRA_STREAM)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        }
        val text = when {
            uri != null -> readUri(uri)
            // A plain-text share carries the payload inline, not as a file.
            intent.action == Intent.ACTION_SEND ->
                intent.getStringExtra(Intent.EXTRA_TEXT)
            else -> null
        }
        if (!text.isNullOrBlank()) pendingSharedText = text
    }

    private fun readUri(uri: Uri): String? = try {
        contentResolver.openInputStream(uri)?.use { it.bufferedReader().readText() }
    } catch (e: Exception) {
        null
    }
}
