/// ==============================================================================
///  وصف الملف: generic_catalog_cubit.dart
/// ==============================================================================
/// كيوبت عام لإدارة أي قائمة كتالوج سريع (أذكار، حصن، أحاديث، سور، إلخ).
/// يدعم التحميل الفوري، الكاش الذكي، والبحث التلقائي باللغة العربية.
/// ==============================================================================
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tarteel/core/helpers/arabic_search_helper.dart';
import '../lazy_data_loader.dart';
import 'generic_catalog_state.dart';

class GenericCatalogCubit<THeader, TDetail>
    extends Cubit<GenericCatalogState<THeader>> {
  final LazyDataLoader<THeader, TDetail> loader;
  final String Function(THeader item) titleExtractor;

  /// دالة اختيارية للمزامنة السحابية في الخلفية (مثل GitHub أو أي API)
  final Future<List<THeader>> Function()? remoteSyncer;

  GenericCatalogCubit({
    required this.loader,
    required this.titleExtractor,
    this.remoteSyncer,
    bool autoLoad = true,
  }) : super(GenericCatalogState<THeader>(isLoading: true)) {
    if (autoLoad) {
      loadCatalog();
    }
  }

  /// تحميل العناوين خفيفة الوزن بسرعة البرق ثم المزامنة السحابية في الخلفية
  Future<void> loadCatalog() async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      final items = await loader.loadHeaders();
      emit(state.copyWith(
        allItems: items,
        filteredItems: items,
        isLoading: false,
        searchQuery: '',
      ));

      // مزامنة هادئة في الخلفية من المصدر السحابي إن وجد
      if (remoteSyncer != null) {
        _syncInBackground();
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل القائمة: $e',
      ));
    }
  }

  /// مزامنة صامتة في الخلفية دون تعطيل واجهة المستخدم
  Future<void> _syncInBackground() async {
    if (remoteSyncer == null) return;
    try {
      final updatedItems = await remoteSyncer!();
      if (updatedItems.isNotEmpty) {
        final currentQuery = state.searchQuery;
        emit(state.copyWith(
          allItems: updatedItems,
          filteredItems: currentQuery.isEmpty
              ? updatedItems
              : _filterList(updatedItems, currentQuery),
        ));
      }
    } catch (_) {}
  }

  /// طلب المزامنة السحابية يدوياً وتحديث الواجهة فوراً (مثل عند السحب للتحديث أو Hot Reload)
  Future<void> syncRemote() async {
    await _syncInBackground();
  }

  List<THeader> _filterList(List<THeader> list, String query) {
    final normalizedQuery =
        ArabicSearchHelper.normalize(query.trim()).toLowerCase();
    return list.where((item) {
      final title = titleExtractor(item);
      final normalizedTitle =
          ArabicSearchHelper.normalize(title).toLowerCase();
      return normalizedTitle.contains(normalizedQuery);
    }).toList();
  }

  /// تصفية وبحث ذكي يدعم الكلمات العربية وتجريد التشكيل
  void search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(
        filteredItems: state.allItems,
        searchQuery: '',
      ));
      return;
    }

    final results = _filterList(state.allItems, trimmed);

    emit(state.copyWith(
      filteredItems: results,
      searchQuery: query,
    ));
  }

  /// مسح البحث
  void clearSearch() {
    emit(state.copyWith(
      filteredItems: state.allItems,
      searchQuery: '',
    ));
  }
}
