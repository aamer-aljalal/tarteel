import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/bottom_sheets/custom_grid_bottom_sheet.dart';
import 'package:tarteel/core/widgets/cards/action_grid_card.dart';

class MuezzinSelectionSheet extends StatefulWidget {
  final AdhanMuezzin selectedMuezzin;
  final bool isTestingAdhan;
  final VoidCallback onStopTesting;
  final Function(AdhanMuezzin) onMuezzinSelected;

  const MuezzinSelectionSheet({
    super.key,
    required this.selectedMuezzin,
    required this.isTestingAdhan,
    required this.onStopTesting,
    required this.onMuezzinSelected,
  });

  @override
  State<MuezzinSelectionSheet> createState() => _MuezzinSelectionSheetState();
}

class _MuezzinSelectionSheetState extends State<MuezzinSelectionSheet> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingMuezzinId;
  bool _isSaving = false;
  late AdhanMuezzin _currentSelectedMuezzin;

  @override
  void initState() {
    super.initState();
    _currentSelectedMuezzin = widget.selectedMuezzin;
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingMuezzinId = null);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePreview(AdhanMuezzin muezzin) async {
    if (widget.isTestingAdhan) {
      widget.onStopTesting();
    }

    if (_playingMuezzinId == muezzin.id) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      return;
    }

    setState(() => _playingMuezzinId = muezzin.id);
    try {
      await _player.stop();
      await _player.setAsset(muezzin.assetPath);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تشغيل صوت المؤذن')));
    }
  }

  Future<void> _selectMuezzin(AdhanMuezzin muezzin) async {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentSelectedMuezzin = muezzin;
      _isSaving = true;
    });

    if (widget.isTestingAdhan) {
      widget.onStopTesting();
    }

    await AdhanNotificationService.setSelectedMuezzin(muezzin);

    if (!mounted) return;
    
    // إخفاء مؤشر التحميل وتحديث الواجهة فوراً
    setState(() => _isSaving = false);
    widget.onMuezzinSelected(muezzin);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم اختيار ${muezzin.name} للأذان')));

    // الجدولة في الخلفية بعد جزء من الثانية لكي لا يحدث أي تقطيع في واجهة المستخدم (Smooth UI)
    final provider = context.read<PrayerProvider>();
    Future.delayed(const Duration(milliseconds: 300), () {
      provider.scheduleAdhanNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomGridBottomSheet(
      title: 'اختر صوت المؤذن للأذان',
      subtitle:
          'اضغط على البطاقة للاستماع والتجربة، واضغط على (تفعيل) للاختيار.',
      heightFraction: 0.65,
      crossAxisCount: 3,
      childAspectRatio: 1.0,
      itemCount: AdhanNotificationService.muezzins.length,
      itemBuilder: (context, index) {
        final muezzin = AdhanNotificationService.muezzins[index];
        final isSelected = _currentSelectedMuezzin.id == muezzin.id;
        final isPlaying = _playingMuezzinId == muezzin.id;
        final isSavingThis = _isSaving && isSelected;

        // تجهيز الودجت السفلية للمربع (الزر أو مؤشر التحميل)
        Widget actionWidget;
        if (isSavingThis) {
          actionWidget = SizedBox(
            width: 12.w,
            height: 12.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        } else {
          actionWidget = GestureDetector(
            onTap: isSelected ? null : () => _selectMuezzin(muezzin),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                isSelected ? 'مختار' : 'تفعيل',
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          );
        }

        return ActionGridCard(
          title: muezzin.name,
          icon: isPlaying
              ? Icons.stop_rounded
              : (isSelected ? Icons.check_circle : Icons.person_outline),
          activeColor: AppColors.primary,
          isActive: isSelected,
          isErrorState: isPlaying,
          onTap: () => _togglePreview(muezzin),
          actionWidget: actionWidget,
        );
      },
    );
  }
}
