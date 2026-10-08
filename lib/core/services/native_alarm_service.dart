import 'package:flutter/services.dart';
import 'dart:developer' as developer;

/// ============================================================================
/// اسم الملف: native_alarm_service.dart
/// المسؤولية: تقديم واجهة برمجية موحدة في فلاتر للتواصل مع نظام المنبهات الأصلي في الهاتف.
/// سبب الإنشاء: توفير طبقة تجريد (Abstraction) تمنع التداخل المباشر مع MethodChannel وتسهل الجدولة.
/// متى يستخدم: عند جدولة الصلوات أو إلغائها من أي مكان داخل كود Dart.
/// من يستدعيه: adhan_notification_service.dart أو واجهات التحكم في الإعدادات.
/// الملفات التي يتواصل معها: AlarmBridge.kt في الأندرويد (عبر قناة البث المشتركة).
/// ============================================================================
class NativeAlarmService {
  // اسم قناة الاتصال الموحدة والمطابقة لملف الأندرويد
  static const MethodChannel _channel = MethodChannel('com.tarteel.app/alarm');

  /// جدولة منبه دقيق في الهاتف.
  /// 
  /// [id]: المعرف الفريد للمنبه (مثلاً: fadjr_2026_07_24).
  /// [type]: نوع المنبه كـ نص (ADHAN, IQAMAH, AZKAR, REMINDER).
  /// [title]: العنوان المعروض للمستخدم.
  /// [subtitle]: الوصف أو التفاصيل المعروضة أسفل العنوان.
  /// [audioFile]: اسم ملف الصوت الموجود في res/raw (بدون الامتداد).
  /// [audioSource]: مصدر تشغيل الصوت (RAW_RESOURCE, SYSTEM_DEFAULT, NONE).
  /// [scheduledTime]: وقت إطلاق التنبيه بصيغة DateTime.
  /// [vibrate]: هل يهتز الهاتف عند الرنين.
  /// [fullScreen]: هل يتم فتح الشاشة التفاعلية بملء الشاشة فوق قفل الهاتف.
  /// [volume]: قوة صوت الرنين (من 0.0 إلى 1.0).
  /// [loopAudio]: هل يتكرر ملف الصوت تلقائياً عند انتهائه.
  /// [payload]: بيانات اختيارية يتم تمريرها وإعادتها للتطبيق.
  static Future<bool> scheduleAlarm({
    required String id,
    required String type,
    required String title,
    required String subtitle,
    required String audioFile,
    required String audioSource,
    required DateTime scheduledTime,
    bool vibrate = true,
    bool fullScreen = true,
    double volume = 1.0,
    bool loopAudio = false,
    String? payload,
  }) async {
    try {
      // تحويل التاريخ إلى ملي ثانية (Epoch Milliseconds) كما يتوقعه الأندرويد
      final int timeMillis = scheduledTime.millisecondsSinceEpoch;

      final Map<String, dynamic> args = {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'audioFile': audioFile,
        'audioSource': audioSource,
        'scheduledTime': timeMillis,
        'vibrate': vibrate,
        'fullScreen': fullScreen,
        'volume': volume,
        'loopAudio': loopAudio,
        'payload': payload,
      };

      developer.log('بدء إرسال طلب جدولة المنبه $id لوقت: $scheduledTime', name: 'NativeAlarmService');
      
      final bool? success = await _channel.invokeMethod<bool>('scheduleAlarm', args);
      return success ?? false;
    } on PlatformException catch (e) {
      developer.log('فشلت جدولة المنبه الأصلي بسبب خطأ النظام: ${e.message}', name: 'NativeAlarmService', error: e);
      return false;
    } catch (e) {
      developer.log('حدث خطأ غير متوقع أثناء جدولة المنبه: $e', name: 'NativeAlarmService', error: e);
      return false;
    }
  }

  /// إلغاء منبه محدد من الهاتف والذاكرة باستخدام معرفه.
  static Future<bool> cancelAlarm(String id) async {
    try {
      developer.log('إرسال طلب إلغاء المنبه بمعرف: $id', name: 'NativeAlarmService');
      final bool? success = await _channel.invokeMethod<bool>('cancelAlarm', id);
      return success ?? false;
    } on PlatformException catch (e) {
      developer.log('فشل إلغاء المنبه بسبب خطأ النظام: ${e.message}', name: 'NativeAlarmService', error: e);
      return false;
    } catch (e) {
      developer.log('حدث خطأ أثناء إلغاء المنبه: $e', name: 'NativeAlarmService', error: e);
      return false;
    }
  }

  /// إلغاء كافة المنبهات والصلوات المجدولة في نظام الهاتف ومسح الذاكرة بالكامل.
  static Future<bool> cancelAllAlarms() async {
    try {
      developer.log('إرسال طلب إلغاء كافة المنبهات المجدولة', name: 'NativeAlarmService');
      final bool? success = await _channel.invokeMethod<bool>('cancelAllAlarms');
      return success ?? false;
    } on PlatformException catch (e) {
      developer.log('فشل إلغاء كافة المنبهات بسبب خطأ النظام: ${e.message}', name: 'NativeAlarmService', error: e);
      return false;
    } catch (e) {
      developer.log('حدث خطأ أثناء إلغاء كافة المنبهات: $e', name: 'NativeAlarmService', error: e);
      return false;
    }
  }

  /// تشغيل أذان تجريبي فوراً لاختبار الصوت والاهتزاز.
  static Future<bool> playTestAdhan({
    required String audioFile,
    required double volume,
    required bool vibrate,
  }) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('playTestAdhan', {
        'id': 'adhan_test_preview',
        'type': 'ADHAN',
        'title': 'أذان تجريبي',
        'subtitle': 'تعديل مستوى الصوت والاهتزاز',
        'audioFile': audioFile,
        'audioSource': 'RAW_RESOURCE',
        'scheduledTime': DateTime.now().millisecondsSinceEpoch,
        'vibrate': vibrate,
        'fullScreen': false,
        'volume': volume,
        'loopAudio': false,
      });
      return success ?? false;
    } catch (e) {
      developer.log('Error playing test Adhan: $e', name: 'NativeAlarmService');
      return false;
    }
  }

  /// تحديث مستوى صوت الأذان التجريبي الجاري تشغيله حالياً.
  static Future<void> updateTestVolume(double volume) async {
    try {
      await _channel.invokeMethod('updateTestVolume', volume);
    } catch (e) {
      developer.log('Error updating test volume: $e', name: 'NativeAlarmService');
    }
  }

  /// تحديث اهتزاز الأذان التجريبي الجاري تشغيله حالياً.
  static Future<void> updateTestVibration(bool vibrate) async {
    try {
      await _channel.invokeMethod('updateTestVibration', vibrate);
    } catch (e) {
      developer.log('Error updating test vibration: $e', name: 'NativeAlarmService');
    }
  }

  /// إيقاف المنبه الفعال حالياً أو الأذان التجريبي.
  static Future<bool> stopActiveAlarm() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('stopActiveAlarm');
      return success ?? false;
    } catch (e) {
      developer.log('Error stopping active alarm: $e', name: 'NativeAlarmService');
      return false;
    }
  }
}
