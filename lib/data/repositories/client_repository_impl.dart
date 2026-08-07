// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/result.dart';
import '../../domain/entities/client_info.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_remote_data_source.dart';

part 'client_repository_impl.g.dart';

/// [ClientRemoteDataSource] を呼び出し、例外を [Result]/[AppException] に変換する実装。
class ClientRepositoryImpl implements ClientRepository {
  const ClientRepositoryImpl(this._dataSource);

  final ClientRemoteDataSource _dataSource;

  @override
  Future<Result<ClientInfo>> fetchClientInfo(String slug, String identifier) =>
      _run(() => _dataSource.fetchClientInfo(slug, identifier));

  @override
  Future<Result<String>> activateClient(String slug, String identifier) =>
      _run(() => _dataSource.activateClient(slug, identifier));

  @override
  Future<Result<void>> stopClient(String slug, String identifier) =>
      _run(() => _dataSource.stopClient(slug, identifier));

  @override
  Future<Result<void>> resumeClient(String slug, String identifier) =>
      _run(() => _dataSource.resumeClient(slug, identifier));

  Future<Result<T>> _run<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on ApiException catch (e) {
      return Err(ApiFailure(e.statusCode, e.message));
    } catch (_) {
      return const Err(NetworkException());
    }
  }
}

@riverpod
ClientRepository clientRepository(Ref ref) =>
    ClientRepositoryImpl(ref.watch(clientRemoteDataSourceProvider));
