/// ==============================================================================
/// 📌 وصف الملف: home_actions_service.dart
/// ==============================================================================
/// خدمة إدارة وتخزين أزرار الصفحة الرئيسية محلياً في ذاكرة الهاتف (SharedPreferences).
///
/// 🔄 كيف تعمل هذه الخدمة بذكاء؟
/// 1. دائماً تقرأ أزرارك الأساسية مباشرة من ملف (assets/json/home_actions.json)،
///    لذلك أي تعديل تقوم به على العناوين أو الترتيب ينعكس فوراً!
/// 2. تدمج معها في الوقت الفعلي أي أزرار إضافية قادمة من GitHub والمخزنة في الهاتف.
/// ==============================================================================
library;

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/github_sync_service.dart';
import 'package:tarteel/core/services/lazy_loader/lazy_data_loader.dart';

class HomeActionsService
    implements LazyDataLoader<AccessListModel, AccessListModel> {
  /// الرابط السحابي المباشر لملف أزرار ترتيل على GitHub
  static const String githubActionsUrl =
      'https://github.com/aamer-aljalal/tarteel/blob/main/assets/json/home_actions.json';

  const HomeActionsService();

  @override
  Future<List<AccessListModel>> loadHeaders() async {
    return loadActions();
  }

  @override
  Future<AccessListModel> loadDetails(AccessListModel header) async {
    return header;
  }

  /// مفتاح تخزين الأزرار الإضافية الديناميكية القادمة من جيت هب
  static const String _dynamicActionsKey = 'dynamic_extra_actions_v1';

  /// مسار ملف الأزرار الافتراضية في أصول التطبيق
  static const String _defaultAssetPath = 'assets/json/home_actions.json';

  // ============================================================================
  //  قراءة وتحميل الأزرار (ملف الأصول المحلي + الأزرار الإضافية من جيت هب)
  // ============================================================================
  static Future<List<AccessListModel>> loadActions() async {
    try {
      // 1. نقرأ دائماً الأزرار الأساسية من ملف الأصول (لتظهر تعديلاتك المحلية فوراً)
      final localActions = await _loadFromAssets();

      // 2. نقرأ أي أزرار إضافية قادمة من جيت هب محفوظة في الهاتف
      final prefs = await SharedPreferences.getInstance();
      final cachedDynamicJson = prefs.getString(_dynamicActionsKey);

      final List<AccessListModel> remoteActions = [];
      if (cachedDynamicJson != null && cachedDynamicJson.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(cachedDynamicJson);
        remoteActions.addAll(
          decodedList
              .map(
                (item) =>
                    AccessListModel.fromJson(item as Map<String, dynamic>),
              )
              .where((action) => action.isEnabled),
        );
      }

      // 3. دمج ذكي: إذا وفّر جيت هب قائمة أزرار، يكون ترتيب جيت هب هو الحاكم أولاً
      final List<AccessListModel> result = [];

      if (remoteActions.isNotEmpty) {
        // نتبع ترتيب جيت هب بالملي خطوة بخطوة
        for (final remote in remoteActions) {
          if (!remote.isEnabled) continue;

          // نبحث عن بيانات الزر المحلي إن وجدت لاستكمال أي نواقص
          final localMatchIndex = localActions.indexWhere(
            (l) => l.id == remote.id,
          );

          if (localMatchIndex != -1) {
            final local = localActions[localMatchIndex];
            // دمج ذكي: نأخذ عنوان وأيقونة وترتيب جيت هب، ونأخذ مسار فلاتر إن لم يُحدد
            result.add(
              AccessListModel(
                id: remote.id ?? local.id,
                title: remote.title.isNotEmpty ? remote.title : local.title,
                route: remote.route.isNotEmpty ? remote.route : local.route,
                icon: remote.icon,
                iconName: remote.iconName ?? local.iconName,
                isEnabled: remote.isEnabled,
                badge: remote.badge ?? local.badge,
                arguments: remote.arguments ?? local.arguments,
              ),
            );
          } else {
            // زر جديد تماماً من جيت هب نضعه في مكانه المحدد في الترتيب
            result.add(remote);
          }
        }

        // إضافة أي أزرار محلية متبقية لم يذكرها جيت هب في نهاية القائمة
        for (final local in localActions) {
          final isHandledByRemote = remoteActions.any((r) => r.id == local.id);
          if (!isHandledByRemote && local.isEnabled) {
            result.add(local);
          }
        }
      } else {
        // إذا لم توجد أزرار من جيت هب، نعتمد الترتيب المحلي الافتراضي
        for (final local in localActions) {
          if (local.isEnabled) result.add(local);
        }
      }

      return result;
    } catch (e) {
      // في حالة حدوث أي استثناء، نعتمد ملف الأصول المحلي بأمان
      return await _loadFromAssets();
    }
  }

  // ============================================================================
  // 💾 حفظ قائمة الأزرار الإضافية القادمة من جيت هب
  // ============================================================================
  static Future<void> saveDynamicActions(
    List<AccessListModel> dynamicActions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = dynamicActions.map((action) => action.toJson()).toList();
      final encodedString = json.encode(jsonList);
      await prefs.setString(_dynamicActionsKey, encodedString);
    } catch (_) {}
  }

  // ============================================================================
  // ➕ إضافة أو تحديث زر ديناميكي جديد وحفظه
  // ============================================================================
  static Future<List<AccessListModel>> addOrUpdateAction(
    AccessListModel newAction,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDynamicJson = prefs.getString(_dynamicActionsKey);

    List<AccessListModel> dynamicActions = [];
    if (cachedDynamicJson != null && cachedDynamicJson.isNotEmpty) {
      final List<dynamic> decoded = json.decode(cachedDynamicJson);
      dynamicActions = decoded
          .map((item) => AccessListModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final index = dynamicActions.indexWhere((a) => a.id == newAction.id);
    if (index != -1) {
      dynamicActions[index] = newAction;
    } else {
      dynamicActions.add(newAction);
    }

    await saveDynamicActions(dynamicActions);
    return await loadActions();
  }

  // ============================================================================
  // 🌐 مزامنة الأزرار من رابط GitHub Raw ودمجها فوراً
  // ============================================================================
  static Future<List<AccessListModel>> syncFromGithub(String rawUrl) async {
    final jsonList = await GithubSyncService.fetchJsonList(rawUrl);

    if (jsonList != null && jsonList.isNotEmpty) {
      final remoteActions = jsonList
          .map((item) => AccessListModel.fromJson(item))
          .toList();

      // حفظ القائمة بالكامل بنفس الترتيب الذي رتبه المستخدم في GitHub
      await saveDynamicActions(remoteActions);
    }

    return await loadActions();
  }

  // ============================================================================
  // 🗑️ إزالة زر ديناميكي
  // ============================================================================
  static Future<List<AccessListModel>> removeDynamicAction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDynamicJson = prefs.getString(_dynamicActionsKey);

    if (cachedDynamicJson != null && cachedDynamicJson.isNotEmpty) {
      final List<dynamic> decoded = json.decode(cachedDynamicJson);
      final dynamicActions = decoded
          .map((item) => AccessListModel.fromJson(item as Map<String, dynamic>))
          .where((a) => a.id != id)
          .toList();
      await saveDynamicActions(dynamicActions);
    }

    return await loadActions();
  }

  // ============================================================================
  // 🔄 مسح الأزرار الإضافية والعودة لملف JSON المحلي فقط
  // ============================================================================
  static Future<List<AccessListModel>> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dynamicActionsKey);
    } catch (_) {}

    return await _loadFromAssets();
  }

  // ============================================================================
  // 📂 دالة مساعدة لقراءة ملف JSON من أصول التطبيق
  // ============================================================================
  static Future<List<AccessListModel>> _loadFromAssets() async {
    final jsonString = await rootBundle.loadString(_defaultAssetPath);
    final List<dynamic> decodedList = json.decode(jsonString);
    return decodedList
        .map((item) => AccessListModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
