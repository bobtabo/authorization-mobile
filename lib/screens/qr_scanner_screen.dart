import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  final ValueChanged<String> onScan;
  final VoidCallback onBack;

  const QRScannerScreen({super.key, required this.onScan, required this.onBack});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _flashOn = false;
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _controller.toggleTorch();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      _scanned = true;
      widget.onScan(barcode!.rawValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const Text(
                    'QRコードスキャン',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    onPressed: _toggleFlash,
                    icon: Icon(
                      _flashOn ? Icons.flashlight_on : Icons.flashlight_off,
                      color: _flashOn ? Colors.yellow[400] : Colors.white,
                      size: 26,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white10,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: MobileScanner(
                            controller: _controller,
                            onDetect: _onDetect,
                            errorBuilder: (context, error, child) =>
                                _SimulatorFallback(onScan: widget.onScan),
                          ),
                        ),
                      ),
                      // 外枠（点滅）
                      Positioned.fill(
                        child: _PulsingBorder(),
                      ),
                      // コーナーマーカー
                      Positioned.fill(
                        child: _ScannerCorners(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  const Text(
                    '管理画面に表示された\nQRコードを読み取ってください',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ]
                    .animate()
                    .fade(delay: 300.ms, duration: 400.ms),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SimulatorFallback extends StatelessWidget {
  final ValueChanged<String> onScan;

  const _SimulatorFallback({required this.onScan});

  void _simulateScan(BuildContext context) {
    final controller = TextEditingController(
      text: 'https://apis.authorization-php.dev/activate?client_id=client_test_001',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QRスキャン（シミュレーター）'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'QRコードの値'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onScan(controller.text.trim());
            },
            child: const Text('スキャン'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            const Text(
              'カメラが利用できません',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _simulateScan(context),
                icon: const Icon(Icons.qr_code),
                label: const Text('テストスキャン'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PulsingBorder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30, width: 4),
        borderRadius: BorderRadius.circular(24),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.3, end: 1.0, duration: 1000.ms);
  }
}

class _ScannerCorners extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // スキャンエリア（内側の青枠）
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.8,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6), width: 4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
