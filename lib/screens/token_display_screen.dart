import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

class TokenDisplayScreen extends StatefulWidget {
  final String token;
  final String clientName;
  final VoidCallback onClose;

  const TokenDisplayScreen({
    super.key,
    required this.token,
    required this.clientName,
    required this.onClose,
  });

  @override
  State<TokenDisplayScreen> createState() => _TokenDisplayScreenState();
}

class _TokenDisplayScreenState extends State<TokenDisplayScreen> {
  bool _copied = false;
  bool _showConfirmDialog = false;

  void _handleCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.token));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _handleShare() async {
    final size = MediaQuery.of(context).size;
    await SharePlus.instance.share(
      ShareParams(
        text: widget.token,
        title: 'シェア',
        subject: 'アクセストークンをシェア',
        sharePositionOrigin: Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 1,
          height: 1,
        ),
      ),
    );
  }

  void _handleClose() {
    setState(() => _showConfirmDialog = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ヘッダー
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'アクセストークン発行',
                        style: TextStyle(fontSize: 18),
                      ),
                      IconButton(
                        onPressed: _handleClose,
                        icon: const Icon(Icons.close, size: 22),
                        style: IconButton.styleFrom(
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                // コンテンツ
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // アクティベーション完了
                        _Banner(
                          icon: Icons.check,
                          iconColor: const Color(0xFF16A34A),
                          backgroundColor: const Color(0xFFF0FDF4),
                          borderColor: const Color(0xFFBBF7D0),
                          title: '利用開始しました。',
                          subtitle: '',
                          titleColor: const Color(0xFF14532D),
                          subtitleColor: const Color(0xFF15803D),
                        ),
                        const SizedBox(height: 16),
                        // 重要な警告
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFDC2626),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      '重要な警告',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF7F1D1D),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'このトークンは一度きりの表示です。この画面を閉じると二度と表示できません。',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF991B1B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // トークンカード
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9FAFB),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'アクセストークン',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF111827),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.token,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Color(0xFF4ADE80),
                                          height: 1.6,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _handleCopy,
                                            icon: Icon(
                                              _copied
                                                  ? Icons.check
                                                  : Icons.copy,
                                              size: 20,
                                            ),
                                            label: Text(
                                              _copied ? 'コピー済み' : 'コピー',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF4F46E5,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _handleShare,
                                            icon: const Icon(
                                              Icons.share,
                                              size: 20,
                                            ),
                                            label: const Text('シェア'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF374151,
                                              ),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 保存方法の推奨
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '推奨される保存方法:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A5F),
                                ),
                              ),
                              SizedBox(height: 8),
                              _BulletItem('パスワードマネージャーに保存'),
                              _BulletItem('Slack等のセキュアなチャンネルで送信'),
                              _BulletItem('暗号化されたノートアプリに保存'),
                            ],
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1, 1),
                          duration: 300.ms,
                        )
                        .fade(duration: 300.ms),
                  ),
                ),
                // フッターボタン
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF374151),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('この画面を閉じる'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 確認ダイアログ
          if (_showConfirmDialog)
            _ConfirmCloseDialog(
              onCancel: () => setState(() => _showConfirmDialog = false),
              onConfirm: () {
                setState(() => _showConfirmDialog = false);
                widget.onClose();
              },
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;

  const _Banner({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: titleColor,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: subtitleColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmCloseDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ConfirmCloseDialog({
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '画面を閉じますか？',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'トークンを保存しましたか？この画面を閉じると二度と表示できません。',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide.none,
                            backgroundColor: const Color(0xFFF3F4F6),
                            foregroundColor: const Color(0xFF374151),
                          ),
                          child: const Text('キャンセル'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('閉じる'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                )
                .fade(duration: 200.ms),
          ),
        ),
      )
          .animate()
          .fade(duration: 150.ms),
    );
  }
}
