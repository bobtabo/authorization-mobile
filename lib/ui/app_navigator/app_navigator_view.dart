// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../activation_confirm/view/activation_confirm_screen.dart';
import '../home/view/home_screen.dart';
import '../scanner/view/qr_scanner_screen.dart';
import '../splash/view/splash_screen.dart';
import '../token_display/view/token_display_screen.dart';
import 'app_navigator_state.dart';
import 'app_navigator_view_model.dart';

/// アプリ全体の画面遷移とAPIコールを管理するルートウィジェット。
class AppNavigatorView extends ConsumerWidget {
  const AppNavigatorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appNavigatorViewModelProvider);
    final notifier = ref.read(appNavigatorViewModelProvider.notifier);

    ref.listen(appNavigatorViewModelProvider, (previous, next) async {
      final message = next.errorMessage;
      if (message == null) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('エラー'),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      notifier.dismissError();
    });

    final screen = switch (state.currentScreen) {
      AppScreen.splash => SplashScreen(
        onStart: notifier.handleStartScan,
        selectedBackend: state.selectedBackend,
        onSelectBackend: notifier.selectBackend,
      ),
      AppScreen.scanner => QRScannerScreen(
        onScan: notifier.handleQrScan,
        onBack: notifier.handleBackToSplash,
      ),
      AppScreen.confirm =>
        state.clientInfo != null
            ? ActivationConfirmScreen(
                clientInfo: state.clientInfo!,
                onActivate: () {
                  notifier.handleActivate();
                },
                onBack: notifier.handleBackToScanner,
              )
            : SplashScreen(
                onStart: notifier.handleStartScan,
                selectedBackend: state.selectedBackend,
                onSelectBackend: notifier.selectBackend,
              ),
      AppScreen.token =>
        state.clientInfo != null
            ? TokenDisplayScreen(
                token: state.token,
                clientName: state.clientInfo!.name,
                onClose: notifier.handleCloseToken,
              )
            : SplashScreen(
                onStart: notifier.handleStartScan,
                selectedBackend: state.selectedBackend,
                onSelectBackend: notifier.selectBackend,
              ),
      AppScreen.home =>
        state.clientInfo != null
            ? HomeScreen(
                clientInfo: state.clientInfo!,
                onSuspend: () {
                  notifier.handleSuspend();
                },
                onResume: () {
                  notifier.handleResume();
                },
                selectedBackend: state.selectedBackend,
                onSelectBackend: notifier.selectBackend,
              )
            : SplashScreen(
                onStart: notifier.handleStartScan,
                selectedBackend: state.selectedBackend,
                onSelectBackend: notifier.selectBackend,
              ),
    };

    if (!state.isLoading) return screen;
    return Stack(
      children: [
        screen,
        const ModalBarrier(dismissible: false, color: Colors.black45),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
