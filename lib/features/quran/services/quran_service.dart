import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/helpers/arabic_search_helper.dart';
import 'package:tarteel/core/services/lazy_loader/lazy_data_loader.dart';
import 'package:tarteel/routes/AppRoutes.dart';

class QuranSurah {
  const QuranSurah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.transliteration,
    required this.revelationPlace,
    required this.versesCount,
  });

  final int number;
  final String nameArabic;
  final String nameEnglish;
  final String transliteration;
  final String revelationPlace;
  final int versesCount;
}

class QuranAyah {
  const QuranAyah({
    required this.chapter,
    required this.verse,
    required this.text,
  });

  final int chapter;
  final int verse;
  final String text;
}

class SearchableAyah {
  const SearchableAyah({
    required this.ayah,
    required this.surah,
    required this.normalizedText,
  });

  final QuranAyah ayah;
  final QuranSurah surah;
  final String normalizedText;
}

class QuranService implements LazyDataLoader<AccessListModel, QuranSurah> {
  const QuranService();

  static List<AccessListModel>? _cachedActions;

  static Future<List<AccessListModel>> loadSurahsAsActions() async {
    if (_cachedActions != null) return _cachedActions!;

    final surahs = await loadSurahs();
    _cachedActions = surahs.map((surah) {
      final versesText = surah.versesCount == 7
          ? '٧ آيات'
          : '${surah.versesCount} آية';
      return AccessListModel(
        id: surah.number.toString(),
        title: 'سورة ${surah.nameArabic}',
        subtitle: '${surah.revelationPlace} • $versesText • ${surah.nameEnglish}',
        badge: '${surah.number}',
        icon: Icons.menu_book_rounded,
        route: AppRoutes.surahDetails,
        arguments: surah,
      );
    }).toList();

    return _cachedActions!;
  }

  @override
  Future<List<AccessListModel>> loadHeaders() async {
    return loadSurahsAsActions();
  }

  @override
  Future<QuranSurah> loadDetails(AccessListModel header) async {
    if (header.arguments is QuranSurah) {
      return header.arguments as QuranSurah;
    }
    final surahs = await loadSurahs();
    final number = int.tryParse(header.id ?? '') ?? 1;
    return surahs.firstWhere(
      (s) => s.number == number,
      orElse: () => surahs.first,
    );
  }

  static List<QuranSurah>? _surahs;
  static Map<String, dynamic>? _quran;
  static Map<String, String>? _interpretations;
  static List<SearchableAyah>? _searchableAyahs;

  static Future<void> preloadQuran() async {
    if (_quran != null) return;
    try {
      final raw = await rootBundle.loadString('assets/json/quran.json');
      _quran = await Isolate.run(() => jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  static Future<List<QuranSurah>> loadSurahs() async {
    if (_surahs != null) return _surahs!;

    final raw = await rootBundle.loadString('assets/json/metadata.json');
    final decoded = jsonDecode(raw) as List<dynamic>;

    _surahs = decoded.map((item) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as Map<String, dynamic>;
      final revelationPlace = map['revelation_place'] as Map<String, dynamic>;

      return QuranSurah(
        number: map['number'] as int,
        nameArabic: name['ar'] as String,
        nameEnglish: name['en'] as String,
        transliteration: name['transliteration'] as String,
        revelationPlace: revelationPlace['ar'] as String,
        versesCount: map['verses_count'] as int,
      );
    }).toList();

    return _surahs!;
  }

  static Future<List<QuranAyah>> loadAyahs(int surahNumber) async {
    if (_quran == null) {
      final raw = await rootBundle.loadString('assets/json/quran.json');
      _quran = await Isolate.run(() => jsonDecode(raw) as Map<String, dynamic>);
    }

    final rawAyahs = (_quran!['$surahNumber'] as List<dynamic>? ?? []);

    return rawAyahs.map((item) {
      final map = item as Map<String, dynamic>;
      return QuranAyah(
        chapter: map['chapter'] as int,
        verse: map['verse'] as int,
        text: map['text'] as String,
      );
    }).toList();
  }

  static Future<List<SearchableAyah>> loadAllSearchableAyahs() async {
    if (_searchableAyahs != null) return _searchableAyahs!;

    final surahs = await loadSurahs();
    final List<SearchableAyah> results = [];

    if (_quran == null) {
      final raw = await rootBundle.loadString('assets/json/quran.json');
      _quran = await Isolate.run(() => jsonDecode(raw) as Map<String, dynamic>);
    }

    for (final surah in surahs) {
      final rawAyahs = (_quran!['${surah.number}'] as List<dynamic>? ?? []);
      for (final item in rawAyahs) {
        final map = item as Map<String, dynamic>;
        final text = map['text'] as String;
        final ayah = QuranAyah(
          chapter: map['chapter'] as int,
          verse: map['verse'] as int,
          text: text,
        );
        results.add(SearchableAyah(
          ayah: ayah,
          surah: surah,
          normalizedText: ArabicSearchHelper.normalize(text),
        ));
      }
    }

    _searchableAyahs = results;
    return _searchableAyahs!;
  }

  static Future<String> loadInterpretation({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    _interpretations ??= await _loadInterpretations();
    return _interpretations!['$surahNumber:$ayahNumber'] ?? '';
  }

  static Future<int> getAbsoluteAyahOffset(int surahNumber, int ayahNumber) async {
    final surahs = await loadSurahs();
    int offset = 0;
    for (int i = 0; i < surahNumber - 1; i++) {
      offset += surahs[i].versesCount;
    }
    return offset + ayahNumber;
  }

  static Future<Map<String, String>> _loadInterpretations() async {
    final raw = await rootBundle.loadString('assets/json/Interpretation.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final interpretations = <String, String>{};

    for (final item in decoded) {
      final map = item as Map<String, dynamic>;
      final surah = map['sura'] as int?;
      final ayah = map['aya'] as int?;
      final text = _cleanInterpretation(map['text'] as String? ?? '');

      if (surah == null || ayah == null) continue;
      interpretations['$surah:$ayah'] = text;
    }

    return interpretations;
  }

  static String _cleanInterpretation(String value) {
    return value
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .replaceAll(RegExp(r'\s+\n'), '\n')
        .replaceAll(RegExp(r'\n\s+'), '\n')
        .trim();
  }
}
