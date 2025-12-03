import '../entities/viaje.dart';
import '../repositories/viaje_repository.dart';

class IniciarViajeUseCase {
  IniciarViajeUseCase(this._repository);

  final ViajeRepository _repository;

  Future<Viaje> call({
    required int idViaje,
    required String token,
  }) {
    return _repository.iniciarViaje(
      idViaje: idViaje,
      token: token,
    );
  }
}

