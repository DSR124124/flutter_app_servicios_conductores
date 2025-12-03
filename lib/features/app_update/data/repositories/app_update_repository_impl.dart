import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_data_source.dart';

/// Implementación del repositorio de actualizaciones
class AppUpdateRepositoryImpl implements AppUpdateRepository {
  AppUpdateRepositoryImpl({
    AppUpdateRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? AppUpdateRemoteDataSource();

  final AppUpdateRemoteDataSource _remoteDataSource;

  @override
  Future<AppUpdateInfo?> checkForUpdate({
    required int idUsuario,
    required String token,
    required String codigoProducto,
    required String versionActual,
  }) async {
    // Usa el endpoint optimizado que ya compara versiones en el backend
    return await _remoteDataSource.checkForUpdate(
      idUsuario: idUsuario,
      token: token,
      codigoProducto: codigoProducto,
      versionActual: versionActual,
    );
  }
}

