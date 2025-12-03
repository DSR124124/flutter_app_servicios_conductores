import '../entities/viaje.dart';
import '../repositories/viaje_repository.dart';

class GetMisViajesUseCase {
  GetMisViajesUseCase(this._repository);

  final ViajeRepository _repository;

  Future<List<Viaje>> call({
    String? estado,
    DateTime? fecha,
    required String token,
  }) {
    return _repository.obtenerMisViajes(
      estado: estado,
      fecha: fecha,
      token: token,
    );
  }
}

