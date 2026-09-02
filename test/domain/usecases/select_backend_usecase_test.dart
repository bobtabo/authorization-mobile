import 'package:authorization_mobile/domain/entities/backend_option.dart';
import 'package:authorization_mobile/domain/repositories/backend_repository.dart';
import 'package:authorization_mobile/domain/usecases/select_backend_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBackendRepository implements BackendRepository {
  BackendOption? saved;

  @override
  Future<BackendOption> loadSelected() => throw UnimplementedError();

  @override
  Future<void> saveSelected(BackendOption backend) async {
    saved = backend;
  }
}

void main() {
  test(
    'delegates to BackendRepository.saveSelected with the given backend',
    () async {
      const backend = BackendOption(name: 'Go (Gin)', slug: 'go-gin');
      final repository = _FakeBackendRepository();
      final useCase = SelectBackendUseCase(repository);

      await useCase(backend);

      expect(repository.saved, backend);
    },
  );
}
