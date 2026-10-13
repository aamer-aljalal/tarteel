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

class HomeActionsService {
  /// مفتاح تخزين الأزرار الإضافية الديناميكية القادمة من جيت هب
  static const String _dynamicActionsKey = 'dynamic_extra_actions_v1';

  /// مسار ملف الأزرار الافتراضية في أصول التطبيق
  static const String _defaultAssetPath = 'assets/json/home_actions.json';

  // ============================================================================
  // 📥 قراءة وتحميل الأزرار (ملف الأصول المحلي + الأزرار الإضافية من جيت هب)
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

      // 3. دمج الأزرار المحلية مع الإضافية (مع الحفاظ على ترتيب ملف JSON)
      final List<AccessListModel> result = [];

      for (final local in localActions) {
        if (!local.isEnabled) continue;
        // إذا وجد تحديث من جيت هب لنفس الزر بالمعرّف id، نأخذ التحديث
        final remoteOverrideIndex =
            remoteActions.indexWhere((r) => r.id == local.id);
        if (remoteOverrideIndex != -1) {
          result.add(remoteActions[remoteOverrideIndex]);
        } else {
          result.add(local);
        }
      }

      // إضافة أي أزرار جديدة تماماً أتت من جيت هب وليست في ملف الأصول المحلي
      for (final remote in remoteActions) {
        final existsLocally = localActions.any((l) => l.id == remote.id);
        if (!existsLocally && remote.isEnabled) {
          result.add(remote);
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
      for (final item in jsonList) {
        final action = AccessListModel.fromJson(item);
        await addOrUpdateAction(action);
      }
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
