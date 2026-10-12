package com.tarteel.app.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * ============================================================================
 * اسم الملف: AlarmReceiver.kt
 * المسؤولية: استقبال إشارة التنبيه من نظام أندرويد وتشغيل الخدمة الخلفية فوراً.
 * سبب الإنشاء: تلبية لمتطلبات نظام أندرويد الذي يفرض استقبال إشارات التوقيت عبر BroadcastReceiver.
 * متى يستخدم: عند حلول وقت المنبه/الصلاة المجدول بالثانية.
 * من يستدعيه: نظام تشغيل أندرويد (OS) عبر الـ AlarmManager.
 * الملفات التي يتواصل معها: AlarmBridge.kt (غير مباشر)، AlarmForegroundService.kt (مباشر)
 * ============================================================================
 */
class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
    }

    /**
     * الدالة الرئيسية التي يتم استدعاؤها تلقائياً من نظام أندرويد عند رنين المنبه.
     */
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "تم استقبال إشارة رنين المنبه بنجاح")

        // 1. استخراج معرف المنبه الفريد من النية القادمة
        val alarmId = intent.getStringExtra("alarm_id")
        if (alarmId == null) {
            Log.e(TAG, "فشل تشغيل المنبه: معرف المنبه (alarm_id) فارغ")
            return
        }

        Log.d(TAG, "بدء تشغيل منبه بمعرف: $alarmId")

        // إيقاظ المعالج وشاشة الهاتف فوراً (لتضيء الشاشة في الظلام والقفل)
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
        @Suppress("DEPRECATION")
        val wakeLock = powerManager?.newWakeLock(
            android.os.PowerManager.FULL_WAKE_LOCK or
                    android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP or
                    android.os.PowerManager.ON_AFTER_RELEASE,
            "Tarteel:AlarmScreenWakeLock"
        )
        try {
            wakeLock?.acquire(20 * 1000L) // إبقاء الشاشة مضاءة 20 ثانية لتظهر الواجهة
        } catch (e: Exception) {
            Log.w(TAG, "تعذر حجز WakeLock: ${e.message}")
        }

        // 2. إطلاق شاشة الأذان فوراً فوق قفل الشاشة مباشرة
        val activityIntent = Intent(context, AlarmActivity::class.java).apply {
            putExtra("alarm_id", alarmId)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        }
        try {
            context.startActivity(activityIntent)
            Log.d(TAG, "تم إرسال أمر فتح AlarmActivity من AlarmReceiver بنجاح")
        } catch (e: Exception) {
            Log.e(TAG, "تعذر فتح AlarmActivity من AlarmReceiver: ${e.message}")
        }

        // 3. إعداد النية لتشغيل الخدمة الخلفية المستمرة وتمرير معرف المنبه لها
        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtra("alarm_id", alarmId)
        }

        // 4. تشغيل الخدمة الخلفية بشكل آمن يعتمد على إصدار الأندرويد
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.d(TAG, "تم إرسال أمر تشغيل الخدمة الخلفية للمنبه بنجاح")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تشغيل الخدمة الخلفية للمنبه: ${e.message}")
        }
    }
}
