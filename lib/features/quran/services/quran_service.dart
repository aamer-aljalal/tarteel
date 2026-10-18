import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/helpers/arabic_search_helper.dart';
import 'package:tarteel/core/services/lazy_loader/lazy_data_loader.dart';
import 'package:tarteel/routes/AppRoutes.dart';

import '../models/quran_models.dart';
export '../models/quran_models.dart';


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
  static Map<int, List<QuranAyah>>? _surahAyahsCache;
  static Map<int, List<QuranAyah>>? _pageAyahsCache;
  static Map<String, String>? _interpretations;
  static List<SearchableAyah>? _searchableAyahs;

  static Future<void> preloadQuran() async {
    await _ensureQuranLoaded();
  }

  static Future<void> _ensureQuranLoaded() async {
    if (_surahAyahsCache != null) return;
    try {
      final raw =
          await rootBundle.loadString('assets/json/quran/quran_uthmani.json');
      final parsed = await Isolate.run(() {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final surahs = data['data']['surahs'] as List<dynamic>;

        final surahMap = <int, List<QuranAyah>>{};
        final pageMap = <int, List<QuranAyah>>{};

        for (final s in surahs) {
          final sMap = s as Map<String, dynamic>;
          final surahNumber = sMap['number'] as int;
          final rawAyahs = sMap['ayahs'] as List<dynamic>;

          final ayahsList = <QuranAyah>[];
          for (final a in rawAyahs) {
            final aMap = a as Map<String, dynamic>;
            final verse = aMap['numberInSurah'] as int;
            var text = aMap['text'] as String;

            // إزالة البسملة الملحقة ببداية الآية الأولى لجميع السور عدا الفاتحة (1) والتوبة (9)
            if (surahNumber != 1 && surahNumber != 9 && verse == 1) {
              const prefix1 = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';
              const prefix2 = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ ';
              if (text.startsWith(prefix1)) {
                text = text.substring(prefix1.length).trim();
              } else if (text.startsWith(prefix2)) {
                text = text.substring(prefix2.length).trim();
              }
            }

            final sajdaRaw = aMap['sajda'];
            final hasSajda = sajdaRaw != false && sajdaRaw != null;

            final ayah = QuranAyah(
              chapter: surahNumber,
              verse: verse,
              text: text,
              page: aMap['page'] as int? ?? 1,
              juz: aMap['juz'] as int? ?? 1,
              hizbQuarter: aMap['hizbQuarter'] as int? ?? 1,
              hasSajdah: hasSajda,
            );

            ayahsList.add(ayah);
            pageMap.putIfAbsent(ayah.page, () => []).add(ayah);
          }

          surahMap[surahNumber] = ayahsList;
        }

        return {'surahs': surahMap, 'pages': pageMap};
      });

      _surahAyahsCache = parsed['surahs'] as Map<int, List<QuranAyah>>;
      _pageAyahsCache = parsed['pages'] as Map<int, List<QuranAyah>>;
    } catch (e) {
      debugPrint('Error loading Quran data: $e');
    }
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
    await _ensureQuranLoaded();
    return _surahAyahsCache?[surahNumber] ?? [];
  }

  static Future<List<QuranAyah>> loadPage(int pageNumber) async {
    await _ensureQuranLoaded();
    return _pageAyahsCache?[pageNumber] ?? [];
  }

  static Future<List<SearchableAyah>> loadAllSearchableAyahs() async {
    if (_searchableAyahs != null) return _searchableAyahs!;

    final surahs = await loadSurahs();
    await _ensureQuranLoaded();
    final List<SearchableAyah> results = [];

    for (final surah in surahs) {
      final ayahs = _surahAyahsCache?[surah.number] ?? [];
      for (final ayah in ayahs) {
        results.add(SearchableAyah(
          ayah: ayah,
          surah: surah,
          normalizedText: ArabicSearchHelper.normalize(ayah.text),
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
