import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/features/azkar/icons/azkar_icons.dart';

import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/model/zekr_model%20.dart';
import 'package:tarteel/routes/AppRoutes.dart';

class AzkarService {
  static List<ZekrCategory>? _cachedCategories;

  static Future<List<ZekrCategory>> loadAzkar() async {
    if (_cachedCategories != null) return _cachedCategories!;

    // قراءة ملف json
    final String jsonString = await rootBundle.loadString(
      'assets/json/azkar/azkar.json',
    );

    final dynamic decoded = jsonDecode(jsonString);
    List<ZekrCategory> categories = [];

    if (decoded is List) {
      categories = decoded
          .map((e) => ZekrCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (decoded is Map<String, dynamic>) {
      int idx = 1;
      decoded.forEach((key, value) {
        List<ZekrModel> azkar = (value as List)
            .map((e) => ZekrModel.fromJson(e as Map<String, dynamic>))
            .toList();
        categories.add(ZekrCategory(id: idx++, title: key, azkar: azkar));
      });
    }

    _cachedCategories = categories;
    return categories;
  }

  static void clearCache() {
    _cachedCategories = null;
  }

  // ================= تحويلها إلى Actions =================

  static Future<List<AccessListModel>> loadAzkarAsActions() async {
    final categories = await loadAzkar();

    return categories.map((category) {
      return AccessListModel(
        icon: AzkarIcons.icons[category.title] ?? Icons.menu_book,

        title: category.title,

        route: AppRoutes.zkarDetails,

        arguments: category,
      );
    }).toList();
  }
}
