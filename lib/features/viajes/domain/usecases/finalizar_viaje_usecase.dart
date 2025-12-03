import '../entities/viaje.dart';
import '../repositories/viaje_repository.dart';

class FinalizarViajeUseCase {
  FinalizarViajeUseCase(this._repository);

  final ViajeRepository _repository;

  Future<Viaje> call({
    required int idViaje,
    required String token,
  }) {
    return _repository.finalizarViaje(
      idViaje: idViaje,
      token: token,
    );
  }
}

