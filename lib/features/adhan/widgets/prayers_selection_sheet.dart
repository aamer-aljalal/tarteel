import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/widgets/bottom_sheets/custom_grid_bottom_sheet.dart';
import 'package:tarteel/core/widgets/cards/action_grid_card.dart';

class PrayersSelectionSheet extends StatefulWidget {
  final bool fajrEnabled;
  final bool dhuhrEnabled;
  final bool asrEnabled;
  final bool maghribEnabled;
  final bool ishaEnabled;
  final Function(Prayer, bool) onPrayerToggled;

  const PrayersSelectionSheet({
    super.key,
    required this.fajrEnabled,
    required this.dhuhrEnabled,
    required this.asrEnabled,
    required this.maghribEnabled,
    required this.ishaEnabled,
    required this.onPrayerToggled,
  });

  @override
  State<PrayersSelectionSheet> createState() => _PrayersSelectionSheetState();
}

class _PrayersSelectionSheetState extends State<PrayersSelectionSheet> {
  late bool _fajrEnabled;
  late bool _dhuhrEnabled;
  late bool _asrEnabled;
  late bool _maghribEnabled;
  late bool _ishaEnabled;

  @override
  void initState() {
    super.initState();
    _fajrEnabled = widget.fajrEnabled;
    _dhuhrEnabled = widget.dhuhrEnabled;
    _asrEnabled = widget.asrEnabled;
    _maghribEnabled = widget.maghribEnabled;
    _ishaEnabled = widget.ishaEnabled;
  }

  Future<void> _updatePrayerAdhanEnabled(Prayer prayer, bool enabled) async {
    HapticFeedback.lightImpact();

    setState(() {
      switch (prayer) {
        case Prayer.fajr:
          _fajrEnabled = enabled;
          break;
        case Prayer.dhuhr:
          _dhuhrEnabled = enabled;
          break;
        case Prayer.asr:
          _asrEnabled = enabled;
          break;
        case Prayer.maghrib:
          _maghribEnabled = enabled;
          break;
        case Prayer.isha:
          _ishaEnabled = enabled;
          break;
        default:
          break;
      }
    });

    await AdhanNotificationService.setSinglePrayerAdhanEnabled(prayer, enabled);
    
    if (mounted) {
      widget.onPrayerToggled(prayer, enabled);
      
      // الجدولة في الخلفية لمنع تجميد زر التفعيل (Switch)
      final prayerProvider = context.read<PrayerProvider>();
      Future.delayed(const Duration(milliseconds: 300), () {
        prayerProvider.scheduleAdhanNotifications();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> prayersData = [
      {
        'prayer': Prayer.fajr,
        'title': 'صلاة الفجر',
        'icon': Icons.wb_twilight,
        'color': Colors.amber.shade800,
        'enabled': _fajrEnabled,
      },
      {
        'prayer': Prayer.dhuhr,
        'title': 'صلاة الظهر',
        'icon': Icons.wb_sunny,
        'color': Colors.orange.shade700,
        'enabled': _dhuhrEnabled,
      },
      {
        'prayer': Prayer.asr,
        'title': 'صلاة العصر',
        'icon': Icons.wb_sunny_outlined,
        'color': Colors.deepOrange,
        'enabled': _asrEnabled,
      },
      {
        'prayer': Prayer.maghrib,
        'title': 'صلاة المغرب',
        'icon': Icons.wb_twilight_outlined,
        'color': Colors.indigo,
        'enabled': _maghribEnabled,
      },
      {
        'prayer': Prayer.isha,
        'title': 'صلاة العشاء',
        'icon': Icons.nights_stay_outlined,
        'color': Colors.blueGrey,
        'enabled': _ishaEnabled,
      },
    ];

    return CustomGridBottomSheet(
      title: 'تخصيص الأذان لكل صلاة',
      subtitle: 'اضغط على البطاقة لتفعيل أو إيقاف الأذان لهذه الصلاة.',
      heightFraction: 0.60,
      crossAxisCount: 3, 
      childAspectRatio: 1.0, 
      itemCount: prayersData.length,
      itemBuilder: (context, index) {
        final data = prayersData[index];
        final prayer = data['prayer'] as Prayer;
        final title = data['title'] as String;
        final icon = data['icon'] as IconData;
        final color = data['color'] as Color;
        final isEnabled = data['enabled'] as bool;

        // تجهيز مفتاح التفعيل (Switch)
        final actionWidget = Transform.scale(
          scale: 0.55, 
          child: Switch.adaptive(
            value: isEnabled,
            onChanged: (val) => _updatePrayerAdhanEnabled(prayer, val),
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
          ),
        );

        return ActionGridCard(
          title: title,
          icon: icon,
          activeColor: color,
          isActive: isEnabled,
          onTap: () => _updatePrayerAdhanEnabled(prayer, !isEnabled),
          actionWidget: actionWidget,
        );
      },
    );
  }
}
