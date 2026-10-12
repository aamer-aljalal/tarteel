import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// [FavoritesService]
/// خدمة مركزية وموحدة لإدارة المفضلة في التطبيق (أذكار، حصن المسلم، أدعية، وغيرها).
class FavoritesService {
  static String _storageKeyForType(String type) {
    if (type == 'azkar') return 'saved_azkar';
    if (type == 'hisn') return 'saved_hisn';
    return 'app_favorite_items_$type';
  }

  /// التحقق مما إذا كان العنصر موجوداً في المفضلة
  static Future<bool> isFavorite({
    required String type,
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _storageKeyForType(type);
    final rawItems = prefs.getStringList(storageKey) ?? [];

    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        if (decoded['key'] == key || decoded['content'] == key) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// تبديل حالة المفضلة (إضافة / حذف)
  static Future<bool> toggleFavorite({
    required String type,
    required String key,
    required String content,
    String? title,
    String? description,
    String? reference,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = _storageKeyForType(type);

    List<String> rawItems = prefs.getStringList(storageKey) ?? [];
    bool exists = false;

    rawItems.removeWhere((itemStr) {
      try {
        final decoded = jsonDecode(itemStr) as Map<String, dynamic>;
        if (decoded['key'] == key || decoded['content'] == key || decoded['content'] == content) {
          exists = true;
          return true;
        }
      } catch (_) {}
      return false;
    });

    bool isAdded;
    if (exists) {
      isAdded = false;
    } else {
      final newItem = {
        'key': key,
        'type': type,
        'category': title ?? '',
        'title': title ?? '',
        'content': content,
        'description': description ?? '',
        'reference': reference ?? '',
        'savedAt': DateTime.now().toIso8601String(),
      };
      rawItems.add(jsonEncode(newItem));
      isAdded = true;
    }

    await prefs.setStringList(storageKey, rawItems);
    return isAdded;
  }

  /// جلب كافة العناصر المفضلة لنوع معين أو للكل
  static Future<List<Map<String, dynamic>>> getFavorites({
    String type = 'azkar',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKeyForType(type)) ?? [];
    List<Map<String, dynamic>> items = [];

    for (final raw in rawItems) {
      try {
        items.add(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }

    return items;
  }
}
