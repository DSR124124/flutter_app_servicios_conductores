import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/app_update_model.dart';

/// Data source remoto para verificar actualizaciones disponibles
class AppUpdateRemoteDataSource {
  AppUpdateRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  /// Verifica si hay una actualización disponible para el usuario
  /// Usa el nuevo endpoint optimizado del backend de gestión
  Future<AppUpdateModel?> checkForUpdate({
    required int idUsuario,
    required String token,
    required String codigoProducto,
    required String versionActual,
  }) async {
    try {
      final url = '${AppConfig.backendGestionBaseUrl}${AppConfig.updateCheckEndpoint}/$idUsuario/$codigoProducto/$versionActual';
      
      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
        
        final hayActualizacion = json['hayActualizacion'] as bool? ?? false;
        
        if (!hayActualizacion) {
          return null;
        }
        
        return AppUpdateModel.fromVerificarActualizacionJson(json);
      }

      if (response.statusCode == 401) {
        throw AppException.sessionExpired();
      }
      if (response.statusCode == 403) {
        throw AppException.forbidden();
      }
      if (response.statusCode >= 500) {
        throw AppException.server();
      }

      return null;
    } on SocketException catch (_, stackTrace) {
      throw AppException.network(stackTrace);
    } on TimeoutException catch (_, stackTrace) {
      throw AppException.timeout(stackTrace);
    } on AppException {
      rethrow;
    } catch (e) {
      return null;
    }
  }
}

