import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/notificacion_model.dart';
import '../dtos/crear_notificacion_dto.dart';

abstract class NotificacionesRemoteDataSource {
  Future<List<NotificacionModel>> getMisNotificaciones({
    required int idUsuario,
    required String token,
  });

  Future<void> marcarComoLeida({
    required int idNotificacion,
    required int idUsuario,
    required String token,
  });

  Future<void> crearNotificacion({
    required CrearNotificacionDto dto,
    required String token,
  });
}

class NotificacionesRemoteDataSourceImpl implements NotificacionesRemoteDataSource {
  final http.Client client;

  NotificacionesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificacionModel>> getMisNotificaciones({
    required int idUsuario,
    required String token,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.backendGestionBaseUrl}/api/notificaciones/usuario/$idUsuario',
    );

    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body) as List<dynamic>;
      return jsonList
          .map((e) => NotificacionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw AppException.server();
    }
  }

  @override
  Future<void> marcarComoLeida({
    required int idNotificacion,
    required int idUsuario,
    required String token,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.backendGestionBaseUrl}/api/notificaciones/$idNotificacion/usuario/$idUsuario/marcar-leida',
    );

    final response = await client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw AppException.server();
    }
  }

  @override
  Future<void> crearNotificacion({
    required CrearNotificacionDto dto,
    required String token,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.backendGestionBaseUrl}/api/notificaciones',
    );

    final response = await client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dto.toJson()),
    );

    if (response.statusCode != 201) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['mensaje'] is String) {
          throw AppException(body['mensaje'] as String);
        }
      } catch (_) {
        // ignorar errores de parseo y lanzar error genérico
      }
      throw AppException.server();
    }
  }
}


