import '../entities/notificacion.dart';
import '../../data/dtos/crear_notificacion_dto.dart';

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

  Future<void> crearNotificacion({
    required CrearNotificacionDto dto,
    required String token,
  });
}


