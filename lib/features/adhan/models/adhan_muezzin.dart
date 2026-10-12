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
}
