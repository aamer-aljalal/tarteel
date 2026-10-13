/// ==============================================================================
/// 📌 وصف الملف: dynamic_page_screen.dart
/// ==============================================================================
/// شاشة القالب الديناميكي العام لتطبيق ترتيل.
///
/// 🔄 كيف تعمل هذه الشاشة؟
/// 1. تستقبل رابط ملف JSON من GitHub (أو بيانات محلية) عبر arguments.
/// 2. تقوم بجلب البيانات وتحفظها محلياً (Offline First) لتعمل حتى دون إنترنت.
/// 3. تقرأ مصفوفة المكونات ("components") وتستدعي DynamicComponentParser
///    لبناء كل عنصر وتنسيقه فوراً.
/// 4. تدعم التفاعل الذكي مع الأزرار (إجابة صحيحة، إجابة خاطئة، رسائل تنبيهية، انتقال).
/// ==============================================================================
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/github_sync_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/core/widgets/backgrounds/islamic_pattern_background.dart';
import 'package:tarteel/core/widgets/dynamic/dynamic_component_parser.dart';

class DynamicPageScreen extends StatefulWidget {
  final String? url;
  final Map<String, dynamic>? initialData;
  final String? title;

  const DynamicPageScreen({
    super.key,
    this.url,
    this.initialData,
    this.title,
  });

  @override
  State<DynamicPageScreen> createState() => _DynamicPageScreenState();
}

class _DynamicPageScreenState extends State<DynamicPageScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _pageData;

  String get _pageTitle =>
      _pageData?['pageTitle'] as String? ??
      _pageData?['title'] as String? ??
      widget.title ??
      'صفحة جديدة';

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  // ============================================================================
  // 📥 تحميل بيانات الصفحة (من الذاكرة أولاً ثم التحديث من الإنترنت)
  // ============================================================================
  Future<void> _loadPage() async {
    // 1. إذا تم تمرير بيانات مباشرة
    if (widget.initialData != null) {
      setState(() {
        _pageData = widget.initialData;
        _isLoading = false;
      });
      return;
    }

    final targetUrl = widget.url;
    if (targetUrl == null || targetUrl.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'لم يتم تحديد رابط لبيانات الصفحة';
      });
      return;
    }

    // 2. فحص الكاش المحلي في الهاتف أولاً لتعمل فوراً دون انتظار
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'dynamic_page_cache_${targetUrl.hashCode}';
      final cachedJson = prefs.getString(cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        setState(() {
          _pageData = json.decode(cachedJson);
          _isLoading = false;
        });
      }
    } catch (_) {}

    // 3. جلب أحدث نسخة من GitHub في الخلفية
    try {
      final remoteData = await GithubSyncService.fetchJsonMap(targetUrl);
      if (remoteData != null && mounted) {
        setState(() {
          _pageData = remoteData;
          _isLoading = false;
          _errorMessage = null;
        });

        // حفظ النسخة في الذاكرة للعمل أوفلاين
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'dynamic_page_cache_${targetUrl.hashCode}';
        await prefs.setString(cacheKey, json.encode(remoteData));
      } else if (_pageData == null && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر الاتصال لتحميل الصفحة، يرجى التحقق من الإنترنت';
        });
      }
    } catch (e) {
      if (_pageData == null && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل الصفحة: $e';
        });
      }
    }
  }

  // ============================================================================
  // 🎯 التعامل مع الأحداث التفاعلية للأزرار (المسابقات، الإجابات، التنبيهات)
  // ============================================================================
  void _handleAction(String action, dynamic value) {
    switch (action.toLowerCase().trim()) {
      // إجابة صحيحة في مسابقة
      case 'check_correct':
      case 'correct':
        HapticFeedback.heavyImpact();
        _showFeedbackDialog(
          title: 'إجابة صحيحة! أحسنت 🌟',
          message: value is String ? value : 'بارك الله فيك، إجابتك موفقة وصحيحة.',
          isSuccess: true,
        );
        break;

      // إجابة خاطئة في مسابقة
      case 'check_wrong':
      case 'wrong':
        HapticFeedback.mediumImpact();
        _showFeedbackDialog(
          title: 'إجابة خاطئة ❌',
          message: value is String ? value : 'حاول مرة أخرى وركز في السؤال.',
          isSuccess: false,
        );
        break;

      // رسالة تنبيهية سريعة
      case 'message':
      case 'toast':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value?.toString() ?? '',
              textAlign: TextAlign.right,
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        break;

      // فتح مسار آخر داخل التطبيق
      case 'navigate':
        if (value is String && value.isNotEmpty) {
          Navigator.pushNamed(context, value);
        }
        break;

      default:
        break;
    }
  }

  void _showFeedbackDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isSuccess ? Colors.green : Colors.redAccent,
              size: 28.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: tarteelAppBar(
        titleText: _pageTitle,
        elevation: 0,
        toolbarHeight: 90,
      ),
      body: IslamicPatternBackground(
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 54.sp, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadPage();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final components = (_pageData?['components'] as List<dynamic>?) ?? [];

    if (components.isEmpty) {
      return Center(
        child: Text(
          'لا توجد عناصر لعرضها في هذه الصفحة',
          style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo', color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: components.map((comp) {
          if (comp is! Map<String, dynamic>) return const SizedBox.shrink();
          return DynamicComponentParser.buildComponent(
            context: context,
            json: comp,
            onActionTriggered: _handleAction,
          );
        }).toList(),
      ),
    );
  }
}
