import '../../domain/entities/notificacion.dart';
import '../../domain/repositories/notificaciones_repository.dart';
import '../datasources/notificaciones_remote_data_source.dart';

class NotificacionesRepositoryImpl implements NotificacionesRepository {
  final NotificacionesRemoteDataSource remoteDataSource;

  NotificacionesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Notificacion>> getMisNotificaciones({
    required int idUsuario,
    required String token,
  }) {
    return remoteDataSource.getMisNotificaciones(
      idUsuario: idUsuario,
      token: token,
    );
  }

  @override
  Future<void> marcarComoLeida({
    required int idNotificacion,
    required int idUsuario,
    required String token,
  }) {
    return remoteDataSource.marcarComoLeida(
      idNotificacion: idNotificacion,
      idUsuario: idUsuario,
      token: token,
    );
  }
}


