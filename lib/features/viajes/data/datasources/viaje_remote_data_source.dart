import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/estadisticas.dart';
import '../../domain/entities/ubicacion_gps.dart';
import '../models/viaje_model.dart';

class ViajeRemoteDataSource {
  ViajeRemoteDataSource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _buildHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Obtiene los viajes asignados al conductor
  Future<List<ViajeModel>> fetchMisViajes({
    String? estado,
    DateTime? fecha,
    required String token,
  }) async {
    try {
      var url = '${AppConfig.backendServiciosBaseUrl}/api/conductor/mis-viajes';
      final params = <String, String>{};
      if (estado != null) params['estado'] = estado;
      if (fecha != null) params['fecha'] = fecha.toIso8601String().split('T')[0];
      
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await _client
          .get(Uri.parse(url), headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.map((json) => ViajeModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      _handleError(response);
      return [];
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Obtiene el viaje activo del conductor
  Future<ViajeModel?> fetchViajeActivo({required String token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConfig.backendServiciosBaseUrl}/api/conductor/viaje-activo'),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // El backend devuelve {viajeActivo: false, mensaje: "..."} cuando no hay viaje activo
        if (data.containsKey('viajeActivo') && data['viajeActivo'] == false) {
          return null;
        }
        
        // Si tiene idViaje, es un viaje activo
        if (data.containsKey('idViaje')) {
          return ViajeModel.fromJson(data);
        }
        
        return null;
      }

      if (response.statusCode == 404) {
        return null; // No hay viaje activo
      }

      _handleError(response);
      return null;
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Inicia un viaje
  Future<ViajeModel> iniciarViaje({
    required int idViaje,
    required String token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.backendServiciosBaseUrl}/api/conductor/viaje/$idViaje/iniciar'),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ViajeModel.fromJson(data);
      }

      _handleError(response);
      throw AppException('Error al iniciar viaje');
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Finaliza un viaje
  Future<ViajeModel> finalizarViaje({
    required int idViaje,
    required String token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.backendServiciosBaseUrl}/api/conductor/viaje/$idViaje/finalizar'),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ViajeModel.fromJson(data);
      }

      _handleError(response);
      throw AppException('Error al finalizar viaje');
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Envía ubicación GPS al servidor
  Future<void> enviarUbicacionGPS({
    required UbicacionGPS ubicacion,
    required String token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.backendServiciosBaseUrl}/api/gps/ubicacion'),
            headers: _buildHeaders(token),
            body: jsonEncode(ubicacion.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Marca llegada a un paradero
  Future<void> marcarLlegadaParadero({
    required int idViaje,
    required int idParadero,
    required String token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${AppConfig.backendServiciosBaseUrl}/api/conductor/viaje/$idViaje/paradero/$idParadero/llegada',
            ),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Obtiene historial de viajes
  Future<List<ViajeModel>> fetchHistorial({
    required String token,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '${AppConfig.backendServiciosBaseUrl}/api/conductor/historial?page=$page&size=$size',
            ),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data is List ? data : (data['content'] as List<dynamic>? ?? []);
        return content.map((json) => ViajeModel.fromJson(json as Map<String, dynamic>)).toList();
      }

      _handleError(response);
      return [];
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  /// Obtiene las estadísticas del conductor
  Future<EstadisticasConductor> fetchEstadisticas({required String token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConfig.backendServiciosBaseUrl}/api/conductor/estadisticas'),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EstadisticasConductor.fromJson(data);
      }

      _handleError(response);
      throw AppException('Error al obtener estadísticas');
    } on SocketException catch (_, st) {
      throw AppException.network(st);
    } on TimeoutException catch (_, st) {
      throw AppException.timeout(st);
    } on AppException {
      rethrow;
    } catch (_, st) {
      throw AppException.unknown(st);
    }
  }

  void _handleError(http.Response response) {
    String message = 'Error desconocido';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['mensaje'] ?? body['message'] ?? body['error'] ?? message;
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw AppException.sessionExpired();
      case 403:
        throw AppException.forbidden();
      case 404:
        throw AppException('Recurso no encontrado');
      case >= 500:
        throw AppException.server();
      default:
        throw AppException(message);
    }
  }
}

