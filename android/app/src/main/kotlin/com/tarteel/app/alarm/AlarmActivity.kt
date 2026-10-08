package com.tarteel.app.alarm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RelativeLayout
import android.widget.TextView

/**
 * ============================================================================
 * اسم الملف: AlarmActivity.kt
 * المسؤولية: الشاشة الأصلية التي تظهر فوق شاشة قفل الهاتف لعرض تفاصيل الصلاة وأزرار التحكم.
 * سبب الإنشاء: المكون الأساسي لعرض واجهة المنبه التفاعلية بملء الشاشة عند قفل الهاتف بتصميم متناسق.
 * متى يستخدم: يتم فتحه تلقائياً بواسطة نظام التشغيل عند رنين المنبه/الأذان.
 * من يستدعيه: نظام تشغيل أندرويد عبر نية الشاشة الكاملة (FullScreenIntent).
 * الملفات التي يتواصل معها: AlarmForegroundService.kt (لإرسال الأوامر)، AlarmBridge.kt (لقراءة البيانات).
 * ============================================================================
 */
class AlarmActivity : Activity() {

    private var alarmId: String? = null
    private var alarmStoppedReceiver: android.content.BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 0. تسجيل مراقب توقف المنبه لإغلاق الشاشة تلقائياً
        registerAlarmStoppedReceiver()
        
        // 2. استخراج معرف المنبه القادم مع النية
        alarmId = intent.getStringExtra("alarm_id")
        Log.d("AlarmActivity", "تم بدء onCreate لمعرف منبه: $alarmId")

        // 1. إعداد شاشة الهاتف لإيقاظها وتخطي قفل الهاتف الأمني
        setupLockScreenFlags()

        // 3. جلب بيانات التنبيه من الذاكرة المشتركة SharedPreferences
        var alarmTitle = "حان الآن موعد الصلاة"
        var alarmSubtitle = "نداء للأذان"
        
        if (alarmId != null) {
            val sharedPrefs = getSharedPreferences("native_alarm_prefs", Context.MODE_PRIVATE)
            val jsonStr = sharedPrefs.getString("alarm_$alarmId", null)
            if (jsonStr != null) {
                try {
                    val alarmData = AlarmData.fromJson(jsonStr)
                    alarmTitle = alarmData.title
                    alarmSubtitle = alarmData.subtitle
                } catch (e: Exception) {
                    // في حال الفشل نبقي على القيم الافتراضية
                }
            }
        }

        // 4. بناء الواجهة الرسومية برمجياً بنسق داكن ملكي راقي يحاكي واجهة التطبيق الداخلية
        val rootLayout = RelativeLayout(this).apply {
            setBackgroundColor(Color.parseColor("#0B0F19"))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setPadding(dpToPx(24), dpToPx(32), dpToPx(24), dpToPx(32))
        }

