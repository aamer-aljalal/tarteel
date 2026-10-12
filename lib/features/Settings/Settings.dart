import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tarteel/core/providers/theme_provider.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticFeedback = true;
  String _themeMode = 'تلقائي';
  bool _notificationsAzkar = true;
  bool _notificationsFriday = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _themeMode = prefs.getString('theme_mode') ?? 'تلقائي';
      _notificationsAzkar = prefs.getBool('notifications_azkar') ?? true;
      _notificationsFriday = prefs.getBool('notifications_friday') ?? true;
    });
  }

  Future<void> _exportData() async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> backupData = {};
      for (final key in keys) {
        backupData[key] = prefs.get(key);
      }

      final String jsonStr = jsonEncode(backupData);
      await Share.share(jsonStr, subject: 'نسخة احتياطية من تطبيق ترتيل');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تصدير البيانات: $e',
              textAlign: TextAlign.right,
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showImportDialog() {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          'استيراد نسخة احتياطية',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'قم بلصق كود النسخة الاحتياطية الذي قمت بتصديره ومشاركته سابقاً في الحقل أدناه لاسترجاع كافة بياناتك وتفضيلاتك:',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12.0),
            TextField(
              controller: controller,
              maxLines: 5,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: '{...}',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.all(12.0),
              ),
              style: const TextStyle(fontSize: 12.0, fontFamily: 'monospace'),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final String text = controller.text.trim();
              if (text.isEmpty) return;

              try {
                final Map<String, dynamic> data = jsonDecode(text);
                final prefs = await SharedPreferences.getInstance();

                // Clear existing prefs
                await prefs.clear();

                // Restore each key
                for (final entry in data.entries) {
                  final key = entry.key;
                  final value = entry.value;
                  if (value is bool) {
                    await prefs.setBool(key, value);
                  } else if (value is int) {
                    await prefs.setInt(key, value);
                  } else if (value is double) {
                    await prefs.setDouble(key, value);
                  } else if (value is String) {
                    await prefs.setString(key, value);
                  } else if (value is List) {
                    await prefs.setStringList(key, List<String>.from(value));
                  }
                }

                // Re-initialize all schedules in background
                await GeneralNotificationService.scheduleAllEnabledNotifications();

                // Reload settings on screen
                await _loadSettings();

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم استيراد النسخة الاحتياطية وإعادة جدولة التنبيهات بنجاح!',
                      textAlign: TextAlign.right,
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'فشل الاستيراد: يرجى التأكد من صحة كود النسخة ($e)',
                      textAlign: TextAlign.right,
                    ),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('استيراد وتطبيق'),
          ),
        ],
      ),
    );
  }

  void _showResetWarningDialog() {
    if (_hapticFeedback) HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: const Text(
          'تنبيه هام! إعادة الضبط',
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد تماماً أنك تريد إعادة ضبط المصنع؟ سيؤدي هذا الإجراء إلى حذف جميع أذكارك المخصصة والمحفوظات نهائياً ولا يمكن التراجع عنه.',
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Reload settings on screen
              await _loadSettings();

              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'تمت إعادة ضبط المصنع بنجاح',
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('إعادة ضبط ومسح'),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() async {
    String nextTheme;
    if (_themeMode == 'تلقائي') {
      nextTheme = 'نهاري';
    } else if (_themeMode == 'نهاري') {
      nextTheme = 'ليلي';
    } else {
      nextTheme = 'تلقائي';
    }

    setState(() {
      _themeMode = nextTheme;
    });

    if (_hapticFeedback) HapticFeedback.lightImpact();

    if (mounted) {
      await Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).updateTheme(nextTheme);
    }
  }

  IconData _getThemeIcon() {
    if (_themeMode == 'نهاري') return Icons.wb_sunny_outlined;
    if (_themeMode == 'ليلي') return Icons.nights_stay_outlined;
    return Icons.settings_brightness_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const tarteelAppBar(titleText: 'الإعدادات', elevation: 0),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildSection(
              title: 'التفضيلات والتنبيهات',
              isDark: isDark,
              children: [
                _buildActionTile(
                  icon: _getThemeIcon(),
                  title: 'المظهر: $_themeMode',
                  color: isDark ? Colors.indigoAccent : Colors.orangeAccent,
                  onTap: _toggleTheme,
                ),
                const Divider(height: 1, indent: 50, endIndent: 16),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return _buildSwitchTile(
                      title: 'الخلفيات الإسلامية المزخرفة',
                      subtitle:
                          'إظهار نقوش إسلامية هادئة في الشاشات الرئيسية (الرئيسية، الأذكار، وحصن المسلم)',
                      value: themeProvider.isPatternBackgroundEnabled,
                      icon: Icons.auto_awesome_mosaic_outlined,
                      onChanged: (val) async {
                        if (_hapticFeedback) HapticFeedback.lightImpact();
                        await themeProvider.setPatternBackgroundEnabled(val);
                      },
                      iconColor: isDark
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF2E6F58),
                    );
                  },
                ),
                const Divider(height: 1, indent: 50, endIndent: 16),
                _buildSwitchTile(
                  title: 'الاهتزاز التفاعلي',
                  subtitle:
                      'اهتزاز خفيف للأزرار والعداد لتحسين تجربة الاستخدام',
                  value: _hapticFeedback,
                  icon: Icons.vibration_rounded,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('haptic_feedback', val);
                    setState(() {
                      _hapticFeedback = val;
                    });
                    if (val) HapticFeedback.mediumImpact();
                  },
                  iconColor: Colors.blueGrey,
                ),
                const Divider(height: 1, indent: 50, endIndent: 16),
                _buildSwitchTile(
                  title: 'تذكير أذكار الصباح والمساء',
                  subtitle: 'تنبيهات يومية لقراءة الأذكار المأثورة في أوقاتها',
                  value: _notificationsAzkar,
                  icon: Icons.spa_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_azkar', val);
                    setState(() {
                      _notificationsAzkar = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.amber.shade700,
                ),
                const Divider(height: 1, indent: 50, endIndent: 16),
                _buildSwitchTile(
                  title: 'تنبيهات يوم الجمعة',
                  subtitle: 'تذكير بقراءة سورة الكهف والصلاة على النبي ﷺ',
                  value: _notificationsFriday,
                  icon: Icons.mosque_outlined,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_friday', val);
                    setState(() {
                      _notificationsFriday = val;
                    });
                    await GeneralNotificationService.scheduleAllEnabledNotifications();
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                  },
                  iconColor: Colors.green.shade700,
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            _buildSection(
              title: 'النسخ الاحتياطي والصيانة',
              isDark: isDark,
              children: [
                _buildActionTile(
                  icon: Icons.upload_file_outlined,
                  title: 'تصدير البيانات والمحفوظات',
                  color: Colors.blue.shade700,
                  onTap: _exportData,
                ),
                const Divider(height: 1, indent: 50, endIndent: 16),
                _buildActionTile(
                  icon: Icons.download_outlined,
                  title: 'استيراد البيانات والمحفوظات',
                  color: AppColors.primary,
                  onTap: _showImportDialog,
                ),
                const Divider(height: 1, indent: 50, endIndent: 16),
                _buildActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'إعادة ضبط المصنع',
                  color: Colors.red.shade700,
                  onTap: _showResetWarningDialog,
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Premium Caution Box
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.red.shade700.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'تنبيه: عملية إعادة ضبط المصنع ستقوم بمسح كامل للإعدادات المخزنة محلياً على جهازك بشكل دائم ولا يمكن استردادها.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // App Info Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
                      : [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mosque_outlined,
                      size: 28.0,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'تطبيق ترتيل الإسلامي',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'نسأل الله أن يتقبل منا ومنكم صالح الأعمال، وأن يجعل هذا العمل خالصاً لوجهه الكريم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.0,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              right: 16.0,
              left: 16.0,
              top: 12.0,
              bottom: 4.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 3.0,
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.0,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 14.0,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
