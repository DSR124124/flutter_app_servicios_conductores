import '../repositories/notificaciones_repository.dart';
import '../../data/dtos/crear_notificacion_dto.dart';

class CrearNotificacionUseCase {
  final NotificacionesRepository repository;

  CrearNotificacionUseCase(this.repository);

  Future<void> call({
    required CrearNotificacionDto dto,
    required String token,
  }) {
    return repository.crearNotificacion(dto: dto, token: token);
  }
}


