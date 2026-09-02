// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/repositories/client_session_repository.dart';
import '../datasources/client_session_local_data_source.dart';

part 'client_session_repository_impl.g.dart';

/// [ClientSessionLocalDataSource] に委譲する実装。
class ClientSessionRepositoryImpl implements ClientSessionRepository {
  const ClientSessionRepositoryImpl(this._dataSource);

  final ClientSessionLocalDataSource _dataSource;

  @override
  Future<({String slug, String identifier})?> loadSession() =>
      _dataSource.load();

  @override
  Future<void> saveSession(String slug, String identifier) =>
      _dataSource.save(slug, identifier);

  @override
  Future<void> clearSession() => _dataSource.clear();
}

@riverpod
ClientSessionRepository clientSessionRepository(Ref ref) =>
    ClientSessionRepositoryImpl(
      ref.watch(clientSessionLocalDataSourceProvider),
    );
