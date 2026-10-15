import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/lazy_data_loader.dart';
import 'package:tarteel/features/azkar/icons/azkar_icons.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/model/zekr_model%20.dart';
import 'package:tarteel/routes/AppRoutes.dart';

class AzkarService implements LazyDataLoader<AccessListModel, ZekrCategory> {
  // كاش البيانات الخام للـ JSON
  static dynamic _rawJsonData;

  // كاش الكتالوج الخفيف (العناوين والأيقونات فقط - سريع جداً)
  static List<AccessListModel>? _cachedHeaders;
  static List<AccessListModel>? get cachedHeaders => _cachedHeaders;

  // كاش كامل للأقسام
  static List<ZekrCategory>? _cachedCategories;

  // كاش On-Demand لتفاصيل كل قسم حسب عنوانه
  static final Map<String, ZekrCategory> _detailsCache = {};

  // ============================================================================
  // واجهة LazyDataLoader: جلب العناوين بسرعة البرق (0 ثانية)
  // ============================================================================
  @override
  Future<List<AccessListModel>> loadHeaders() async {
    return loadAzkarAsActions();
  }

  // واجهة LazyDataLoader: جلب التفاصيل الكاملة عند النقر
  @override
  Future<ZekrCategory> loadDetails(AccessListModel header) async {
    return loadCategoryByTitle(header.title);
  }

  // جلب البيانات الخام من ملف JSON لمرة واحدة
  static Future<dynamic> _getRawData() async {
    if (_rawJsonData != null) return _rawJsonData;
    final String jsonString = await rootBundle.loadString(
      'assets/json/azkar/azkar.json',
    );
    _rawJsonData = jsonDecode(jsonString);
    return _rawJsonData;
  }

  // ============================================================================
  // جلب العناوين فقط كأزرار خفيفة وسريعة دون فك تشفير وتوليد آلاف الأذكار
  // ============================================================================
  static Future<List<AccessListModel>> loadAzkarAsActions() async {
    if (_cachedHeaders != null) return _cachedHeaders!;

    final rawData = await _getRawData();
    List<AccessListModel> headers = [];

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          final String title = item['title'] as String? ?? '';
          headers.add(
            AccessListModel(
              icon: AzkarIcons.icons[title] ?? Icons.menu_book,
              title: title,
              route: AppRoutes.zkarDetails,
              arguments: title,
            ),
          );
        }
      }
    } else if (rawData is Map<String, dynamic>) {
      rawData.forEach((key, _) {
        headers.add(
          AccessListModel(
            icon: AzkarIcons.icons[key] ?? Icons.menu_book,
            title: key,
            route: AppRoutes.zkarDetails,
            arguments: key,
          ),
        );
      });
    }

    _cachedHeaders = headers;
    return _cachedHeaders!;
  }

  // ============================================================================
  // جلب تفاصيل قسم محدد فقط عند الطلب (On-Demand)
  // ============================================================================
  static Future<ZekrCategory> loadCategoryByTitle(String title) async {
    if (_detailsCache.containsKey(title)) {
      return _detailsCache[title]!;
    }

    final rawData = await _getRawData();

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic> && item['title'] == title) {
          final cat = ZekrCategory.fromJson(item);
          _detailsCache[title] = cat;
          return cat;
        }
      }
    } else if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey(title)) {
        final list = rawData[title] as List;
        final azkar = list
            .map((e) => ZekrModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final cat = ZekrCategory(id: 1, title: title, azkar: azkar);
        _detailsCache[title] = cat;
        return cat;
      }
    }

    final fallback = ZekrCategory(id: 0, title: title, azkar: []);
    _detailsCache[title] = fallback;
    return fallback;
  }

  // ============================================================================
  // جلب كافة الأقسام (للتوافق القديم)
  // ============================================================================
  static Future<List<ZekrCategory>> loadAzkar() async {
    if (_cachedCategories != null) return _cachedCategories!;

    final rawData = await _getRawData();
    List<ZekrCategory> categories = [];

    if (rawData is List) {
      categories = rawData
          .map((e) => ZekrCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (rawData is Map<String, dynamic>) {
      int idx = 1;
      rawData.forEach((key, value) {
        List<ZekrModel> azkar = (value as List)
            .map((e) => ZekrModel.fromJson(e as Map<String, dynamic>))
            .toList();
        categories.add(ZekrCategory(id: idx++, title: key, azkar: azkar));
      });
    }

    _cachedCategories = categories;
    for (var cat in categories) {
      _detailsCache[cat.title] = cat;
    }
    return categories;
  }

  static void clearCache() {
    _rawJsonData = null;
    _cachedCategories = null;
    _cachedHeaders = null;
    _detailsCache.clear();
  }
}
