import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_cubit.dart';
import 'package:tarteel/features/azkar/model/zekr_category.dart';
import 'package:tarteel/features/azkar/services/azkar_service.dart';

/// النوع المعرّف (Type Alias) لكوبيت الأذكار باستخدام المحرك العام
typedef AzkarCatalogCubit = GenericCatalogCubit<AccessListModel, ZekrCategory>;

/// مصنع لإنشاء كيوبت الأذكار العام بسطر واحد
class AzkarCubitFactory {
  static AzkarCatalogCubit create() {
    return GenericCatalogCubit<AccessListModel, ZekrCategory>(
      loader: AzkarService(),
      titleExtractor: (item) => item.title,
    );
  }
}
