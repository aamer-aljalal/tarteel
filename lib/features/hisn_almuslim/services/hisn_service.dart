import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/lazy_data_loader.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/routes/AppRoutes.dart';

class HisnService implements LazyDataLoader<AccessListModel, HisnCategory> {
  // كاش للبيانات الخام للـ JSON بالكامل لتفادي إعادة قراءة الملف من الديسك
  static Map<String, dynamic>? _rawJsonMap;

  // كاش للعناوين السريعة فقط
  static List<AccessListModel>? _cachedHeaders;

  // كاش تفاصيل الأقسام التي تم فتحها مسبقاً (On-Demand Cache)
  static final Map<String, HisnCategory> _detailsCache = {};

  // ============================================================================
  // 1. الواجهة العامة LazyDataLoader: تحميل العناوين السريعة فقط (0 ثانية)
  // ============================================================================
  @override
  Future<List<AccessListModel>> loadHeaders() async {
    return loadHisnAsActions();
  }

  // ============================================================================
  // 2. الواجهة العامة LazyDataLoader: تحميل تفاصيل باب محدد فقط عند الضغط عليه
  // ============================================================================
  @override
  Future<HisnCategory> loadDetails(AccessListModel header) async {
    return loadCategoryByTitle(header.title);
  }

  // ============================================================================
  // جلب خريطة الـ JSON الخام لمرة واحدة فقط
  // ============================================================================
  static Future<Map<String, dynamic>> _getRawData() async {
    if (_rawJsonMap != null) return _rawJsonMap!;
    final String jsonString =
        await rootBundle.loadString('assets/json/hisn_almuslim.json');
    _rawJsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return _rawJsonMap!;
  }

  // ============================================================================
  // جلب العناوين كأزرار خفيفة وسريعة جداً (فقط المفاتيح والأيقونات دون لمس النصوص)
  // ============================================================================
  static Future<List<AccessListModel>> loadHisnAsActions() async {
    if (_cachedHeaders != null) return _cachedHeaders!;

    final rawData = await _getRawData();

    _cachedHeaders = rawData.keys.map((title) {
      return AccessListModel(
        icon: getHisnIcon(title),
        title: title,
        route: AppRoutes.hisnDetails,
        arguments: title, // نمرر فقط العنوان أو الـ Model
      );
    }).toList();

    return _cachedHeaders!;
  }

  // ============================================================================
  // تحميل تفاصيل باب محدد عند طلبه فقط (On-Demand)
  // ============================================================================
  static Future<HisnCategory> loadCategoryByTitle(String title) async {
    if (_detailsCache.containsKey(title)) {
      return _detailsCache[title]!;
    }

    final rawData = await _getRawData();
    final categoryData = rawData[title];

    if (categoryData != null && categoryData is Map<String, dynamic>) {
      final category = HisnCategory.fromJson(title, categoryData);
      _detailsCache[title] = category;
      return category;
    }

    // احتياط في حال عدم العثور عليه
    final fallback = HisnCategory(title: title, texts: [], footnotes: []);
    _detailsCache[title] = fallback;
    return fallback;
  }

  // تحميل كافة الأقسام (متوافق مع أي شاشة تستدعيه بالكامل)
  static Future<List<HisnCategory>> loadHisn() async {
    final rawData = await _getRawData();
    List<HisnCategory> list = [];
    rawData.forEach((key, val) {
      if (_detailsCache.containsKey(key)) {
        list.add(_detailsCache[key]!);
      } else if (val is Map<String, dynamic>) {
        final cat = HisnCategory.fromJson(key, val);
        _detailsCache[key] = cat;
        list.add(cat);
      }
    });
    return list;
  }

  // مسح الكاش إن لزم
  static void clearCache() {
    _rawJsonMap = null;
    _cachedHeaders = null;
    _detailsCache.clear();
  }

  // ============================================================================
  // أيقونات الأبواب
  // ============================================================================
  static IconData getHisnIcon(String title) {
    if (title.contains('الوضوء')) return Icons.water_drop_outlined;
    if (title.contains('المسجد')) return Icons.mosque_outlined;
    if (title.contains('البيت') || title.contains('المنزل')) return Icons.home_outlined;
    if (title.contains('الثوب') || title.contains('لبس')) return Icons.checkroom_outlined;
    if (title.contains('الموت') ||
        title.contains('الميت') ||
        title.contains('القبور') ||
        title.contains('الجنازة') ||
        title.contains('التعزية') ||
        title.contains('إغماض')) {
      return Icons.co_present_outlined;
    }
    if (title.contains('المطر') ||
        title.contains('الريح') ||
        title.contains('الرعد') ||
        title.contains('الهلال') ||
        title.contains('الاستسقاء')) {
      return Icons.thunderstorm_outlined;
    }
    if (title.contains('الصباح') || title.contains('المساء')) return Icons.wb_sunny_outlined;
    if (title.contains('النوم') ||
        title.contains('الاستيقاظ') ||
        title.contains('تقلب')) {
      return Icons.alarm_on_outlined;
    }
    if (title.contains('الطعام') || title.contains('إفطار')) return Icons.restaurant_menu_outlined;
    if (title.contains('العدو') ||
        title.contains('السلطان') ||
        title.contains('خاف') ||
        title.contains('طرد')) {
      return Icons.shield_outlined;
    }
    if (title.contains('الهم') ||
        title.contains('الحزن') ||
        title.contains('الكرب') ||
        title.contains('مصيبة')) {
      return Icons.mood_bad_outlined;
    }
    if (title.contains('الذكر')) return Icons.star_outline_rounded;
    if (title.contains('المقدمة')) return Icons.info_outline;
    if (title.contains('الخلاء')) return Icons.door_sliding_outlined;
    if (title.contains('الأذان')) return Icons.volume_up_outlined;
    if (title.contains('الركوع') ||
        title.contains('السجود') ||
        title.contains('الرفع') ||
        title.contains('التشهد') ||
        title.contains('قنوت') ||
        title.contains('الوتر') ||
        title.contains('الصلاة')) {
      return Icons.accessibility_new_outlined;
    }
    if (title.contains('الاستخارة')) return Icons.psychology_outlined;
    if (title.contains('الدين')) return Icons.monetization_on_outlined;

    return Icons.menu_book_outlined;
  }
}
