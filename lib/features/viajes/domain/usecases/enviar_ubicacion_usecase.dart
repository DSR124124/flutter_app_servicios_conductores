import '../entities/ubicacion_gps.dart';
import '../repositories/viaje_repository.dart';

class EnviarUbicacionUseCase {
  EnviarUbicacionUseCase(this._repository);

  final ViajeRepository _repository;

  Future<void> call({
    required UbicacionGPS ubicacion,
    required String token,
  }) {
    return _repository.enviarUbicacionGPS(
      ubicacion: ubicacion,
      token: token,
    );
  }
}

