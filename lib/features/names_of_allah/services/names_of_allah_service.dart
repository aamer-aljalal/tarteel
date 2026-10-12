import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tarteel/features/names_of_allah/models/name_model.dart';

class NamesOfAllahService {
  /// Loads Allah's 99 Beautiful Names
  static Future<List<AllahName>> loadAllahNames() async {
    try {
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(
          'assets/json/names/names_of_allah.json',
        );
      } catch (_) {
        jsonString = await rootBundle.loadString(
          'assets/json/names_of_allah.json',
        );
      }

      final List<dynamic> data = jsonDecode(jsonString);
      return data
          .map((e) => AllahName.fromJson(e, category: NameCategory.allah))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Loads Prophet Muhammad's (PBUH) Names
  static Future<List<AllahName>> loadProphetNames() async {
    try {
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(
          'assets/json/names/names_of_moahmed.json',
        );
      } catch (_) {
        jsonString = await rootBundle.loadString(
          'assets/json/names_of_moahmed.json',
        );
      }

      final dynamic decoded = jsonDecode(jsonString);
      List<dynamic> listData;
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        listData = decoded['data'] as List<dynamic>;
      } else if (decoded is List) {
        listData = decoded;
      } else {
        listData = [];
      }

      final List<AllahName> result = [];
      for (int i = 0; i < listData.length; i++) {
        final item = listData[i];
        if (item is Map<String, dynamic>) {
          result.add(
            AllahName.fromJson(
              item,
              category: NameCategory.prophet,
              fallbackId: i + 1,
            ),
          );
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }

  /// Loads names by category
  static Future<List<AllahName>> loadNamesByCategory(
    NameCategory category,
  ) async {
    if (category == NameCategory.prophet) {
      return loadProphetNames();
    }
    return loadAllahNames();
  }

  /// Backward compatible alias
  static Future<List<AllahName>> loadNames() => loadAllahNames();
}
