/// كلاس يمثل بيانات المؤذن (الاسم، المعرف، ومسار ملف الصوت)
class AdhanMuezzin {
  const AdhanMuezzin({
    required this.id,
    required this.name,
    required this.rawResourceName,
    required this.assetPath,
  });

  final String id; // المعرف الفريد للمؤذن (يستخدم في الإعدادات)
  final String name; // الاسم المعروض للمستخدم باللغة العربية
  final String rawResourceName; // اسم ملف الصوت بدون صيغة (للاستخدام في نظام أندرويد res/raw)
  final String assetPath; // مسار ملف الصوت في الأصول (للاستخدام داخل التطبيق)

  /// اسم ملف الصوت للأذان القصير (التكبيرات فقط) لنظام أندرويد
  String get shortRawResourceName => '${rawResourceName}_short';

  /// مسار ملف الصوت للأذان القصير في الأصول
  String get shortAssetPath {
    final lastDot = assetPath.lastIndexOf('.');
    if (lastDot == -1) return '${assetPath}_short';
    return '${assetPath.substring(0, lastDot)}_short${assetPath.substring(lastDot)}';
  }

  /// إرجاع اسم مورد الصوت المناسب لنظام أندرويد بحسب نمط الأذان (كامل أو قصير)
  String getRawResourceName({bool isShort = false}) =>
      isShort ? shortRawResourceName : rawResourceName;

  /// إرجاع مسار الأصل المناسب داخل التطبيق بحسب نمط الأذان (كامل أو قصير)
  String getAssetPath({bool isShort = false}) =>
      isShort ? shortAssetPath : assetPath;
}
