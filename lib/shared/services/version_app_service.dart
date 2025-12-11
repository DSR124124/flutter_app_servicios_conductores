import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_config.dart';

/// Modelo para la información de versión de la app
class VersionAppInfo {
  final String codigoProducto;
  final String? nombreAplicacion;
  final String versionActual;
  final String? fechaPublicacion;

  const VersionAppInfo({
    required this.codigoProducto,
    this.nombreAplicacion,
    required this.versionActual,
    this.fechaPublicacion,
  });

  factory VersionAppInfo.fromJson(Map<String, dynamic> json) {
    return VersionAppInfo(
      codigoProducto: json['codigoProducto'] as String? ?? '',
      nombreAplicacion: json['nombreAplicacion'] as String?,
      versionActual: json['versionActual'] as String? ?? '0.0.0',
      fechaPublicacion: json['fechaPublicacion'] as String?,
    );
  }

  /// Versión por defecto cuando hay error
  static VersionAppInfo defaultVersion() {
    return VersionAppInfo(
      codigoProducto: AppConfig.appCode,
      versionActual: AppConfig.appVersion,
    );
  }
}

/// Servicio para obtener la versión de la app desde el backend
class VersionAppService {
  VersionAppService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Obtiene la versión actual de la app desde la BD
  /// Si el backend no responde o devuelve una versión inválida, usa la versión local
  Future<VersionAppInfo> obtenerVersionActual() async {
    try {
      final url =
          '${AppConfig.backendGestionBaseUrl}${AppConfig.versionAppEndpoint}/${AppConfig.appCode}';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body) as Map<String, dynamic>;
        final versionInfo = VersionAppInfo.fromJson(json);
        
        if (versionInfo.versionActual == '0.0.0' || 
            versionInfo.versionActual.isEmpty) {
          return VersionAppInfo.defaultVersion();
        }
        
        return versionInfo;
      }

      return VersionAppInfo.defaultVersion();
    } on SocketException catch (_) {
      return VersionAppInfo.defaultVersion();
    } on TimeoutException catch (_) {
      return VersionAppInfo.defaultVersion();
    } catch (e) {
      return VersionAppInfo.defaultVersion();
    }
  }
}

