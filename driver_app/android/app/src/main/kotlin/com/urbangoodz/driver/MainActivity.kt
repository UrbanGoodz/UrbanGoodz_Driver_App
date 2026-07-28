package com.urbangoodz.driver

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    /**
     * Lets the secure card-reveal screen turn on FLAG_SECURE while provider
     * card credentials are on screen. FLAG_SECURE blocks screenshots and
     * screen recording, and blanks the window in the recent-apps thumbnail —
     * so a backgrounded reveal does not leave a readable card in the task
     * switcher.
     *
     * Scoped to the reveal screen rather than set once for the whole app: the
     * rest of the driver experience needs screenshots to stay available for
     * proof-of-delivery and support tickets.
     */
    private val secureScreenChannel = "com.urbangoodz.driver/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            secureScreenChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
