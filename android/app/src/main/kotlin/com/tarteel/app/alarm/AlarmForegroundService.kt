package com.tarteel.app.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * ============================================================================
 * اسم الملف: AlarmForegroundService.kt
 * المسؤولية: تشغيل صوت الأذان/المنبه بالخلفية وإظهار إشعار ذو أولوية قصوى وفتح شاشة الرنين.
 * سبب الإنشاء: المكون الوحيد القادر على إبقاء عملية التشغيل نشطة بالخلفية وتخطي قيود السبات.
 * متى يستخدم: عند رنين المنبه وبدء تشغيل الخدمة الخلفية.
 * من يستدعيه: AlarmReceiver.kt
 * الملفات التي يتواصل معها: AlarmReceiver.kt, AlarmActivity.kt, AlarmBridge.kt (لقراءة البيانات)
 * ============================================================================
 */
class AlarmForegroundService : Service() {

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var currentAlarmData: AlarmData? = null
    private var isMuted = false
    private var originalAlarmVolume: Int? = null
    private var powerButtonReceiver: android.content.BroadcastReceiver? = null
    private var alarmStartTime: Long = 0
    private var audioFocusRequest: AudioFocusRequest? = null
    private var mediaSession: MediaSession? = null

    companion object {
        private const val TAG = "AlarmService"
        private const val NOTIFICATION_ID = 9999
        private const val CHANNEL_ID = "adhan_alarm_channel_v1"

        // مفاتيح الأوامر الخاصة بالتحكم بالخدمة
        const val ACTION_START = "com.tarteel.app.alarm.ACTION_START"
        const val ACTION_STOP = "com.tarteel.app.alarm.ACTION_STOP"
        const val ACTION_MUTE = "com.tarteel.app.alarm.ACTION_MUTE"
        const val ACTION_UPDATE_VOLUME = "com.tarteel.app.alarm.ACTION_UPDATE_VOLUME"
        const val ACTION_UPDATE_VIBRATION = "com.tarteel.app.alarm.ACTION_UPDATE_VIBRATION"
        const val ACTION_ALARM_STOPPED = "com.tarteel.app.alarm.ACTION_ALARM_STOPPED"
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // هذه الخدمة لا تدعم الربط المباشر بالأنشطة (Bound Service)
    }

