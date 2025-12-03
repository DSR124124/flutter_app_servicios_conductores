import '../entities/perfil_info.dart';
import '../repositories/perfil_repository.dart';

class GetPerfilInfoUseCase {
  GetPerfilInfoUseCase(this._repository);

  final PerfilRepository _repository;

  Future<PerfilInfo> call() {
    return _repository.obtenerPerfil();
  }
}

