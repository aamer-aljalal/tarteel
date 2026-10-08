package com.tarteel.app.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.lang.IllegalArgumentException

/**
 * ============================================================================
 * اسم الملف: AlarmBridge.kt
 * المسؤولية: إدارة وحفظ وجدولة التنبيهات والصلوات في نظام أندرويد والتواصل مع فلاتر.
 * سبب الإنشاء: تبسيط البنية ودمج عمليات الاتصال والجدولة والحفظ في ملف واحد لتجنب كثرة الملفات.
 * متى يستخدم: عند تهيئة التطبيق، وعند جدولة الصلوات أو إلغائها من فلاتر.
 * من يستدعيه: MainActivity.kt
 * الملفات التي يتواصل معها: MainActivity.kt, AlarmReceiver.kt, AlarmForegroundService.kt
 * ============================================================================
 */

/**
 * نوع المنبه المجدول لمنع الأخطاء الإملائية.
 */
enum class AlarmType {
    ADHAN,
    IQAMAH,
    AZKAR,
    REMINDER
}

/**
 * مصدر ملف الصوت المخصص للمنبه.
 */
enum class AudioSource {
    RAW_RESOURCE,
    ASSET,
    SYSTEM_DEFAULT,
    NONE
}

/**
 * كلاس البيانات الموحد لحمل تفاصيل المنبه.
 */
data class AlarmData(
    val id: String,                         // المعرف الفريد للتنبيه
    val type: AlarmType,                    // نوع التنبيه (أذان، أذكار...)
    val title: String,                      // العنوان المعروض باللغة الحالية
    val subtitle: String,                   // الوصف المعروض باللغة الحالية
    val audioFile: String,                  // اسم ملف الصوت في مجلد res/raw
    val audioSource: AudioSource,           // مصدر الصوت
    val scheduledTime: Long,                // وقت الرنين بالملي ثانية
    val vibrate: Boolean,                   // تفعيل الهزاز
    val fullScreen: Boolean,                // فتح واجهة كاملة فوق شاشة القفل
    val volume: Float,                      // مستوى الصوت (0.0 إلى 1.0)
    val loopAudio: Boolean,                 // تكرار الصوت تلقائياً
    val payload: String?                    // بيانات إضافية اختيارية
) {
    companion object {
        /**
         * دالة تحويل خريطة البيانات (Map) القادمة من فلاتر إلى كائن AlarmData.
         */
        fun fromMap(map: Map<String, Any?>): AlarmData {
            val typeStr = map["type"] as? String ?: "REMINDER"
            val audioSourceStr = map["audioSource"] as? String ?: "SYSTEM_DEFAULT"

            return AlarmData(
                id = map["id"] as? String ?: throw IllegalArgumentException("معرف المنبه لا يمكن أن يكون فارغاً"),
                type = AlarmType.valueOf(typeStr.uppercase()),
                title = map["title"] as? String ?: "",
                subtitle = map["subtitle"] as? String ?: "",
                audioFile = map["audioFile"] as? String ?: "",
                audioSource = AudioSource.valueOf(audioSourceStr.uppercase()),
                scheduledTime = (map["scheduledTime"] as? Number)?.toLong() ?: throw IllegalArgumentException("وقت المنبه لا يمكن أن يكون فارغاً"),
                vibrate = map["vibrate"] as? Boolean ?: true,
                fullScreen = map["fullScreen"] as? Boolean ?: true,
                volume = (map["volume"] as? Number)?.toFloat() ?: 1.0f,
                loopAudio = map["loopAudio"] as? Boolean ?: false,
                payload = map["payload"] as? String
            )
        }

        /**
         * دالة تحويل نص JSON المحفوظ إلى كائن AlarmData لاستعادته عند إعادة التشغيل.
         */
        fun fromJson(jsonStr: String): AlarmData {
            val json = JSONObject(jsonStr)
            return AlarmData(
                id = json.getString("id"),
                type = AlarmType.valueOf(json.getString("type")),
                title = json.getString("title"),
                subtitle = json.getString("subtitle"),
                audioFile = json.getString("audioFile"),
                audioSource = AudioSource.valueOf(json.getString("audioSource")),
                scheduledTime = json.getLong("scheduledTime"),
                vibrate = json.getBoolean("vibrate"),
                fullScreen = json.getBoolean("fullScreen"),
                volume = json.getDouble("volume").toFloat(),
                loopAudio = json.getBoolean("loopAudio"),
                payload = json.optString("payload", null)
            )
        }
    }

    /**
     * دالة تحويل كائن المنبه إلى نص JSON لسهولة حفظه في ذاكرة الهاتف.
     */
    fun toJsonString(): String {
        val json = JSONObject().apply {
            put("id", id)
            put("type", type.name)
            put("title", title)
            put("subtitle", subtitle)
            put("audioFile", audioFile)
            put("audioSource", audioSource.name)
            put("scheduledTime", scheduledTime)
            put("vibrate", vibrate)
            put("fullScreen", fullScreen)
            put("volume", volume.toDouble())
            put("loopAudio", loopAudio)
            put("payload", payload)
        }
        return json.toString()
    }
}

/**
 * الفئة البرمجية الرئيسية لإدارة جسر التواصل والجدولة والحفظ.
 */
class AlarmBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    private val sharedPrefs: SharedPreferences = context.getSharedPreferences("native_alarm_prefs", Context.MODE_PRIVATE)
    private val alarmManager: AlarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    companion object {
        private const val CHANNEL_NAME = "com.tarteel.app/alarm"

        /**
         * تهيئة قناة الاتصال وتسجيل مستمع الطلبات القادمة من فلاتر.
         */
        fun registerWith(binaryMessenger: io.flutter.plugin.common.BinaryMessenger, context: Context) {
            val channel = MethodChannel(binaryMessenger, CHANNEL_NAME)
            channel.setMethodCallHandler(AlarmBridge(context))
        }
    }

    /**
     * استقبال الأوامر من تطبيق فلاتر وتوجيهها للدالة المناسبة.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleAlarm" -> {
                val map = call.arguments as? Map<String, Any?>
                if (map != null) {
                    try {
                        val alarmData = AlarmData.fromMap(map)
                        val success = schedule(alarmData)
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("SCHEDULE_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "البيانات المرسلة فارغة", null)
                }
            }
            "cancelAlarm" -> {
                val id = call.arguments as? String
                if (id != null) {
                    val success = cancel(id)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENTS", "معرف المنبه غير موجود", null)
                }
            }
            "cancelAllAlarms" -> {
                val success = cancelAll()
                result.success(success)
            }
            "stopActiveAlarm" -> {
                try {
                    val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                        action = AlarmForegroundService.ACTION_STOP
                    }
                    context.startService(serviceIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("STOP_FAILED", e.message, null)
                }
            }
            "playTestAdhan" -> {
                val map = call.arguments as? Map<String, Any?>
                if (map != null) {
                    try {
                        val alarmData = AlarmData.fromMap(map)
                        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                            action = AlarmForegroundService.ACTION_START
                            putExtra("alarm_json", alarmData.toJsonString())
                        }
                        context.startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("PLAY_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "البيانات المرسلة فارغة", null)
                }
            }
            "updateTestVolume" -> {
                val volume = call.arguments as? Double ?: 1.0
                try {
                    val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                        action = AlarmForegroundService.ACTION_UPDATE_VOLUME
                        putExtra("volume", volume.toFloat())
                    }
                    context.startService(serviceIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UPDATE_FAILED", e.message, null)
                }
            }
            "updateTestVibration" -> {
                val vibrate = call.arguments as? Boolean ?: true
                try {
                    val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                        action = AlarmForegroundService.ACTION_UPDATE_VIBRATION
                        putExtra("vibrate", vibrate)
                    }
                    context.startService(serviceIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("UPDATE_FAILED", e.message, null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * جدولة المنبه وحفظ بياناته محلياً بطريقة فائقة الدقة تتخطى قيود السبات (Doze Mode).
     */
    private fun schedule(alarmData: AlarmData): Boolean {
        try {
            // 1. إعداد النية (Intent) التي ستُطلق عند رنين المنبه لتشغيل الـ AlarmReceiver
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                putExtra("alarm_id", alarmData.id)
            }

            // 2. تحويل النية إلى PendingIntent مع حمايتها برمجياً
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmData.id.hashCode(),
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 3. إعداد نية فتح الشاشة لمكون AlarmClockInfo
            val showIntent = Intent(context, AlarmActivity::class.java).apply {
                putExtra("alarm_id", alarmData.id)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val showPendingIntent = PendingIntent.getActivity(
                context,
                alarmData.id.hashCode() + 1,
                showIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // 4. الجدولة الفائقة الدقة باستخدام setAlarmClock (أقوى وأضمن آلية في أندرويد لتخطي السبات نهائياً)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val alarmClockInfo = AlarmManager.AlarmClockInfo(
                    alarmData.scheduledTime,
                    showPendingIntent
                )
                try {
                    alarmManager.setAlarmClock(alarmClockInfo, pendingIntent)
                    Log.d("AlarmBridge", "تم الجدولة بنجاح باستخدام setAlarmClock للمنبه: ${alarmData.id}")
                } catch (e: SecurityException) {
                    Log.w("AlarmBridge", "تنبيه: setAlarmClock رفضت الصلاحية، محاولة التمرير البديل: ${e.message}")
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            alarmData.scheduledTime,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            alarmData.scheduledTime,
                            pendingIntent
                        )
                    }
                }
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    alarmData.scheduledTime,
                    pendingIntent
                )
            }

            // 5. حفظ بيانات المنبه في ذاكرة الهاتف المشتركة SharedPreferences بصيغة JSON
            sharedPrefs.edit().apply {
                putString("alarm_${alarmData.id}", alarmData.toJsonString())
                apply()
            }

            return true
        } catch (e: Exception) {
            Log.e("AlarmBridge", "فشل جدولة المنبه: ${e.message}", e)
            return false
        }
    }

    /**
     * إلغاء منبه محدد من النظام والذاكرة المشتركة.
     */
    private fun cancel(id: String): Boolean {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id.hashCode(),
            intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )

        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }

        // حذف المنبه من الذاكرة
        sharedPrefs.edit().apply {
            remove("alarm_$id")
            apply()
        }

        return true
    }

    /**
     * إلغاء كافة المنبهات المجدولة ومسح الذاكرة.
     */
    private fun cancelAll(): Boolean {
        val keys = sharedPrefs.all.keys
        for (key in keys) {
            if (key.startsWith("alarm_")) {
                val id = key.substringAfter("alarm_")
                cancel(id)
            }
        }
        return true
    }
}