    /**
     * الدالة الرئيسية لاستقبال الأوامر والتحكم بالخدمة.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        val alarmId = intent?.getStringExtra("alarm_id")
        val alarmJson = intent?.getStringExtra("alarm_json")

        Log.d(TAG, "تم استدعاء الخدمة الخلفية بالأمر: $action لمعرف منبه: $alarmId أو نص JSON: $alarmJson")

        // 1. معالجة أوامر التحكم المباشرة (إيقاف، كتم، أو تحديث فوري)
        if (action == ACTION_STOP) {
            stopAlarm()
            return START_NOT_STICKY
        }
        if (action == ACTION_MUTE) {
            muteAlarm()
            return START_STICKY
        }
        if (action == ACTION_UPDATE_VOLUME) {
            val volume = intent?.getFloatExtra("volume", 1.0f) ?: 1.0f
            updateVolume(volume)
            return START_STICKY
        }
        if (action == ACTION_UPDATE_VIBRATION) {
            val vibrate = intent?.getBooleanExtra("vibrate", true) ?: true
            updateVibration(vibrate)
            return START_STICKY
        }

        // 2. التحقق من صحة المعرف وبدء رنين منبه جديد أو أذان تجريبي
        if (alarmJson != null) {
            try {
                val alarmData = AlarmData.fromJson(alarmJson)
                currentAlarmData = alarmData
                isMuted = false // تصفير كتم الصوت عند بدء منبه جديد
                startAlarm(alarmData)
            } catch (e: Exception) {
                Log.e(TAG, "فشل فك بيانات المنبه التجريبي: ${e.message}")
                stopSelf()
            }
        } else if (alarmId != null) {
            // جلب تفاصيل المنبه من ذاكرة الهاتف
            val sharedPrefs = getSharedPreferences("native_alarm_prefs", Context.MODE_PRIVATE)
            val jsonStr = sharedPrefs.getString("alarm_$alarmId", null)
            
            if (jsonStr != null) {
                try {
                    val alarmData = AlarmData.fromJson(jsonStr)
                    currentAlarmData = alarmData
                    isMuted = false // تصفير كتم الصوت عند بدء منبه جديد
                    startAlarm(alarmData)
                } catch (e: Exception) {
                    Log.e(TAG, "فشل فك بيانات المنبه: ${e.message}")
                    stopSelf()
                }
            } else {
                Log.e(TAG, "لم يتم العثور على منبه بالمعرف: $alarmId في الذاكرة")
                stopSelf()
            }
        } else {
            // إذا بدأت الخدمة بدون معرف وبدون أمر، نقوم بإيقافها فوراً
            stopSelf()
        }

        return START_STICKY
    }

    private fun startAlarm(alarmData: AlarmData) {
        currentAlarmData = alarmData
        Log.d(TAG, "بدء رنين المنبه: ${alarmData.title}")

        // تفعيل الخاصية الافتراضية المباشرة بالنظام (AudioFocus & MediaSession) لصيد أزرار الهاردوير وطاقة الهاتف تلقائياً
        setupNativeAudioSystem()

        // تفعيل مراقبة أزرار الطاقة والصوت بشكل إجباري ومطلق عند بدء أي تنبيه أو اختبار
        registerPowerButtonReceiver()

        // نقوم أولاً بإيقاف وتفريغ أي مشغل أو هزاز نشط لتفادي تداخل الأصوات وتراكمها
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            // تجاهل الخطأ
        }
        try {
            vibrator?.cancel()
            vibrator = null
        } catch (e: Exception) {
            // تجاهل الخطأ
        }

        // 1. إعداد الإشعار وتفعيل الخدمة كخدمة أمامية فقط للمنبهات غير التجريبية
        val isTest = alarmData.id == "adhan_test_preview"
        if (!isTest) {
            // إنشاء قناة الإشعارات (مهم جداً لأندرويد 8+)
            createNotificationChannel()

            // إعداد النيات (Intents) لأزرار الإيقاف والكتم في الإشعار
            val stopIntent = Intent(this, AlarmForegroundService::class.java).apply {
                action = ACTION_STOP
            }
            val stopPendingIntent = PendingIntent.getService(
                this,
                alarmData.id.hashCode() + 1,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val muteIntent = Intent(this, AlarmForegroundService::class.java).apply {
                action = ACTION_MUTE
            }
            val mutePendingIntent = PendingIntent.getService(
                this,
                alarmData.id.hashCode() + 2,
                muteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // إعداد النية لفتح واجهة المنبه الكاملة AlarmActivity فوق قفل الشاشة
            val fullScreenIntent = Intent(this, AlarmActivity::class.java).apply {
                putExtra("alarm_id", alarmData.id)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val fullScreenPendingIntent = PendingIntent.getActivity(
                this,
                alarmData.id.hashCode(),
                fullScreenIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // بناء الإشعار ذو الأولوية القصوى مع أزرار تفاعلية ونية الشاشة الكاملة
            val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_lock_idle_alarm) // أيقونة منبه افتراضية آمنة
                .setContentTitle(alarmData.title)
                .setContentText(alarmData.subtitle)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setFullScreenIntent(fullScreenPendingIntent, true) // تفعيل الظهور بملء الشاشة فوق القفل
                .setOngoing(true) // منع المستخدم من مسح الإشعار يدوياً أثناء الرنين
                .setAutoCancel(false)
                .setContentIntent(fullScreenPendingIntent) // فتح الواجهة عند الضغط على الإشعار
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "إيقاف", stopPendingIntent)
                .addAction(android.R.drawable.ic_lock_silent_mode, "كتم", mutePendingIntent)
                .build()

            // إعلان تشغيل الخدمة بالخلفية فوراً لحمايتها من القتل
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }

            // إطلاق شاشة الأذان مباشرة من داخل الخدمة الأمامية لضمان ظهورها بملء الشاشة فوق قفل هواتف سامسونج (Android 14)
            try {
                startActivity(fullScreenIntent)
                Log.d(TAG, "تم إرسال أمر فتح AlarmActivity مباشرة من الخدمة الأمامية فوق قفل الشاشة")
            } catch (e: Exception) {
                Log.e(TAG, "تعذر إطلاق AlarmActivity مباشرة: ${e.message}")
            }
        }

        // 6. تشغيل الهزاز إذا كان مفعلاً
        if (alarmData.vibrate) {
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 1000, 1000), 0))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(longArrayOf(0, 1000, 1000), 0)
            }
        }

        // 7. ضبط مستوى صوت المنبه في النظام وتحديد خصائص الصوت
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        try {
            originalAlarmVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            // حساب مستوى الصوت المطلوب لتيار المنبه (STREAM_ALARM)
            val targetVolume = (alarmData.volume * maxVolume).toInt()
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, targetVolume, 0)
            Log.d(TAG, "تم ضبط مستوى صوت المنبه بالنظام مؤقتاً إلى: $targetVolume من أصل $maxVolume (السابق: $originalAlarmVolume)")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تعيين مستوى صوت المنبه بالنظام: ${e.message}")
        }

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        // 8. تشغيل ملف الصوت المخصص باستخدام MediaPlayer مع ثلاث طبقات احتياطية لضمان عمل الصوت في أنظمة سامسونج (Android 14+)
        try {
            // تنظيف اسم الملف من أي امتداد لضمان التوافق الكامل مع R.raw
            val cleanResourceName = alarmData.audioFile.removeSuffix(".m4a").removeSuffix(".mp3").removeSuffix(".wav").trim()
            val resourceId = resources.getIdentifier(cleanResourceName, "raw", packageName)
            
            val player = MediaPlayer()
            player.setAudioAttributes(audioAttributes)
            
            var sourceLoaded = false
            
            // المحاولة الأولى: عبر openRawResourceFd
            if (resourceId != 0 && !sourceLoaded) {
                try {
                    val afd = resources.openRawResourceFd(resourceId)
                    if (afd != null) {
                        player.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                        afd.close()
                        sourceLoaded = true
                        Log.d(TAG, "تم تحميل صوت الأذان $cleanResourceName بنجاح عبر openRawResourceFd")
                    }
                } catch (ex: Exception) {
                    Log.e(TAG, "المحاولة الأولى (openRawResourceFd) لم تفلح، جاري الانتقال للمحاولة الثانية: ${ex.message}")
                }
            }
            
            // المحاولة الثانية: عبر معرف الـ URI القياسي لموارد الأندرويد (تتفادى ضغط الملفات في التصدير)
            if (resourceId != 0 && !sourceLoaded) {
                try {
                    val resourceUri = android.net.Uri.parse("android.resource://$packageName/$resourceId")
                    player.setDataSource(this, resourceUri)
                    sourceLoaded = true
                    Log.d(TAG, "تم تحميل صوت الأذان بنجاح عبر Android Resource URI لهواتف سامسونج")
                } catch (ex: Exception) {
                    Log.e(TAG, "المحاولة الثانية (Resource URI) لم تفلح، جاري الانتقال للمحاولة الثالثة: ${ex.message}")
                }
            }
            
            // المحاولة الثالثة: القراءة مباشرة من مسار أصول فلاتر (Flutter Assets) كطبقة أمان إضافية
            if (!sourceLoaded) {
                try {
                    val assetFd = assets.openFd("flutter_assets/assets/audio/adhan/$cleanResourceName.m4a")
                    player.setDataSource(assetFd.fileDescriptor, assetFd.startOffset, assetFd.length)
                    assetFd.close()
                    sourceLoaded = true
                    Log.d(TAG, "تم تحميل صوت الأذان بنجاح من أصول فلاتر مباشرة (Flutter Assets)")
                } catch (ex: Exception) {
                    Log.e(TAG, "المحاولة الثالثة (Flutter Assets) لم تفلح: ${ex.message}")
                }
            }
            
            // إذا فشلت كافة الطبقات الثلاث، نلجأ للمنبه الافتراضي للنظام
            if (!sourceLoaded) {
                Log.w(TAG, "استخدام منبه النظام الافتراضي لعدم تمكن النظام من قراءة الصوت المخصص: $cleanResourceName")
                val defaultUri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
                player.setDataSource(this, defaultUri)
            }
            
            player.prepare()
            player.isLooping = alarmData.loopAudio
            player.setVolume(alarmData.volume, alarmData.volume)
            player.start()

            // مستمع لإنهاء الصوت لإغلاق الخدمة تلقائياً إذا كان التكرار معطلاً
            if (!alarmData.loopAudio) {
                player.setOnCompletionListener {
                    stopAlarm()
                }
            }
            mediaPlayer = player
        } catch (e: Exception) {
            Log.e(TAG, "فشل كامل في تشغيل مشغل الصوت: ${e.message}", e)
        }
    }

    /**
     * كتم أو إلغاء كتم صوت الرنين دون إغلاق الواجهة أو الإشعار.
     */
    private fun muteAlarm() {
        try {
            if (isMuted) {
                // إلغاء الكتم: استئناف تشغيل الصوت والهزاز
                isMuted = false
                Log.d(TAG, "تم إلغاء كتم صوت المنبه")
                mediaPlayer?.start()
                
                // استئناف الهزاز إذا كان مفعلاً
                currentAlarmData?.let { alarmData ->
                    if (alarmData.vibrate) {
                        if (vibrator == null) {
                            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 1000, 1000), 0))
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator?.vibrate(longArrayOf(0, 1000, 1000), 0)
                        }
                    }
                }
            } else {
                // كتم الصوت: إيقاف مؤقت للصوت والهزاز
                isMuted = true
                Log.d(TAG, "تم كتم صوت المنبه")
                if (mediaPlayer?.isPlaying == true) {
                    mediaPlayer?.pause()
                }
                vibrator?.cancel()
            }
        } catch (e: Exception) {
            Log.e(TAG, "فشل تعديل حالة الكتم/التشغيل: ${e.message}")
        }
    }

    /**
     * إيقاف تشغيل المنبه بالكامل ومسح الهزاز والإشعارات وإغلاق الخدمة.
     */
    private fun stopAlarm() {
        Log.d(TAG, "إيقاف المنبه بالكامل وإنهاء الخدمة")
        unregisterPowerButtonReceiver()
        releaseNativeAudioSystem()
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
        } catch (e: Exception) {
            Log.e(TAG, "خطأ أثناء إيقاف MediaPlayer: ${e.message}")
        }

        try {
            vibrator?.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "خطأ أثناء إيقاف الهزاز: ${e.message}")
        }

        originalAlarmVolume?.let {
            try {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.setStreamVolume(AudioManager.STREAM_ALARM, it, 0)
                Log.d(TAG, "تمت استعادة مستوى صوت المنبه بالنظام إلى: $it")
            } catch (e: Exception) {
                Log.e(TAG, "فشل استعادة مستوى صوت المنبه بالنظام: ${e.message}")
            }
            originalAlarmVolume = null
        }

        try {
            val stoppedIntent = Intent(ACTION_ALARM_STOPPED)
            sendBroadcast(stoppedIntent)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ أثناء إرسال بث توقف الأذان: ${e.message}")
        }

        // إيقاف نمط الخدمة الخلفية ومسح الإشعار
        stopForeground(true)
        // إيقاف الخدمة الحالية
        stopSelf()
    }

    /**
     * إعداد واستغلال الميزة الهاردويرية الافتراضية للنظام (AudioFocus & MediaSession)
     * والتي تضمن قيام نظام أندرويد (سامسونج وغيرها) بكتم الأذان تلقائياً عند الضغط على أي زر هاردوير.
     */
    private fun setupNativeAudioSystem() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        val focusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
            Log.d(TAG, "حدث تغيّر في تركيز الصوت بالنظام AudioFocus: $focusChange")
            // فقط عند الفقدان الكلي الدائم لتركيز الصوت (مثل إجراء أو استقبال مكالمة هاتفية) نوقف الأذان
            if (focusChange == AudioManager.AUDIOFOCUS_LOSS) {
                Log.d(TAG, "تم فقدان تركيز الصوت الدائم من النظام (مكالمة هاتفية)، إيقاف الأذان...")
                stopAlarm()
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()

                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    .setAudioAttributes(audioAttributes)
                    .setAcceptsDelayedFocusGain(false)
                    .setOnAudioFocusChangeListener(focusChangeListener)
                    .build()

                audioManager.requestAudioFocus(audioFocusRequest!!)
            } else {
                @Suppress("DEPRECATION")
                audioManager.requestAudioFocus(
                    focusChangeListener,
                    AudioManager.STREAM_ALARM,
                    AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "فشل طلب AudioFocus الافتراضي: ${e.message}")
        }

        try {
            mediaSession = MediaSession(this, "AdhanMediaSession").apply {
                setCallback(object : MediaSession.Callback() {
                    override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                        Log.d(TAG, "تم استقبال نية أزرار الهاردوير الافتراضية عبر MediaSession: $mediaButtonIntent")
                        stopAlarm()
                        return true
                    }
                    override fun onPause() {
                        Log.d(TAG, "تم استقبال أمر Pause افتراضي من النظام")
                        stopAlarm()
                    }
                    override fun onStop() {
                        Log.d(TAG, "تم استقبال أمر Stop افتراضي من النظام")
                        stopAlarm()
                    }
                })
                val state = PlaybackState.Builder()
                    .setActions(PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or PlaybackState.ACTION_STOP)
                    .setState(PlaybackState.STATE_PLAYING, PlaybackState.PLAYBACK_POSITION_UNKNOWN, 1.0f)
                    .build()
                setPlaybackState(state)
                isActive = true
            }
            Log.d(TAG, "تم تفعيل MediaSession الافتراضية بنجاح لصيد مفاتيح النظام")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تهيئة MediaSession: ${e.message}")
        }
    }

    private fun releaseNativeAudioSystem() {
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
                audioFocusRequest = null
            } else {
                @Suppress("DEPRECATION")
                audioManager.abandonAudioFocus(null)
            }

            mediaSession?.let {
                it.isActive = false
                it.release()
                mediaSession = null
            }
            Log.d(TAG, "تم تحرير ميزات النظام الافتراضية AudioFocus & MediaSession بنجاح")
        } catch (e: Exception) {
            Log.e(TAG, "خطأ أثناء تحرير ميزات الصوت الافتراضية: ${e.message}")
        }
    }

    /**
     * إنشاء قناة الإشعارات الخاصة بالمنبه (متطلب إلزامي في أندرويد 8+).
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "تنبيهات الصلوات والمنبهات"
            val descriptionText = "قناة مخصصة لتشغيل نغمات الأذان والصلوات في وقتها"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableLights(true)
                enableVibration(false) // نتحكم بالهزاز يدوياً لتفادي تداخل نغمة القناة الافتراضية
                // تعيين قناة الصوت لتشغيل الأذان كمنبه لتخطي الأوضاع الصامتة
                setSound(
                    null, // نلغي الصوت الافتراضي للقناة لأننا نشغله يدوياً وبدقة عبر MediaPlayer
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
            }
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun updateVolume(volume: Float) {
        try {
            mediaPlayer?.setVolume(volume, volume)
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            val targetVolume = (volume * maxVolume).toInt()
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, targetVolume, 0)
            Log.d(TAG, "تحديث مستوى صوت الأذان تجريبياً لحظياً إلى: $targetVolume")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تحديث مستوى الصوت لحظياً: ${e.message}")
        }
    }

    private fun updateVibration(vibrate: Boolean) {
        try {
            if (vibrate) {
                if (vibrator == null) {
                    vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 1000, 1000), 0))
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator?.vibrate(longArrayOf(0, 1000, 1000), 0)
                    }
                }
            } else {
                vibrator?.cancel()
                vibrator = null
            }
            Log.d(TAG, "تحديث حالة الاهتزاز تجريبياً لحظياً إلى: $vibrate")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تحديث الاهتزاز لحظياً: ${e.message}")
        }
    }

    private fun registerPowerButtonReceiver() {
        try {
            unregisterPowerButtonReceiver()
            alarmStartTime = System.currentTimeMillis()
            powerButtonReceiver = object : android.content.BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val action = intent?.action
                    val elapsed = System.currentTimeMillis() - alarmStartTime
                    
                    Log.d(TAG, "رصد حدث زر النظام أو الشاشة: $action بعد $elapsed م.ث")

                    // عند ضغط زر الطاقة الجانبي لإغلاق الشاشة أثناء رنين الأذان، نوقف الأذان
                    if (action == Intent.ACTION_SCREEN_OFF) {
                        Log.d(TAG, "تم رصد ضغطة زر الطاقة الجانبي لإغلاق الشاشة، إيقاف الأذان...")
                        stopAlarm()
                        return
                    }
                    
                    // عند تغيير أزرار الصوت الهاردويرية بعد مرور ثانية على الأقل من بدء الأذان
                    if (elapsed > 1000 && (action == "android.media.VOLUME_CHANGED_ACTION" ||
                                           action == "android.media.STREAM_MUTE_CHANGED_ACTION")) {
                        Log.d(TAG, "تم رصد تغيير أزرار الصوت بعد بدء الأذان ($action بعد $elapsed م.ث)، جاري إيقاف الأذان...")
                        stopAlarm()
                    }
                }
            }
            val filter = android.content.IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction("android.media.VOLUME_CHANGED_ACTION")
                addAction("android.media.STREAM_MUTE_CHANGED_ACTION")
                priority = IntentFilter.SYSTEM_HIGH_PRIORITY
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                try {
                    registerReceiver(powerButtonReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                } catch (e: Exception) {
                    registerReceiver(powerButtonReceiver, filter, Context.RECEIVER_EXPORTED)
                }
            } else {
                registerReceiver(powerButtonReceiver, filter)
            }
            Log.d(TAG, "تم بنجاح تسجيل مراقب زر الطاقة الجانبي وأزرار الصوت (Samsung One UI Compatible)")
        } catch (e: Exception) {
            Log.e(TAG, "فشل تسجيل مراقب زر القفل: ${e.message}")
        }
    }

    private fun unregisterPowerButtonReceiver() {
        try {
            powerButtonReceiver?.let {
                unregisterReceiver(it)
                powerButtonReceiver = null
                Log.d(TAG, "تم إلغاء تسجيل مراقب زر الطاقة/القفل")
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في إلغاء تسجيل مراقب زر القفل: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAlarm()
    }
}
