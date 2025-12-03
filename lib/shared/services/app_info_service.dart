import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_config.dart';

/// Servicio centralizado para obtener información de la app instalada.
class AppInfoService {
  AppInfoService._internal();

  static final AppInfoService _instance = AppInfoService._internal();

  factory AppInfoService() => _instance;

  PackageInfo? _cachedInfo;

  /// Obtiene la versión actual instalada (formato X.Y.Z).
  /// Retorna la versión de AppConfig si hay error (ej: durante hot restart)
  Future<String> getCurrentVersion() async {
    try {
      final info = await _ensurePackageInfo();
      return info.version;
    } on MissingPluginException {
      // Durante hot restart, el plugin puede no estar disponible
      return AppConfig.appVersion;
    } catch (_) {
      return AppConfig.appVersion;
    }
  }

  /// Obtiene el build number actual (si se requiere).
  Future<String> getBuildNumber() async {
    try {
      final info = await _ensurePackageInfo();
      return info.buildNumber;
    } on MissingPluginException {
      return '1';
    } catch (_) {
      return '1';
    }
  }

  Future<PackageInfo> _ensurePackageInfo() async {
    _cachedInfo ??= await PackageInfo.fromPlatform();
    return _cachedInfo!;
  }

  /// Limpia el cache (útil después de actualizar la app)
  void clearCache() {
    _cachedInfo = null;
  }
}

