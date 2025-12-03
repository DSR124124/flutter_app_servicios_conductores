import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../shared/services/app_info_service.dart';
import '../../data/repositories/app_update_repository_impl.dart';
import '../../domain/entities/app_update_info.dart';
import '../../domain/usecases/check_for_update_usecase.dart';

/// Provider para manejar el estado de las actualizaciones
class AppUpdateProvider extends ChangeNotifier {
  AppUpdateProvider({
    CheckForUpdateUseCase? checkForUpdateUseCase,
    AppInfoService? appInfoService,
  })  : _checkForUpdateUseCase =
            checkForUpdateUseCase ?? CheckForUpdateUseCase(AppUpdateRepositoryImpl()),
        _appInfoService = appInfoService ?? AppInfoService();

  final CheckForUpdateUseCase _checkForUpdateUseCase;
  final AppInfoService _appInfoService;

  AppUpdateInfo? _availableUpdate;
  bool _isChecking = false;
  bool _hasChecked = false;
  String? _error;

  /// Actualización disponible (null si no hay)
  AppUpdateInfo? get availableUpdate => _availableUpdate;

  /// Indica si hay una actualización disponible
  bool get hasUpdate => _availableUpdate != null;

  /// Indica si es una actualización crítica
  bool get isCriticalUpdate => _availableUpdate?.esCritico ?? false;

  /// Indica si está verificando actualizaciones
  bool get isChecking => _isChecking;

  /// Indica si ya se verificó por actualizaciones
  bool get hasChecked => _hasChecked;

  /// Error de la última verificación
  String? get error => _error;

  /// Verifica si hay actualizaciones disponibles
  Future<void> checkForUpdates({
    required int idUsuario,
    required String token,
  }) async {
    if (_isChecking) return;

    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final installedVersion = await _appInfoService.getCurrentVersion();

      _availableUpdate = await _checkForUpdateUseCase(
        idUsuario: idUsuario,
        token: token,
        versionActual: installedVersion,
      );
      _hasChecked = true;
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Error al verificar actualizaciones';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  /// Descarta la actualización actual (para actualizaciones no críticas)
  void dismissUpdate() {
    if (!isCriticalUpdate) {
      _availableUpdate = null;
      notifyListeners();
    }
  }

  /// Reinicia el estado para una nueva verificación
  void reset() {
    _availableUpdate = null;
    _hasChecked = false;
    _error = null;
    notifyListeners();
  }
}

