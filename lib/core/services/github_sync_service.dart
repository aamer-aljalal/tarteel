/// ==============================================================================
///  وصف الملف: github_sync_service.dart
/// ==============================================================================
/// الخدمة المركزية العامة لجلب البيانات والملفات السحابية من GitHub Raw (أو أي رابط API).
///
///  مميزات هذه الخدمة:
/// 1. عامة ومفتوحة (Generic): تعمل لجلب أزرار الرئيسية، بنك الأسئلة، القوالب، إلخ.
/// 2. آمنة ولا تعطل التطبيق (Fail-Safe): إذا انقطع الإنترنت أو فشل الرابط، تعيد null
///    ليستمر التطبيق في استخدام البيانات المحلية بأمان.
/// 3. خفيفة جداً: تعتمد على HttpClient الأصلي المدمج في Dart دون الحاجة لمكتبات إضافية.
/// 4. تدعم مهلة اتصال قصيرة (Timeout): لضمان عدم تعليق التطبيق عند ضعف الشبكة.
/// ==============================================================================
library;

import 'dart:convert';
import 'dart:io';

class GithubSyncService {
  /// مهلة الاتصال القصوى (7 ثوانٍ لضمان سرعة الاستجابة وعدم انتظار المستخدم)
  static const Duration _timeoutDuration = Duration(seconds: 7);

  // ============================================================================
  //  جلب ملف JSON خام (Raw) كـ خريطة Map أو مصفوفة List
  // ============================================================================
  static Future<dynamic> fetchRawJson(String rawUrl) async {
    HttpClient? client;
    try {
      if (rawUrl.trim().isEmpty) return null;

      // منع الكاش الخاص بـ GitHub CDN عبر إضافة توقيت زمني وترويسات no-cache
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final uriString = rawUrl.trim().contains('?')
          ? '${rawUrl.trim()}&_t=$cacheBuster'
          : '${rawUrl.trim()}?_t=$cacheBuster';

      final uri = Uri.parse(uriString);
      client = HttpClient();
      client.connectionTimeout = _timeoutDuration;

      final request = await client.getUrl(uri).timeout(_timeoutDuration);
      // إضافة ترويسة قبول JSON والترميز العربي UTF-8 ومنع الكاش نهائياً
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache, no-store, must-revalidate');
      request.headers.set(HttpHeaders.pragmaHeader, 'no-cache');

      final response = await request.close().timeout(_timeoutDuration);

      if (response.statusCode == HttpStatus.ok) {
        // قراءة الاستجابة بصيغة utf8 لدعم اللغة العربية بدقة
        final responseBody =
            await response.transform(utf8.decoder).join().timeout(_timeoutDuration);

        if (responseBody.trim().isEmpty) return null;

        final decodedData = json.decode(responseBody);
        return decodedData;
      } else {
        // حدث خطأ في السيرفر أو الرابط غير صحيح
        return null;
      }
    } catch (_) {
      // فشل الاتصال (مثل عدم وجود إنترنت أو انتهاء المهلة)
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  // ============================================================================
  //  جلب مصفوفة كائنات List<Map<String, dynamic>>
  // ============================================================================
  static Future<List<Map<String, dynamic>>?> fetchJsonList(String rawUrl) async {
    final data = await fetchRawJson(rawUrl);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return null;
  }

  // ============================================================================
  //  جلب كائن مفرد Map<String, dynamic>
  // ============================================================================
  static Future<Map<String, dynamic>?> fetchJsonMap(String rawUrl) async {
    final data = await fetchRawJson(rawUrl);
    if (data is Map<String, dynamic>) {
      return data;
    }
    return null;
  }
}
