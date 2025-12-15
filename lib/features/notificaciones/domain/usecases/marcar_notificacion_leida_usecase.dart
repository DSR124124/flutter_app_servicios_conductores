import '../repositories/notificaciones_repository.dart';

class MarcarNotificacionLeidaUseCase {
  final NotificacionesRepository repository;

  MarcarNotificacionLeidaUseCase(this.repository);

  Future<void> call({
    required int idNotificacion,
    required int idUsuario,
    required String token,
  }) {
    return repository.marcarComoLeida(
      idNotificacion: idNotificacion,
      idUsuario: idUsuario,
      token: token,
    );
  }
}


