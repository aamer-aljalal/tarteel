import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentAction {
  final String category; // 'quran', 'azkar', 'names_of_allah', 'tasbeeh'
  final String title;    // e.g. 'سورة البقرة' or 'أذكار الصباح'
  final String subtitle; // e.g. 'صفحة 5' or 'تصفح'
  final Map<String, dynamic> extraData; // Map for navigation targets like surah index, category id

  RecentAction({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.extraData,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'title': title,
    'subtitle': subtitle,
    'extraData': extraData,
  };

  factory RecentAction.fromJson(Map<String, dynamic> json) => RecentAction(
    category: json['category'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    extraData: json['extraData'] != null ? Map<String, dynamic>.from(json['extraData']) : {},
  );
}

class RecentActionsManager {
  static const String _key = 'recent_resume_actions';

  static Future<List<RecentAction>> getActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_key) ?? [];
      return jsonList.map((e) => RecentAction.fromJson(json.decode(e))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addAction({
    required String category,
    required String title,
    required String subtitle,
    required Map<String, dynamic> extraData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actions = await getActions();

      // Remove ANY existing item of the same category to keep exactly one item per category
      actions.removeWhere((item) => item.category == category);

      // Add to start of list
      actions.insert(0, RecentAction(
        category: category,
        title: title,
        subtitle: subtitle,
        extraData: extraData,
      ));

      // Limit to max 5 items
      if (actions.length > 5) {
        actions.removeRange(5, actions.length);
      }

      final jsonList = actions.map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList(_key, jsonList);
    } catch (e) {
      // Fail-safe
    }
  }
}
