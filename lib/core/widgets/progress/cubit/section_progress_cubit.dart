/// ==============================================================================
///  وصف الملف: section_progress_cubit.dart
/// ==============================================================================
/// العقل المنطقي لحساب وتحديث نسبة التقدم بشريط القسم بنمط Cubit.
/// يحتوي على كافة العمليات الحسابية بدون الحاجة لكتابتها في الواجهات.
/// ==============================================================================
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'section_progress_state.dart';

class SectionProgressCubit extends Cubit<SectionProgressState> {
  SectionProgressCubit({int currentIndex = 0, int totalCount = 1})
      : super(SectionProgressState.initial(
          currentIndex: currentIndex,
          totalCount: totalCount,
        ));

  /// تحديث موقع التقدم الحالي وإعادة احتساب النسبة تلقائياً
  void updateProgress({required int currentIndex, int? totalCount}) {
    final validTotal = (totalCount ?? state.totalCount) > 0
        ? (totalCount ?? state.totalCount)
        : 1;
    final validCurrent = currentIndex.clamp(0, validTotal);
    final calculatedProgress = (validCurrent / validTotal).clamp(0.0, 1.0);
    final calculatedPercentage = (calculatedProgress * 100).round();

    emit(SectionProgressState(
      currentIndex: validCurrent,
      totalCount: validTotal,
      progress: calculatedProgress,
      percentage: calculatedPercentage,
    ));
  }

  /// التقدم خطوة واحدة للأمام
  void next() {
    if (state.currentIndex < state.totalCount) {
      updateProgress(currentIndex: state.currentIndex + 1);
    }
  }

  /// التراجع خطوة واحدة للخلف
  void previous() {
    if (state.currentIndex > 0) {
      updateProgress(currentIndex: state.currentIndex - 1);
    }
  }

  /// إعادة تعيين التقدم للصفر
  void reset() {
    updateProgress(currentIndex: 0);
  }
}
