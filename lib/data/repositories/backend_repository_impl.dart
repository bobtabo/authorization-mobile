// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/backend_option.dart';
import '../../domain/repositories/backend_repository.dart';
import '../datasources/backend_local_data_source.dart';

part 'backend_repository_impl.g.dart';

/// [BackendLocalDataSource] に委譲する実装。
class BackendRepositoryImpl implements BackendRepository {
  const BackendRepositoryImpl(this._dataSource);

  final BackendLocalDataSource _dataSource;

  @override
  Future<BackendOption> loadSelected() => _dataSource.load();

  @override
  Future<void> saveSelected(BackendOption backend) => _dataSource.save(backend);
}

@riverpod
BackendRepository backendRepository(Ref ref) =>
    BackendRepositoryImpl(ref.watch(backendLocalDataSourceProvider));
