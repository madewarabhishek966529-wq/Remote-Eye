package com.example.remote_eye

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private const val CHANNEL = "com.example.remote_eye/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val service = RemoteControlAccessibilityService.instance

            when (call.method) {
                "isAccessibilityGranted" -> {
                    result.success(RemoteControlAccessibilityService.isServiceRunning())
                }

                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTING_ERROR", e.localizedMessage, null)
                    }
                }

                "injectTap" -> {
                    if (service == null) {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not active", null)
                        return@setMethodCallHandler
                    }
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val success = service.injectTap(x, y)
                    result.success(success)
                }

                "injectDoubleTap" -> {
                    if (service == null) {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not active", null)
                        return@setMethodCallHandler
                    }
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val success = service.injectDoubleTap(x, y)
                    result.success(success)
                }

                "injectLongPress" -> {
                    if (service == null) {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not active", null)
                        return@setMethodCallHandler
                    }
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val success = service.injectLongPress(x, y)
                    result.success(success)
                }

                "injectSwipe" -> {
                    if (service == null) {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not active", null)
                        return@setMethodCallHandler
                    }
                    val startX = call.argument<Double>("startX") ?: 0.0
                    val startY = call.argument<Double>("startY") ?: 0.0
                    val endX = call.argument<Double>("endX") ?: 0.0
                    val endY = call.argument<Double>("endY") ?: 0.0
                    val duration = (call.argument<Int>("durationMs") ?: 300).toLong()
                    val success = service.injectSwipe(startX, startY, endX, endY, duration)
                    result.success(success)
                }

                "triggerGlobalAction" -> {
                    if (service == null) {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility service is not active", null)
                        return@setMethodCallHandler
                    }
                    val action = call.argument<String>("action") ?: ""
                    val success = service.triggerGlobalAction(action)
                    result.success(success)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
