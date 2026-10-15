import 'package:tarteel/Model/AccessListModel.dart';
import 'package:tarteel/core/services/lazy_loader/cubit/generic_catalog_cubit.dart';
import 'package:tarteel/features/hisn_almuslim/model/hisn_category.dart';
import 'package:tarteel/features/hisn_almuslim/services/hisn_service.dart';

/// النوع المعرّف لكوبيت حصن المسلم باستخدام المحرك العام
typedef HisnCatalogCubit = GenericCatalogCubit<AccessListModel, HisnCategory>;

/// مصنع لإنشاء كيوبت حصن المسلم العام بسطر واحد
class HisnCubitFactory {
  static HisnCatalogCubit create() {
    return GenericCatalogCubit<AccessListModel, HisnCategory>(
      loader: HisnService(),
      titleExtractor: (item) => item.title,
    );
  }
}
