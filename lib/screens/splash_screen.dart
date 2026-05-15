import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/backends.dart';

/// アプリ起動時に表示されるスプラッシュ画面。QRスキャン開始とバックエンド選択を提供する。
class SplashScreen extends StatefulWidget {
  /// QRスキャン開始ボタン押下時のコールバック。
  final VoidCallback onStart;

  /// 現在選択中のバックエンド。
  final BackendOption selectedBackend;

  /// バックエンド変更時のコールバック。
  final Future<void> Function(BackendOption) onSelectBackend;

  const SplashScreen({
    super.key,
    required this.onStart,
    required this.selectedBackend,
    required this.onSelectBackend,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F46E5), Color(0xFF9333EA), Color(0xFF6B21A8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // バックエンド選択
              Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Backend:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<BackendOption>(
                      value: widget.selectedBackend,
                      dropdownColor: const Color(0xFF4F46E5),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      iconEnabledColor: Colors.white70,
                      underline: Container(height: 1, color: Colors.white38),
                      items: kBackends
                          .map(
                            (b) =>
                                DropdownMenuItem(value: b, child: Text(b.name)),
                          )
                          .toList(),
                      onChanged: (b) {
                        if (b != null) widget.onSelectBackend(b);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                            animation: _floatAnimation,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: SvgPicture.asset(
                                'assets/icon.svg',
                                width: 128,
                                height: 128,
                              ),
                            ),
                          )
                          .animate()
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.easeOut,
                          )
                          .fade(duration: 500.ms),
                      const SizedBox(height: 24),
                      Text(
                            'Authorization Gateway',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  defaultTargetPlatform ==
                                      TargetPlatform.android
                                  ? 22
                                  : 28,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none,
                            ),
                          )
                          .animate()
                          .fade(duration: 500.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
              SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('QRコードをスキャン'),
                    ),
                  )
                  .animate()
                  .fade(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
