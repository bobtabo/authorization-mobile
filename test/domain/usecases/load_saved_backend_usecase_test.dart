import 'package:authorization_mobile/domain/entities/backend_option.dart';
import 'package:authorization_mobile/domain/repositories/backend_repository.dart';
import 'package:authorization_mobile/domain/usecases/load_saved_backend_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackendRepository implements BackendRepository {
  _FakeBackendRepository({required this.selected});

  BackendOption selected;

  @override
  Future<BackendOption> loadSelected() async => selected;

  @override
  Future<void> saveSelected(BackendOption backend) =>
      throw UnimplementedError();
}

void main() {
  test('delegates to BackendRepository.loadSelected', () async {
    const backend = BackendOption(name: 'PHP', slug: 'php');
    final repository = _FakeBackendRepository(selected: backend);
    final useCase = LoadSavedBackendUseCase(repository);

    final result = await useCase();

    expect(result, backend);
  });
}
