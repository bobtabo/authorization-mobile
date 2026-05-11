class BackendOption {
  final String name;
  final String slug;

  const BackendOption({required this.name, required this.slug});
}

const List<BackendOption> kBackends = [
  BackendOption(name: 'Go (Gin)',      slug: 'go-gin'),
  BackendOption(name: 'Go (Beego)',    slug: 'go-beego'),
  BackendOption(name: 'Go (Echo)',     slug: 'go-echo'),
  BackendOption(name: 'Kotlin',        slug: 'kotlin'),
  BackendOption(name: 'PHP',           slug: 'php'),
  BackendOption(name: 'Python',        slug: 'python'),
  BackendOption(name: 'Ruby (Hanami)', slug: 'rb-hanami'),
  BackendOption(name: 'Ruby (Rails)',  slug: 'rb-rails'),
  BackendOption(name: 'Rust',          slug: 'rust'),
  BackendOption(name: 'TypeScript',    slug: 'ts'),
];

const BackendOption kDefaultBackend = BackendOption(name: 'PHP', slug: 'php');
