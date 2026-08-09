// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/backend_option.dart';
import '../../domain/entities/client_info.dart';

part 'app_navigator_state.freezed.dart';

/// アプリ内の画面遷移状態を表す列挙型。
enum AppScreen { splash, scanner, confirm, token, home }

/// AppNavigatorViewModel が保持する状態。
@freezed
abstract class AppNavigatorState with _$AppNavigatorState {
  const factory AppNavigatorState({
    @Default(AppScreen.splash) AppScreen currentScreen,
    ClientInfo? clientInfo,
    @Default('') String token,
    required BackendOption selectedBackend,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _AppNavigatorState;
}
