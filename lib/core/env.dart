// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'env.g.dart';

/// build_runner の疎通確認用ダミープロバイダー。
///
/// 後続Issueで実体に置き換えるか削除する。
@riverpod
String env(Ref ref) => 'dummy';
