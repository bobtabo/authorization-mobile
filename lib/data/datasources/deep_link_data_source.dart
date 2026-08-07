// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:app_links/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deep_link_data_source.g.dart';

/// `package:app_links` をラップし、ディープリンクの受信を扱うDataSource。
class DeepLinkDataSource {
  DeepLinkDataSource({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// アプリ起動時に受け取った初期リンク（アプリが終了していた場合）。
  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  /// アプリ起動中に受け取るリンクのストリーム。
  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;
}

@riverpod
DeepLinkDataSource deepLinkDataSource(Ref ref) => DeepLinkDataSource();
