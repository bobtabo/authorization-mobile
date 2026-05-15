// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/backends.dart';
import '../models/client_info.dart';

class HomeScreen extends StatefulWidget {
  final ClientInfo clientInfo;
  final VoidCallback onSuspend;
  final VoidCallback onResume;
  final BackendOption selectedBackend;
  final Future<void> Function(BackendOption) onSelectBackend;

  const HomeScreen({
    super.key,
    required this.clientInfo,
    required this.onSuspend,
    required this.onResume,
    required this.selectedBackend,
    required this.onSelectBackend,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showSuspendDialog = false;

  Color _statusDotColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.active:
        return const Color(0xFF10B981); // emerald-500
      case ClientStatus.suspended:
        return const Color(0xFFEC4899); // pink-500
      case ClientStatus.preparing:
        return const Color(0xFFF97316); // orange-500
    }
  }

  Color _statusBgColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.active:
        return const Color(0xFFECFDF5);
      case ClientStatus.suspended:
        return const Color(0xFFFDF2F8);
      case ClientStatus.preparing:
        return const Color(0xFFFFF7ED);
    }
  }

  Color _statusBorderColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.active:
        return const Color(0xFF6EE7B7);
      case ClientStatus.suspended:
        return const Color(0xFFF9A8D4);
      case ClientStatus.preparing:
        return const Color(0xFFFDBA74);
    }
  }

  Color _statusTextColor(ClientStatus status) {
    switch (status) {
      case ClientStatus.active:
        return const Color(0xFF065F46);
      case ClientStatus.suspended:
        return const Color(0xFF831843);
      case ClientStatus.preparing:
        return const Color(0xFF7C2D12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ヘッダー
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFFE0E7FF)),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icon.svg',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Authorization Gateway',
                          style: TextStyle(fontSize: 18),
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
                          // バックエンド選択
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Backend:',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 8),
                              DropdownButton<BackendOption>(
                                value: widget.selectedBackend,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1F2937),
                                ),
                                underline: Container(
                                  height: 1,
                                  color: const Color(0xFFE0E7FF),
                                ),
                                isDense: true,
                                items: kBackends
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (b) {
                                  if (b != null) widget.onSelectBackend(b);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ステータスカード
                          _StatusCard(
                            clientInfo: widget.clientInfo,
                            statusDotColor: _statusDotColor,
                            statusBgColor: _statusBgColor,
                            statusBorderColor: _statusBorderColor,
                            statusTextColor: _statusTextColor,
                          ),
                          const SizedBox(height: 24),
                          // 利用中の場合のみ停止ボタン表示
                          if (widget.clientInfo.status == ClientStatus.active)
                            Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFBEB),
                                        border: Border.all(
                                          color: const Color(0xFFFCD34D),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: const [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Color(0xFFD97706),
                                            size: 20,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '一時的に利用を停止する場合は、下のボタンから操作できます。',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF92400E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => setState(
                                          () => _showSuspendDialog = true,
                                        ),
                                        icon: const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 24,
                                        ),
                                        label: const Text('利用停止'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFDC2626,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fade(delay: 200.ms, duration: 300.ms)
                                .slideY(begin: 0.2, end: 0),
                          if (widget.clientInfo.status ==
                              ClientStatus.suspended)
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    border: Border.all(
                                      color: const Color(0xFFFCA5A5),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'アクセスが停止されています',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 13,
                                                color: Color(0xFF7F1D1D),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'APIアクセスは現在無効化されています。',
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
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: widget.onResume,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    child: const Text('利用開始'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 停止確認ダイアログ
          if (_showSuspendDialog)
            _SuspendDialog(
              onCancel: () => setState(() => _showSuspendDialog = false),
              onConfirm: () {
                setState(() => _showSuspendDialog = false);
                widget.onSuspend();
              },
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final ClientInfo clientInfo;
  final Color Function(ClientStatus) statusDotColor;
  final Color Function(ClientStatus) statusBgColor;
  final Color Function(ClientStatus) statusBorderColor;
  final Color Function(ClientStatus) statusTextColor;

  const _StatusCard({
    required this.clientInfo,
    required this.statusDotColor,
    required this.statusBgColor,
    required this.statusBorderColor,
    required this.statusTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF5F3FF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE0E7FF).withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // クライアント名
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFE0E7FF,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF4F46E5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'クライアント名',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      clientInfo.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE0E7FF)),
                const SizedBox(height: 24),
                // 識別名
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE0E7FF).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.label_outline,
                            color: Color(0xFF818CF8),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '識別名',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        clientInfo.identifier,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFE0E7FF)),
                const SizedBox(height: 24),
                // ステータス
                Column(
                  children: [
                    const Text(
                      '現在のステータス',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor(clientInfo.status),
                        border: Border.all(
                          color: statusBorderColor(clientInfo.status),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: statusDotColor(
                              clientInfo.status,
                            ).withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingDot(color: statusDotColor(clientInfo.status)),
                          const SizedBox(width: 16),
                          Text(
                            clientInfo.status.label,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor(clientInfo.status),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
        )
        .fade(duration: 300.ms);
  }
}

class _PulsingDot extends StatelessWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.4, end: 1.0, duration: 800.ms);
  }
}

class _SuspendDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _SuspendDialog({required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child:
                Container(
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
                            children: const [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Color(0xFFEF4444),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '利用停止しますか？',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'APIアクセスを即座に無効化します。',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'この操作により、すべてのAPI呼び出しが拒否されます。',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFDC2626),
                                        fontWeight: FontWeight.w500,
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('停止する'),
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
      ).animate().fade(duration: 150.ms),
    );
  }
}
