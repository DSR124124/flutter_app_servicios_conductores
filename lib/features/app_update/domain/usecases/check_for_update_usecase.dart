import '../../../../core/constants/app_config.dart';
import '../entities/app_update_info.dart';
import '../repositories/app_update_repository.dart';

/// Use case para verificar si hay actualizaciones disponibles
class CheckForUpdateUseCase {
  CheckForUpdateUseCase(this._repository);

  final AppUpdateRepository _repository;

  /// Ejecuta la verificación de actualizaciones
  /// [idUsuario] - ID del usuario logueado
  /// [token] - Token JWT para autenticación
  /// [versionActual] - Versión actual de la app (opcional, usa AppConfig por defecto)
  Future<AppUpdateInfo?> call({
    required int idUsuario,
    required String token,
    String? versionActual,
  }) {
    return _repository.checkForUpdate(
      idUsuario: idUsuario,
      token: token,
      codigoProducto: AppConfig.appCode,
      versionActual: versionActual ?? AppConfig.appVersion,
    );
  }
}

