/// バックエンド選択肢を表すクラス。
class BackendOption {
  /// 表示名。
  final String name;

  /// APIゲートウェイのパスセグメントに使用するスラッグ。
  final String slug;

  const BackendOption({required this.name, required this.slug});
}

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
