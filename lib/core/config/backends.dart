// This is a program developed by BobTabo.
//
// Copyright (c) 2026 BobTabo. All Rights Reserved.

import '../../domain/entities/backend_option.dart';

/// 利用可能なバックエンドの一覧。
const List<BackendOption> kBackends = [
  BackendOption(name: 'Go (Gin)', slug: 'go-gin'),
  BackendOption(name: 'Go (Beego)', slug: 'go-beego'),
  BackendOption(name: 'Go (Echo)', slug: 'go-echo'),
  BackendOption(name: 'Kotlin', slug: 'kotlin'),
  BackendOption(name: 'PHP', slug: 'php'),
  BackendOption(name: 'Python', slug: 'python'),
  BackendOption(name: 'Ruby (Hanami)', slug: 'rb-hanami'),
  BackendOption(name: 'Ruby (Rails)', slug: 'rb-rails'),
  BackendOption(name: 'Rust', slug: 'rust'),
  BackendOption(name: 'TypeScript', slug: 'ts'),
];

/// デフォルトで選択されるバックエンド。
const BackendOption kDefaultBackend = BackendOption(name: 'PHP', slug: 'php');
