import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/client_info.dart';

/// QRスキャン後にクライアント情報を確認して利用開始するための画面。
class ActivationConfirmScreen extends StatelessWidget {
  /// 確認対象のクライアント情報。
  final ClientInfo clientInfo;

  /// 利用開始ボタン押下時のコールバック。
  final VoidCallback onActivate;

  /// 戻るボタン押下時のコールバック。
  final VoidCallback onBack;

  const ActivationConfirmScreen({
    super.key,
    required this.clientInfo,
    required this.onActivate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 22),
                    style: IconButton.styleFrom(shape: const CircleBorder()),
                  ),
                  const Text('利用開始の確認', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            // コンテンツ
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QR読み取り成功バナー
                    _InfoBanner(
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF2563EB),
                      backgroundColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFFBFDBFE),
                      title: 'QRコードを読み取りました',
                      subtitle: '',
                      titleColor: const Color(0xFF1E3A5F),
                      subtitleColor: const Color(0xFF1D4ED8),
                    ),
                    const SizedBox(height: 24),
                    // クライアント情報カード
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
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.business,
                              label: 'クライアント名',
                              value: clientInfo.name,
                            ),
                            const Divider(height: 32, color: Color(0xFFF3F4F6)),
                            _InfoRow(
                              icon: Icons.label_outline,
                              label: '識別名',
                              value: clientInfo.identifier,
                              mono: true,
                            ),
                            const Divider(height: 32, color: Color(0xFFF3F4F6)),
                            _InfoRow(
                              icon: Icons.mail_outline,
                              label: 'メールアドレス',
                              value: clientInfo.email,
                            ),
                            const Divider(height: 32, color: Color(0xFFF3F4F6)),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '現在のステータス',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      border: Border.all(
                                        color: const Color(0xFFFCD34D),
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          clientInfo.status.label,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF78350F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 注意書き
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF78350F),
                          ),
                          children: [
                            TextSpan(
                              text: '注意：',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            TextSpan(
                              text:
                                  '利用開始すると、アクセストークンが発行されます。トークンは一度だけ表示されますので、必ず安全な場所に保管してください。',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(duration: 300.ms).slideY(begin: 0.2, end: 0),
              ),
            ),
            // フッターボタン
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child:
                  SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onActivate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: const Text('利用開始する'),
                        ),
                      )
                      .animate()
                      .fade(delay: 200.ms, duration: 300.ms)
                      .slideY(begin: 0.3, end: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;

  const _InfoBanner({
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
