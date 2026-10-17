package com.ma.smarttaxi

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import kotlin.math.abs

/**
 * The driver's floating bubble: the round app icon in a green ring, drawn over
 * other apps. Drag it anywhere; it snaps to the nearest side of the screen.
 * A tap brings the app back to the front and removes the bubble.
 *
 * It is a plain overlay window of this process (no service, no second Flutter
 * engine), so touches are handled here and nothing has to travel back to Dart.
 * A process-wide object, because the activity may be recreated while the
 * bubble is up.
 */
object FloatingBubble {
    private const val PREFS = "floating_bubble"
    private const val KEY_SIDE_RIGHT = "side_right"
    private const val KEY_Y_FRACTION = "y_fraction"

    private const val SIZE_DP = 76
    private const val RING_DP = 3
    private const val SNAP_MS = 180L
    private const val BRAND_GREEN = 0xFF1F9D55.toInt()

    private lateinit var context: Context
    private var view: View? = null

    /** Called once from the activity; the application context outlives it. */
    fun init(appContext: Context) {
        context = appContext.applicationContext
    }

    fun canDraw(): Boolean = Settings.canDrawOverlays(context)

    val isShowing: Boolean get() = view != null

    /** False when the permission is missing or the window could not be added. */
    fun show(): Boolean {
        if (view != null) return true
        if (!canDraw()) return false
        val windowManager = windowManager()
        val size = dp(SIZE_DP)
        val screen = context.resources.displayMetrics
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        val params = WindowManager.LayoutParams(
            size,
            size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = if (prefs.getBoolean(KEY_SIDE_RIGHT, true)) screen.widthPixels - size else 0
            y = (prefs.getFloat(KEY_Y_FRACTION, 0.35f) * screen.heightPixels).toInt()
                .coerceIn(0, screen.heightPixels - size)
        }

        val bubble = buildView(size)
        bubble.setOnTouchListener(DragListener(windowManager, bubble, params, prefs))
        return try {
            windowManager.addView(bubble, params)
            view = bubble
            true
        } catch (e: RuntimeException) {
            false
        }
    }

    fun hide() {
        val bubble = view ?: return
        view = null
        try {
            windowManager().removeView(bubble)
        } catch (_: RuntimeException) {
            // Already gone (the system removed it with the app).
        }
    }

    /** Puts the running app back in front of whatever is on screen. */
    fun bringAppToFront(): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return false
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
        context.startActivity(intent)
        return true
    }

    private fun windowManager() = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager

    private fun dp(value: Int) = (value * context.resources.displayMetrics.density).toInt()

    /** A green ring around the round app icon. */
    private fun buildView(size: Int): View {
        val ring = dp(RING_DP)
        val icon = ImageView(context).apply {
            setImageDrawable(context.packageManager.getApplicationIcon(context.packageName))
            scaleType = ImageView.ScaleType.CENTER_CROP
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setOval(0, 0, view.width, view.height)
                }
            }
            clipToOutline = true
        }
        return FrameLayout(context).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(BRAND_GREEN)
            }
            elevation = dp(4).toFloat()
            setPadding(ring, ring, ring, ring)
            addView(icon, FrameLayout.LayoutParams(size - 2 * ring, size - 2 * ring))
        }
    }

    /** Drags the bubble, snaps it to a side on release, and turns a short touch into a tap. */
    private class DragListener(
        private val windowManager: WindowManager,
        private val bubble: View,
        private val params: WindowManager.LayoutParams,
        private val prefs: android.content.SharedPreferences,
    ) : View.OnTouchListener {
        private val slop = ViewConfiguration.get(bubble.context).scaledTouchSlop
        private var downRawX = 0f
        private var downRawY = 0f
        private var startX = 0
        private var startY = 0
        private var dragging = false

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(v: View, event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downRawX = event.rawX
                    downRawY = event.rawY
                    startX = params.x
                    startY = params.y
                    dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downRawX
                    val dy = event.rawY - downRawY
                    if (!dragging && abs(dx) < slop && abs(dy) < slop) return true
                    dragging = true
                    val screen = bubble.context.resources.displayMetrics
                    params.x = (startX + dx).toInt().coerceIn(0, screen.widthPixels - params.width)
                    params.y = (startY + dy).toInt().coerceIn(0, screen.heightPixels - params.height)
                    update()
                }
                MotionEvent.ACTION_UP -> {
                    if (dragging) snapToSide() else onTap()
                }
            }
            return true
        }

        private fun update() {
            try {
                windowManager.updateViewLayout(bubble, params)
            } catch (_: RuntimeException) {
                // Removed while being dragged.
            }
        }

        private fun onTap() {
            hide()
            bringAppToFront()
        }

        private fun snapToSide() {
            val screen = bubble.context.resources.displayMetrics
            val toRight = params.x + params.width / 2 > screen.widthPixels / 2
            val targetX = if (toRight) screen.widthPixels - params.width else 0
            prefs.edit()
                .putBoolean(KEY_SIDE_RIGHT, toRight)
                .putFloat(KEY_Y_FRACTION, params.y.toFloat() / screen.heightPixels)
                .apply()
            ValueAnimator.ofInt(params.x, targetX).apply {
                duration = SNAP_MS
                addUpdateListener {
                    params.x = it.animatedValue as Int
                    update()
                }
                start()
            }
        }
    }
}
