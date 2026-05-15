// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/material.dart';
import '../config/backends.dart';

/// バックエンド選択ボトムシートを表示する。
Future<void> showBackendSelector(
  BuildContext context, {
  required BackendOption selected,
  required Future<void> Function(BackendOption) onSelect,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _BackendSelectorSheet(
      selected: selected,
      onSelect: (backend) async {
        await onSelect(backend);
        if (ctx.mounted) Navigator.pop(ctx);
      },
    ),
  );
}

class _BackendSelectorSheet extends StatelessWidget {
  final BackendOption selected;
  final Future<void> Function(BackendOption) onSelect;

  const _BackendSelectorSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'バックエンド切替',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: kBackends
                    .map(
                      (backend) => ListTile(
                        title: Text(backend.name),
                        subtitle: Text(
                          '/function/${backend.slug}/api',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                        ),
                        trailing: selected.slug == backend.slug
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF4F46E5),
                              )
                            : null,
                        onTap: () => onSelect(backend),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
