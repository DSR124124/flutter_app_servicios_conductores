import '../entities/viaje.dart';
import '../repositories/viaje_repository.dart';

class GetViajeActivoUseCase {
  GetViajeActivoUseCase(this._repository);

  final ViajeRepository _repository;

  Future<Viaje?> call({required String token}) {
    return _repository.obtenerViajeActivo(token: token);
  }
}

