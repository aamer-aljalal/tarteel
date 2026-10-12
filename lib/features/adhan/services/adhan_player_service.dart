import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'adhan_notification_service.dart';

class AdhanPlayerService {
  static final AdhanPlayerService _instance = AdhanPlayerService._internal();
  factory AdhanPlayerService() => _instance;
  AdhanPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isMuted = false;
  String _activePrayerName = '';

  AudioPlayer get player => _player;
  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  String get activePrayerName => _activePrayerName;

  void Function(String prayerName)? onAdhanStarted;
  void Function()? onAdhanStopped;

  Future<void> playAdhan(String prayerName) async {
    if (_isPlaying) return;

    _activePrayerName = prayerName;
    final muezzin = await AdhanNotificationService.selectedMuezzin();

    try {
      await _player.setAsset(muezzin.assetPath);
      await _player.setVolume(_isMuted ? 0.0 : 1.0);
      _isPlaying = true;

      if (onAdhanStarted != null) {
        onAdhanStarted!(prayerName);
      }

      _player.play();

      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          stopAdhan();
        }
      });
    } catch (e) {
      debugPrint('Error playing Adhan in app: $e');
      _isPlaying = false;
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _player.setVolume(_isMuted ? 0.0 : 1.0);
  }

  void stopAdhan() {
    _player.stop();
    _isPlaying = false;
    _activePrayerName = '';
    if (onAdhanStopped != null) {
      onAdhanStopped!();
    }
  }
}

class AdhanOverlayWrapper extends StatefulWidget {
  final Widget child;
  const AdhanOverlayWrapper({super.key, required this.child});

  @override
  State<AdhanOverlayWrapper> createState() => _AdhanOverlayWrapperState();
}

class _AdhanOverlayWrapperState extends State<AdhanOverlayWrapper> {
  bool _showOverlay = false;
  String _prayerName = '';
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    final service = AdhanPlayerService();

    service.onAdhanStarted = (prayerName) {
      if (mounted) {
        setState(() {
          _showOverlay = true;
          _prayerName = prayerName;
          _isMuted = service.isMuted;
        });
      }
    };

    service.onAdhanStopped = () {
      if (mounted) {
        setState(() {
          _showOverlay = false;
        });
      }
    };

    if (service.isPlaying) {
      _showOverlay = true;
      _prayerName = service.activePrayerName;
      _isMuted = service.isMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          widget.child,
          if (_showOverlay)
            Positioned.fill(
              child: AdhanPlayingScreen(
                prayerName: _prayerName,
                isMuted: _isMuted,
                onMuteToggle: () {
                  final service = AdhanPlayerService();
                  service.toggleMute();
                  setState(() {
                    _isMuted = service.isMuted;
                  });
                },
                onClose: () {
                  AdhanPlayerService().stopAdhan();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class AdhanPlayingScreen extends StatefulWidget {
  final String prayerName;
  final bool isMuted;
  final VoidCallback onMuteToggle;
  final VoidCallback onClose;

  const AdhanPlayingScreen({
    super.key,
    required this.prayerName,
    required this.isMuted,
    required this.onMuteToggle,
    required this.onClose,
  });

  @override
  State<AdhanPlayingScreen> createState() => _AdhanPlayingScreenState();
}

class _AdhanPlayingScreenState extends State<AdhanPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section: Title & Subtitle
              Column(
                children: [
                  Container(
                    width: 50.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Text(
                    'حان الآن موعد الأذان',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.goldAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'نداء لصلاة ${widget.prayerName}',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Center Section: Pulsing Sound Wave Animation & Mosque Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        final progress =
                            (_rippleController.value + index / 3) % 1.0;
                        return Container(
                          width: (120 + progress * 140).w,
                          height: (120 + progress * 140).h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.goldAccent.withValues(
                                alpha: (1.0 - progress) * 0.4,
                              ),
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  Container(
                    width: 140.w,
                    height: 140.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.9),
                      border: Border.all(color: AppColors.goldAccent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.mosque_rounded,
                        size: 64.sp,
                        color: AppColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Section: Audio controls
              Column(
                children: [
                  Text(
                    'عش عظمة النداء بروحانية وسكينة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 40.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute / Unmute Button
                      _buildControlButton(
                        icon: widget.isMuted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        label: widget.isMuted ? 'تشغيل الصوت' : 'كتم الصوت',
                        color: widget.isMuted
                            ? Colors.grey
                            : AppColors.goldAccent,
                        onPressed: widget.onMuteToggle,
                      ),
                      // Stop / Close Button
                      _buildControlButton(
                        icon: Icons.close_rounded,
                        label: 'إيقاف الأذان',
                        color: Colors.red.shade600,
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 70.w,
            height: 70.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Icon(icon, color: color, size: 30.sp),
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
