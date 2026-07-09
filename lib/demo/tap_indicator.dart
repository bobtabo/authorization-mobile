// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/material.dart';

/// デモ録画時のみ有効化するフラグ（`--dart-define=DEMO_TAP_INDICATOR=true`）。
///
/// integration_test の `tester.tap()` は瞬時に処理され、実カーソルも存在しない
/// ため、録画だけを見ると画面が勝手に動いているように見える。このフラグを
/// 有効にすると、タップした座標に波紋アニメーションを表示してから実際に
/// タップするようになり、操作箇所が視覚的にわかるようになる。
/// 本番ビルドでは既定 `false` のため、実際の画面表示には一切影響しない。
const bool kDemoTapIndicator = bool.fromEnvironment('DEMO_TAP_INDICATOR');

/// integration_test からタップ位置を通知するためのコントローラー。
///
/// integration_test はアプリと同じ Dart isolate 内で動作するため、テスト側から
/// このコントローラーへ直接 [show] を呼ぶだけでオーバーレイに伝わる。
class DemoTapIndicatorController extends ChangeNotifier {
  Offset? _position;
  int _seq = 0;

  /// 直近の波紋アニメーションの識別子（同じ座標に連続でタップしても
  /// アニメーションを最初からやり直すために使う）。
  int get seq => _seq;

  /// 直近に通知されたタップ座標。
  Offset? get position => _position;

  /// [position] にタップが発生したことを通知し、波紋アニメーションを再生する。
  void show(Offset position) {
    _position = position;
    _seq++;
    notifyListeners();
  }
}

/// アプリ全体で共有するタップ表示用コントローラー。
final demoTapIndicatorController = DemoTapIndicatorController();

/// [child] の上にタップ位置を示す波紋アニメーションを重ねて表示するラッパー。
///
/// [kDemoTapIndicator] が `false`（本番ビルドの既定値）の場合は [child] を
/// そのまま返すだけで、オーバーレイは一切構築されない。
class DemoTapIndicatorOverlay extends StatelessWidget {
  final Widget child;

  const DemoTapIndicatorOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kDemoTapIndicator) return child;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: demoTapIndicatorController,
              builder: (context, _) {
                final position = demoTapIndicatorController.position;
                if (position == null) return const SizedBox.shrink();
                return _TapRipple(
                  key: ValueKey(demoTapIndicatorController.seq),
                  position: position,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// タップ座標に一度だけ再生される波紋アニメーション。
class _TapRipple extends StatefulWidget {
  final Offset position;

  const _TapRipple({required super.key, required this.position});

  @override
  State<_TapRipple> createState() => _TapRippleState();
}

class _TapRippleState extends State<_TapRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dotSize = 28.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        // 中心の丸: 最初にパッと現れてすぐ縮む（タップされた瞬間感を出す）。
        final dotScale = t < 0.25 ? 1.0 : (1.0 - (t - 0.25) / 0.75 * 0.4);
        final dotOpacity = (1.0 - t).clamp(0.0, 1.0);
        // 外側のリング: 拡大しながらフェードアウトする波紋。
        final ringScale = 0.6 + t * 2.2;
        final ringOpacity = (1.0 - t).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned(
              left: widget.position.dx - dotSize / 2,
              top: widget.position.dy - dotSize / 2,
              child: Opacity(
                opacity: ringOpacity,
                child: Transform.scale(
                  scale: ringScale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: widget.position.dx - dotSize / 2,
              top: widget.position.dy - dotSize / 2,
              child: Opacity(
                opacity: dotOpacity,
                child: Transform.scale(
                  scale: dotScale,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.55),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
