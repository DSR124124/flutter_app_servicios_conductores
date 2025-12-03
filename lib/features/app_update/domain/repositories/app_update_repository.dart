import '../entities/app_update_info.dart';

/// Repositorio abstracto para el manejo de actualizaciones
abstract class AppUpdateRepository {
  /// Verifica si hay una actualización disponible para la app actual
  /// Usa el endpoint optimizado del backend que ya hace la comparación de versiones
  /// [idUsuario] - ID del usuario logueado
  /// [token] - Token JWT para autenticación
  /// [codigoProducto] - Código de la aplicación (ej: FLUTTER_APP_CONDUCTORES)
  /// [versionActual] - Versión actual instalada
  Future<AppUpdateInfo?> checkForUpdate({
    required int idUsuario,
    required String token,
    required String codigoProducto,
    required String versionActual,
  });
}