        // أ. الحاوية العلوية للعناوين (Title & Subtitle)
        val headerLayout = LinearLayout(this).apply {
            id = View.generateViewId()
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val params = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                addRule(RelativeLayout.ALIGN_PARENT_TOP)
                topMargin = dpToPx(48)
            }
            layoutParams = params
        }
        
        val mainTitleView = TextView(this).apply {
            text = "حان الآن موعد الأذان"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 24f)
            setTextColor(Color.parseColor("#FFD700")) // لون ذهبي متألق للعنوان الرئيسي
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        headerLayout.addView(mainTitleView)

        val subTitleView = TextView(this).apply {
            text = "نداء لـ $alarmTitle\n$alarmSubtitle"
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTextColor(Color.parseColor("#B0BEC5")) // لون رمادي فاتح مريح للوصف
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(12)
            }
        }
        headerLayout.addView(subTitleView)
        rootLayout.addView(headerLayout)

        // ب. حاوية المسجد والتموجات المتحركة (Center Container)
        val centerContainer = FrameLayout(this).apply {
            id = View.generateViewId()
            val params = RelativeLayout.LayoutParams(
                dpToPx(280),
                dpToPx(280)
            ).apply {
                addRule(RelativeLayout.CENTER_IN_PARENT)
            }
            layoutParams = params
        }

        // إنشاء التموجات الجمالية الثلاثة حول المسجد
        val rippleShape = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setStroke(dpToPx(1.5f), Color.parseColor("#4DFFD700")) // إطار ذهبي شبه شفاف (30%)
        }

        val ripple1 = View(this).apply {
            background = rippleShape
            layoutParams = FrameLayout.LayoutParams(dpToPx(140), dpToPx(140)).apply {
                gravity = Gravity.CENTER
            }
        }
        val ripple2 = View(this).apply {
            background = rippleShape
            layoutParams = FrameLayout.LayoutParams(dpToPx(140), dpToPx(140)).apply {
                gravity = Gravity.CENTER
            }
        }
        val ripple3 = View(this).apply {
            background = rippleShape
            layoutParams = FrameLayout.LayoutParams(dpToPx(140), dpToPx(140)).apply {
                gravity = Gravity.CENTER
            }
        }
        centerContainer.addView(ripple1)
        centerContainer.addView(ripple2)
        centerContainer.addView(ripple3)

        // دائرة المسجد الوسطى
        val mosqueCircle = FrameLayout(this).apply {
            val circleBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#121929")) // لون داكن أفتح قليلاً من الخلفية العامة
                setStroke(dpToPx(2f), Color.parseColor("#FFD700")) // إطار ذهبي
            }
            background = circleBg
            layoutParams = FrameLayout.LayoutParams(dpToPx(140), dpToPx(140)).apply {
                gravity = Gravity.CENTER
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                elevation = dpToPx(12).toFloat()
            }
        }

        val mosqueIcon = ImageView(this).apply {
            val resId = resources.getIdentifier("ic_mosque", "drawable", packageName)
            if (resId != 0) {
                setImageResource(resId)
            } else {
                setImageResource(android.R.drawable.ic_lock_idle_alarm)
            }
            setColorFilter(Color.parseColor("#FFD700"))
            layoutParams = FrameLayout.LayoutParams(dpToPx(64), dpToPx(64)).apply {
                gravity = Gravity.CENTER
            }
        }
        mosqueCircle.addView(mosqueIcon)
        centerContainer.addView(mosqueCircle)
        rootLayout.addView(centerContainer)

        // ج. تشغيل تموجات الحركة الجمالية فوراً
        centerContainer.post {
            startRippleAnimation(ripple1, 0)
            startRippleAnimation(ripple2, 1000)
            startRippleAnimation(ripple3, 2000)
        }

        // د. حاوية الأزرار السفلية (كتم على اليسار وإيقاف على اليمين)
        val buttonsContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            val params = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
                bottomMargin = dpToPx(48)
            }
            layoutParams = params
        }

        // إعداد وتصميم الأزرار التفاعلية الدائرية
        var isMuted = false
        lateinit var muteButtonContainer: LinearLayout
        
        val toggleMuteClick = {
            isMuted = !isMuted
            Log.d("AlarmActivity", "تم الضغط على كتم الصوت. الحالة الجديدة للمكتوم: $isMuted")
            sendActionToService(AlarmForegroundService.ACTION_MUTE)
            
            val circle = muteButtonContainer.getChildAt(0) as FrameLayout
            val icon = circle.getChildAt(0) as ImageView
            val label = muteButtonContainer.getChildAt(1) as TextView
            
            if (isMuted) {
                val mutedColor = "#90A4AE"
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(adjustAlpha(mutedColor, 0.15f))
                    setStroke(dpToPx(1.5f), Color.parseColor(mutedColor))
                }
                circle.background = bg
                icon.setColorFilter(Color.parseColor(mutedColor))
                val resId = resources.getIdentifier("ic_volume_off", "drawable", packageName)
                if (resId != 0) icon.setImageResource(resId)
                label.text = "تشغيل الصوت"
                label.setTextColor(Color.parseColor(mutedColor))
            } else {
                val normalColor = "#FFD700"
                val bg = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(adjustAlpha(normalColor, 0.15f))
                    setStroke(dpToPx(1.5f), Color.parseColor(normalColor))
                }
                circle.background = bg
                icon.setColorFilter(Color.parseColor(normalColor))
                val resId = resources.getIdentifier("ic_volume_up", "drawable", packageName)
                if (resId != 0) icon.setImageResource(resId)
                label.text = "كتم الصوت"
                label.setTextColor(Color.parseColor("#B0BEC5"))
            }
        }

        muteButtonContainer = createControlButton("كتم الصوت", "ic_volume_up", "#FFD700") {
            toggleMuteClick()
        }

        val stopButtonContainer = createControlButton("إيقاف الأذان", "ic_stop", "#EF5350") {
            Log.d("AlarmActivity", "تم الضغط على زر إيقاف الأذان")
            sendActionToService(AlarmForegroundService.ACTION_STOP)
            finish()
        }

        buttonsContainer.addView(muteButtonContainer)
        
        // مسافة فارغة لتفريق الأزرار
        val space = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(48), 1)
        }
        buttonsContainer.addView(space)
        
        buttonsContainer.addView(stopButtonContainer)
        rootLayout.addView(buttonsContainer)

        setContentView(rootLayout)
    }

    /**
     * تشغيل الرسوم المتحركة للتموجات الدائرية المتكررة.
     */
    private fun startRippleAnimation(ripple: View, delay: Long) {
        ripple.scaleX = 1.0f
        ripple.scaleY = 1.0f
        ripple.alpha = 1.0f

        val scaleX = android.animation.ObjectAnimator.ofFloat(ripple, "scaleX", 1.0f, 2.2f)
        val scaleY = android.animation.ObjectAnimator.ofFloat(ripple, "scaleY", 1.0f, 2.2f)
        val alpha = android.animation.ObjectAnimator.ofFloat(ripple, "alpha", 1.0f, 0.0f)

        scaleX.repeatCount = android.animation.ValueAnimator.INFINITE
        scaleY.repeatCount = android.animation.ValueAnimator.INFINITE
        alpha.repeatCount = android.animation.ValueAnimator.INFINITE

        val animatorSet = android.animation.AnimatorSet().apply {
            playTogether(scaleX, scaleY, alpha)
            duration = 3000
            startDelay = delay
        }
        animatorSet.start()
    }

    /**
     * دالة مساعدة لإنشاء الأزرار التفاعلية الدائرية ذات التسمية السفلية.
     */
    private fun createControlButton(
        labelStr: String,
        iconResName: String,
        colorHex: String,
        onClick: () -> Unit
    ): LinearLayout {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                dpToPx(120),
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }

        val buttonCircle = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(adjustAlpha(colorHex, 0.15f))
                setStroke(dpToPx(1.5f), Color.parseColor(colorHex))
            }
            background = bg
            layoutParams = LinearLayout.LayoutParams(dpToPx(70), dpToPx(70)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
            isClickable = true
            isFocusable = true
            setOnClickListener { onClick() }
        }

        val iconView = ImageView(this).apply {
            val resId = resources.getIdentifier(iconResName, "drawable", packageName)
            if (resId != 0) {
                setImageResource(resId)
            } else {
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            }
            setColorFilter(Color.parseColor(colorHex))
            layoutParams = FrameLayout.LayoutParams(dpToPx(30), dpToPx(30)).apply {
                gravity = Gravity.CENTER
            }
        }
        buttonCircle.addView(iconView)
        container.addView(buttonCircle)

        val labelView = TextView(this).apply {
            text = labelStr
            setTextColor(Color.parseColor("#B0BEC5"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            gravity = Gravity.CENTER
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(10)
            }
        }
        container.addView(labelView)

        return container
    }

    private fun adjustAlpha(colorHex: String, factor: Float): Int {
        val color = Color.parseColor(colorHex)
        val alpha = Math.round(Color.alpha(color) * factor)
        val red = Color.red(color)
        val green = Color.green(color)
        val blue = Color.blue(color)
        return Color.argb(alpha, red, green, blue)
    }

    private fun setupLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        // إضافة الأعلام (Flags) بشكل إجباري لجميع أنظمة سامسونج (One UI) لضمان إضاءة وعزلة شاشة القفل بنسبة 100%
        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON
        )
    }

    private fun sendActionToService(action: String) {
        val serviceIntent = Intent(this, AlarmForegroundService::class.java).apply {
            this.action = action
            putExtra("alarm_id", alarmId)
        }
        startService(serviceIntent)
    }

    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).toInt()
    }

    private fun dpToPx(dp: Float): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp,
            resources.displayMetrics
        ).toInt()
    }

    override fun dispatchKeyEvent(event: android.view.KeyEvent): Boolean {
        if (event.action == android.view.KeyEvent.ACTION_DOWN) {
            val keyCode = event.keyCode
            if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP ||
                keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN ||
                keyCode == android.view.KeyEvent.KEYCODE_VOLUME_MUTE ||
                keyCode == android.view.KeyEvent.KEYCODE_POWER ||
                keyCode == android.view.KeyEvent.KEYCODE_CAMERA ||
                keyCode == android.view.KeyEvent.KEYCODE_HEADSETHOOK) {
                Log.d("AlarmActivity", "تم رصد ضغطة زر الجانب/الصوت ($keyCode)، جاري إيقاف الأذان وإغلاق الواجهة...")
                sendActionToService(AlarmForegroundService.ACTION_STOP)
                finish()
                return true
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onKeyDown(keyCode: Int, event: android.view.KeyEvent?): Boolean {
        when (keyCode) {
            android.view.KeyEvent.KEYCODE_VOLUME_UP,
            android.view.KeyEvent.KEYCODE_VOLUME_DOWN,
            android.view.KeyEvent.KEYCODE_VOLUME_MUTE,
            android.view.KeyEvent.KEYCODE_POWER,
            android.view.KeyEvent.KEYCODE_CAMERA,
            android.view.KeyEvent.KEYCODE_HEADSETHOOK -> {
                Log.d("AlarmActivity", "تم رصد ضغطة زر في onKeyDown ($keyCode)، جاري إيقاف الأذان فوراً...")
                sendActionToService(AlarmForegroundService.ACTION_STOP)
                finish()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        Log.d("AlarmActivity", "المستخدم يغادر واجهة الرنين (onUserLeaveHint)، إيقاف الأذان فوراً...")
        sendActionToService(AlarmForegroundService.ACTION_STOP)
        finish()
    }

    override fun onStop() {
        super.onStop()
        Log.d("AlarmActivity", "onStop Activity state changed")
    }

    override fun onBackPressed() {
        // لا نفعل شيئاً؛ إجباري التفاعل مع الأزرار للسلامة
    }

    private fun registerAlarmStoppedReceiver() {
        try {
            alarmStoppedReceiver = object : android.content.BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    Log.d("AlarmActivity", "تم استقبال إشعار توقف الأذان تلقائياً من الخدمة، جاري إغلاق الشاشة...")
                    finish()
                }
            }
            val filter = android.content.IntentFilter(AlarmForegroundService.ACTION_ALARM_STOPPED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                try {
                    registerReceiver(alarmStoppedReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                } catch (e: Exception) {
                    registerReceiver(alarmStoppedReceiver, filter, Context.RECEIVER_EXPORTED)
                }
            } else {
                registerReceiver(alarmStoppedReceiver, filter)
            }
        } catch (e: Exception) {
            Log.e("AlarmActivity", "فشل تسجيل مراقب توقف الأذان: ${e.message}")
        }
    }

    private fun unregisterAlarmStoppedReceiver() {
        try {
            alarmStoppedReceiver?.let {
                unregisterReceiver(it)
                alarmStoppedReceiver = null
            }
        } catch (e: Exception) {
            Log.e("AlarmActivity", "خطأ أثناء إلغاء تسجيل مراقب توقف الأذان: ${e.message}")
        }
    }

    override fun onDestroy() {
        unregisterAlarmStoppedReceiver()
        super.onDestroy()
    }
}
