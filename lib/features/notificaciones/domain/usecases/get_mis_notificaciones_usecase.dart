import '../entities/notificacion.dart';
import '../repositories/notificaciones_repository.dart';

class GetMisNotificacionesUseCase {
  final NotificacionesRepository repository;

  GetMisNotificacionesUseCase(this.repository);

  Future<List<Notificacion>> call({
    required int idUsuario,
    required String token,
  }) {
    return repository.getMisNotificaciones(idUsuario: idUsuario, token: token);
  }
}


