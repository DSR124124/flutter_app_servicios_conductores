import '../entities/notificacion.dart';

abstract class NotificacionesRepository {
  Future<List<Notificacion>> getMisNotificaciones({
    required int idUsuario,
    required String token,
  });

  Future<void> marcarComoLeida({
    required int idNotificacion,
    required int idUsuario,
    required String token,
  });
}


