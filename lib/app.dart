// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:flutter/material.dart';

import 'demo/tap_indicator.dart';
import 'ui/app_navigator/app_navigator_view.dart';

/// アプリのルートウィジェット。テーマと [AppNavigatorView] を設定する。
class AuthorizationGatewayApp extends StatelessWidget {
  const AuthorizationGatewayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authorization Gateway',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const DemoTapIndicatorOverlay(child: AppNavigatorView()),
    );
  }
}
