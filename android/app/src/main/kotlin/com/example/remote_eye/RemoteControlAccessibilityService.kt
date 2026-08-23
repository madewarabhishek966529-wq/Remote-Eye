package com.example.remote_eye

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class RemoteControlAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "RemoteControlAccService"
        var instance: RemoteControlAccessibilityService? = null
            private set

        fun isServiceRunning(): Boolean {
            return instance != null
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "RemoteControlAccessibilityService connected successfully")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not required for gesture injection, but required override
    }

    override fun onInterrupt() {
        Log.d(TAG, "RemoteControlAccessibilityService interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        if (instance == this) {
            instance = null
        }
        Log.d(TAG, "RemoteControlAccessibilityService destroyed")
    }

    fun injectTap(xPercent: Double, yPercent: Double): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val displayMetrics = resources.displayMetrics
        val targetX = (xPercent * displayMetrics.widthPixels).toFloat()
        val targetY = (yPercent * displayMetrics.heightPixels).toFloat()

        val path = Path().apply {
            moveTo(targetX, targetY)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, 50)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return dispatchGesture(gesture, null, null)
    }

    fun injectDoubleTap(xPercent: Double, yPercent: Double): Boolean {
        val firstResult = injectTap(xPercent, yPercent)
        Handler(Looper.getMainLooper()).postDelayed({
            injectTap(xPercent, yPercent)
        }, 120)
        return firstResult
    }

    fun injectLongPress(xPercent: Double, yPercent: Double): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val displayMetrics = resources.displayMetrics
        val targetX = (xPercent * displayMetrics.widthPixels).toFloat()
        val targetY = (yPercent * displayMetrics.heightPixels).toFloat()

        val path = Path().apply {
            moveTo(targetX, targetY)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, 600)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return dispatchGesture(gesture, null, null)
    }

    fun injectSwipe(
        startXPercent: Double,
        startYPercent: Double,
        endXPercent: Double,
        endYPercent: Double,
        durationMs: Long = 300
    ): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val displayMetrics = resources.displayMetrics
        val startX = (startXPercent * displayMetrics.widthPixels).toFloat()
        val startY = (startYPercent * displayMetrics.heightPixels).toFloat()
        val endX = (endXPercent * displayMetrics.widthPixels).toFloat()
        val endY = (endYPercent * displayMetrics.heightPixels).toFloat()

        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs.coerceAtLeast(100))
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        return dispatchGesture(gesture, null, null)
    }

    fun triggerGlobalAction(actionType: String): Boolean {
        val action = when (actionType.lowercase()) {
            "back" -> GLOBAL_ACTION_BACK
            "home" -> GLOBAL_ACTION_HOME
            "recents" -> GLOBAL_ACTION_RECENTS
            "notifications" -> GLOBAL_ACTION_NOTIFICATIONS
            else -> return false
        }
        return performGlobalAction(action)
    }
}
